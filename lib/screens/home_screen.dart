import 'package:flutter/material.dart';
import 'package:stribe/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/models/folder.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/widgets/library_list_view.dart';
import 'package:stribe/widgets/detail_view_screen.dart';
import 'package:stribe/widgets/empty_state_view.dart';
import 'package:stribe/repositories/memo_repository.dart';
import 'package:stribe/services/native_service.dart';
import 'package:stribe/services/ondevice_llm_service.dart';
import 'package:stribe/services/share_service.dart';
import 'package:stribe/services/unified_analysis_service.dart';
import 'package:stribe/screens/settings_screen.dart';
import 'package:stribe/utils/app_logger.dart';
import 'package:stribe/utils/text_heuristics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
// Google ML Kit removed - using native Vision Framework (iOS) instead
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final ShareService _shareService = ShareService();
  final MemoRepository _repository = MemoRepository.instance;
  bool _isAnalyzing = false;
  List<MemoCard> _cards = [];
  List<Folder> _folders = [];
  Folder? _selectedFolder;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // DB 전문 검색(FTS) 상태: 검색어 입력 시 디바운스 후 DB에서 조회
  List<MemoCard>? _searchResults;
  Timer? _searchDebounce;

  // Filter state
  bool _showFavoriteOnly = false;
  String? _selectedType; // null = ALL

  // Share Extension: Inbox 상태 관리
  List<SharedItem> _pendingSharedItems = [];
  bool _hasNewSharedItems = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshCards();
    _loadFolders();
    _startScreenshotMonitoring(); // 스크린샷 자동 모니터링 시작
    _checkPendingSharedItems(); // 공유된 항목 확인
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchDebounce?.cancel();
    _stopScreenshotMonitoring(); // 스크린샷 모니터링 중지
    super.dispose();
  }

  /// 검색어 변경 처리: 300ms 디바운스 후 DB 전문 검색(FTS5) 실행.
  /// 메모리 내 필터와 달리 수천 장 규모에서도 인덱스 기반으로 동작한다.
  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _repository.search(value);
      if (mounted && _searchQuery == value) {
        setState(() => _searchResults = results);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아왔을 때 공유된 항목 확인
      _checkPendingSharedItems();
    }
  }

  /// Share Extension에서 공유된 항목 확인
  Future<void> _checkPendingSharedItems() async {
    try {
      final items = await _shareService.getPendingSharedItems();
      if (items.isNotEmpty) {
        logInfo('📥 ${items.length}개의 공유된 항목 발견', name: 'Home');
        setState(() {
          _pendingSharedItems = items;
          _hasNewSharedItems = true;
        });

        // 자동으로 공유된 항목 처리
        _processSharedItems();
      }
    } catch (e) {
      logInfo('❌ 공유된 항목 확인 실패: $e', name: 'Home');
    }
  }

  /// 공유된 항목들을 처리하고 MemoCard로 변환
  Future<void> _processSharedItems() async {
    if (_pendingSharedItems.isEmpty) return;
    
    // Remove _isAnalyzing = true; -> No blocking

    try {
      // 1. Create temporary processing cards
      final processingCards = _pendingSharedItems.map((item) {
        return MemoCard(
          id: 'temp_${item.timestamp}', // Temporary ID
          title: item.displayTitle,
          summary: "Processing...",
          category: "Inbox",
          tags: [],
          captureDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
          imageUrl: item.imagePath ?? '', // Use local image if available
          sourceUrl: item.url,
          isProcessing: true,
        );
      }).toList();

      // 2. Add to list immediately
      setState(() {
         // Insert at top
         _cards.insertAll(0, processingCards);
      });

      // 3. Process items in background
      for (int i = 0; i < _pendingSharedItems.length; i++) {
        final item = _pendingSharedItems[i];
        final tempCardId = processingCards[i].id;

        logInfo('📦 처리 중: ${item.type} - ${item.displayTitle}', name: 'Home');

        // AI 분석 수행
        final processedItem = await _shareService.processSharedItem(item);

        // MemoCard 생성 (Real Card)
        final newCard = await _createCardFromSharedItem(processedItem, saveToDb: true);

              // 4. Update UI: Replace temp card with real card
        if (mounted && newCard != null) {
          setState(() {
            final index = _cards.indexWhere((c) => c.id == tempCardId);
             if (index != -1) {
               _cards[index] = newCard;
             } else {
               _cards.insert(0, newCard); 
             }
          });
        }

        // 처리된 항목 제거
        await _shareService.removePendingSharedItem(item.timestamp);
      }
      
      // Cleanup: Remove any remaining temp cards (just in case)
      setState(() {
         _cards.removeWhere((c) => c.id.startsWith('temp_'));
      });
      
      // Force reload from DB to ensure consistency
       await _refreshCards();
       await _loadFolders();

      // 성공 알림
      if (mounted) {
        final count = _pendingSharedItems.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.msgSharedItemsSaved(count)),
            backgroundColor: AppTheme.accentTeal,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _pendingSharedItems = [];
        _hasNewSharedItems = false;
      });
    } catch (e) {
      logInfo('❌ 공유된 항목 처리 실패: $e', name: 'Home');
      // On error, remove temp cards
      setState(() {
         _cards.removeWhere((c) => c.id.startsWith('temp_'));
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.msgSharedItemsError('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // setState(() => _isAnalyzing = false); // Not needed
    }
  }

  /// SharedItem을 MemoCard로 변환하여 저장
  /// Returns the created card immediately
  Future<MemoCard?> _createCardFromSharedItem(SharedItem item, {bool saveToDb = true}) async {
    String? imagePath;

    // 이미지가 있는 경우 영구 저장소로 복사
    if (item.hasImage && item.imagePath != null) {
      final sourceFile = File(item.imagePath!);
      if (await sourceFile.exists()) {
        imagePath = await _saveToDocuments(sourceFile);
      }
    }

    // 이미지가 없는 경우 플레이스홀더 이미지 경로 사용
    final finalImagePath = imagePath ?? item.imageUrl ?? '';

    // ShareService.processSharedItem이 이미 AI 분석을 수행했으면 그 결과를 그대로 사용.
    // 분석이 안 된 경우(인사이트/요약 없음)에만 추가 분석해 중복 API 호출을 막는다.
    String finalTitle = item.displayTitle;
    String finalSummary = item.summary ?? '';
    List<String> finalInsights = item.keyInsights ?? [];
    String finalCategory = item.category ?? 'Inbox';
    String finalContentType = item.contentType ?? 'general';
    List<String> finalTags = item.tags ?? ['Shared'];
    String finalOcrText = item.ocrText ?? item.text ?? '';

    final bool alreadyAnalyzed = finalSummary.isNotEmpty && finalInsights.isNotEmpty;

    if (finalOcrText.isNotEmpty && !alreadyAnalyzed) {
        try {
            logInfo("🔍 Analyzing shared content...", name: 'Home');
            // Reuse the screenshot analysis logic which handles text->blocks conversion and structural parsing
            final analysis = await _analyzeScreenshotOnDevice(
                finalOcrText,
                suggestedCategory: finalCategory == 'Web' ? 'Web' : finalCategory
            );

            // Merge results
            if (analysis.summary.length > finalSummary.length) {
                // If parser generated a more comprehensive summary (or if original was empty)
                finalSummary = analysis.summary;
            }
            if (finalTitle.isEmpty || finalTitle == AppLocalizations.of(context)!.titleWebLink) {
                finalTitle = analysis.title;
            }
            finalInsights = analysis.keyInsights;
            if (analysis.category != null) finalCategory = analysis.category!;
            finalContentType = analysis.contentType;
            if (analysis.tags.isNotEmpty) finalTags = analysis.tags;

            logInfo("✅ Web content analyzed: ${analysis.title}", name: 'Home');
        } catch (e) {
            logWarn("Shared content analysis passed (using defaults): $e", name: 'Home');
        }
    }

    // Fallback Summary Logic
    if (finalSummary.isEmpty) {
        if (finalOcrText.isNotEmpty) {
           finalSummary = finalOcrText.length > 200 
               ? '${finalOcrText.substring(0, 200)}...' 
               : finalOcrText;
        } else {
           finalSummary = item.hasUrl
               ? AppLocalizations.of(context)!.msgWebLinkSaved
               : AppLocalizations.of(context)!.msgSharedContentSaved;
        }
    }

    final newSourceType = item.hasUrl ? 'url' : (item.type == 'image' ? 'photo' : item.type);

    // 같은 기사/페이지를 방금 스크린샷으로 이미 저장했다면 중복 저장을 건너뛴다
    // (스크린샷 감지와 공유 확장은 서로 독립적으로 동작하므로 순서가 반대일 수 있음).
    if (newSourceType == 'url' &&
        _isDuplicateOfRecentCapture(finalTitle, otherSourceTypes: {'screenshot'})) {
      logInfo('⏭️ 최근 스크린샷 카드와 제목이 겹쳐 공유 항목 저장을 건너뜀: $finalTitle', name: 'Home');
      return null;
    }

    final newCard = MemoCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: finalTitle.length > 50 ? "${finalTitle.substring(0, 47)}..." : finalTitle,
      summary: finalSummary,
      category: finalCategory,
      contentType: finalContentType,
      tags: finalTags,
      captureDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      imageUrl: finalImagePath,
      ocrText: finalOcrText,
      sourceUrl: item.sourceUrl,
      personalNote: item.selectedText,
      folderId: _selectedFolder?.id,
      keyInsights: finalInsights, // Now we have insights!
      sourceType: newSourceType,
    );

    if (saveToDb) {
        await _repository.create(newCard);
        logInfo('✅ 공유된 항목 저장됨: ${newCard.title}', name: 'Home');
    }

    return newCard;
  }

  /// 최근(기본 3분 이내)에 저장된 카드 중 제목이 사실상 같은 것이 있는지 확인.
  ///
  /// 사용자가 기사를 스크린샷으로 캡처한 직후 같은 기사를 URL로도 공유하는 경우
  /// (또는 그 반대 순서) OS 스크린샷 감지와 Share Extension이 각각 독립적으로
  /// 카드를 생성해 같은 내용이 "URL"/"스크린샷" 두 장으로 중복 저장된다.
  /// 두 캡처 경로는 서로의 존재를 모르므로, 저장 직전에 최근 카드 목록에서
  /// 제목이 겹치는 [otherSourceTypes] 카드가 있는지 확인해 중복 생성을 막는다.
  bool _isDuplicateOfRecentCapture(
    String candidateTitle, {
    required Set<String> otherSourceTypes,
  }) {
    final candidate = candidateTitle.trim().toLowerCase();
    if (candidate.length < 5) return false;

    final now = DateTime.now();
    for (final card in _cards) {
      if (!otherSourceTypes.contains(card.sourceType)) continue;

      final captured = DateTime.tryParse(card.captureDate.replaceFirst(' ', 'T'));
      if (captured == null) continue;
      if (now.difference(captured).inSeconds.abs() > 180) continue;

      final existing = card.title.trim().toLowerCase();
      if (existing.length < 5) continue;

      // 말줄임표(...) 제거 후 짧은 쪽이 긴 쪽에 포함되면 사실상 동일 제목으로 간주
      final a = candidate.replaceAll(RegExp(r'\.{2,}$'), '').trim();
      final b = existing.replaceAll(RegExp(r'\.{2,}$'), '').trim();
      if (a.isEmpty || b.isEmpty) continue;
      final shorter = a.length <= b.length ? a : b;
      final longer = a.length <= b.length ? b : a;
      if (shorter.length >= 8 && longer.contains(shorter)) {
        return true;
      }
    }
    return false;
  }

  /// 스크린샷 자동 모니터링 시작
  Future<void> _startScreenshotMonitoring() async {
    // iOS에서만 권한 요청 (macOS는 permission_handler가 지원 안 함)
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (!status.isGranted && !status.isLimited) {
        logInfo('📸 Photo permission not granted, skipping screenshot monitoring', name: 'Home');
        return;
      }
    }

    final success = await NativeService.startScreenshotMonitoring(
      onScreenshotDetected: _handleNewScreenshot,
    );

    if (success) {
      logInfo('✅ Screenshot monitoring started successfully', name: 'Home');
    } else {
      logInfo('❌ Failed to start screenshot monitoring', name: 'Home');
    }
  }

  /// 스크린샷 모니터링 중지
  Future<void> _stopScreenshotMonitoring() async {
    await NativeService.stopScreenshotMonitoring();
    logInfo('⏹️ Screenshot monitoring stopped', name: 'Home');
  }

  /// 새 스크린샷이 감지되었을 때 자동으로 호출되는 핸들러
  Future<void> _handleNewScreenshot(Map<String, dynamic> data) async {
    logInfo('📸 New screenshot detected: ${data['imagePath']}', name: 'Home');

    final imagePath = data['imagePath'] as String;
    
    // Create Temporary Card
    final tempId = "temp_ss_${DateTime.now().millisecondsSinceEpoch}";
    final tempCard = MemoCard(
        id: tempId,
        title: "New Screenshot",
        summary: "Analyzing content...",
        category: "Inbox",
        tags: [],
        captureDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        imageUrl: imagePath,
        isProcessing: true,
        sourceType: 'screenshot', // Default for screenshots
    );

    // Update UI immediately
    if (mounted) {
         setState(() {
             _cards.insert(0, tempCard);
         });
    }

    try {
      final ocrText = data['ocrText'] as String? ?? '';
      final suggestedTags = List<String>.from(data['suggestedTags'] ?? []);
      final suggestedCategory = data['suggestedCategory'] as String? ?? 'Inbox';

      // 🆕 Bounding Box 정보가 포함된 OCR 블록 파싱
      final rawOcrBlocks = data['ocrBlocks'] as List? ?? [];
      final ocrBlocks = rawOcrBlocks.map<OCRBlock>((block) {
        if (block is Map) {
          return OCRBlock.fromNative(Map<String, dynamic>.from(block));
        }
        return OCRBlock(
          text: block.toString(),
          boundingBox: BoundingBox(top: 0, left: 0, width: 0, height: 0),
        );
      }).toList();

      logInfo('   - OCR 블록 수: ${ocrBlocks.length}', name: 'Home');

      // 이미지를 앱의 영구 저장소에 복사
      final permanentPath = await _saveToDocuments(File(imagePath));

      // 🎯 통합 분석 서비스 사용 (일관된 결과 보장)
      // imagePath 전달: OpenAI Vision 활성 시 저해상도 이미지를 함께 분석해
      // OCR이 놓친 시각적 맥락(레이아웃, 이미지)까지 반영한다.
      final analysis = await UnifiedAnalysisService.analyze(
        blocks: ocrBlocks,
        ocrText: ocrText,
        suggestedCategory: suggestedCategory,
        sourceType: 'screenshot',
        imagePath: permanentPath,
      );

      // 최근에 URL 공유로 이미 저장된 같은 기사/페이지라면 스크린샷 중복 저장을 건너뛴다.
      if (_isDuplicateOfRecentCapture(analysis.title, otherSourceTypes: {'url'})) {
        logInfo('⏭️ 최근 URL 카드와 제목이 겹쳐 스크린샷 저장을 건너뜀: ${analysis.title}', name: 'Home');
        if (mounted) {
          setState(() {
            _cards.removeWhere((c) => c.id == tempId);
          });
        }
        return;
      }

      // UI 노이즈가 필터링된 OCR 텍스트 생성
      String finalOcrText = _generateCleanOcrText(ocrBlocks);
      if (finalOcrText.isEmpty) {
        // 필터링 결과가 비어있으면 원본 사용
        finalOcrText = ocrText;
      }
      if (finalOcrText.isEmpty) {
        final fileName = imagePath.split('/').last;
        final now = DateTime.now();
        finalOcrText = "Screenshot captured on ${now.month}/${now.day}/${now.year} at ${now.hour}:${now.minute}. Filename: $fileName. Add personal notes for insights.";
      }

      // URL 추출
      final urlRegExp = RegExp(r"(https?:\/\/[^\s]+[\w\/])|(www\.[^\s]+[\w\/])|([a-zA-Z0-9-]+\.com\/[^\s]*)");
      final String? foundUrl = urlRegExp.firstMatch(finalOcrText)?.group(0);

      // 태그/카테고리: 분석 결과 우선, 없으면 네이티브 제안 → 휴리스틱 순
      final List<String> finalTags = analysis.tags.isNotEmpty
          ? analysis.tags
          : (suggestedTags.isNotEmpty
              ? suggestedTags
              : TextHeuristics.extractTags(finalOcrText));

      final String finalCategory = analysis.category ??
          (suggestedCategory != 'Inbox'
              ? suggestedCategory
              : TextHeuristics.detectCategory(finalOcrText));

      // 새 카드 생성 (Real Card)
      final newCard = MemoCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: analysis.title.length > 40 ? "${analysis.title.substring(0, 40)}..." : analysis.title,
        summary: analysis.summary,
        category: finalCategory,
        contentType: analysis.contentType,
        tags: finalTags,
        keyInsights: analysis.keyInsights,
        captureDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        imageUrl: permanentPath,
        ocrText: finalOcrText,
        sourceUrl: foundUrl,
        personalNote: null,
        folderId: _selectedFolder?.id, // 현재 선택된 폴더에 저장
        sourceType: 'screenshot', // Explicitly set sourceType
      );

      // 데이터베이스에 저장
      await _repository.create(newCard);

      // 임시 카드 교체 및 목록 새로고침
      if (mounted) {
          setState(() {
             final index = _cards.indexWhere((c) => c.id == tempId);
             if (index != -1) {
                 _cards[index] = newCard;
             } else {
                 _cards.insert(0, newCard);
             }
          });
      }
      
      // Force reload to be sure
      // await _refreshCards(); // Optional, avoiding flicker
      await _loadFolders();

      // 성공 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 New screenshot automatically saved!'),
            backgroundColor: AppTheme.accentTeal,
            duration: Duration(seconds: 3),
          ),
        );
      }

      logInfo('✅ Screenshot automatically processed and saved!', name: 'Home');
    } catch (e) {
      logInfo('❌ Error processing new screenshot: $e', name: 'Home');
      if (mounted) {
          // Remove temp card on error
          setState(() {
               _cards.removeWhere((c) => c.id == tempId);
          });
          
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing screenshot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
     // No global loading state to reset
    }
  }

  Future<void> _loadFolders() async {
    final folders = await _repository.getAllFolders();
    setState(() {
      _folders = folders;
    });
  }

  Future<void> _refreshCards() async {
    setState(() => _isAnalyzing = true);
    List<MemoCard> cards;
    if (_selectedFolder != null) {
      cards = await _repository.getByFolder(_selectedFolder!.id);
    } else {
      cards = await _repository.getAll();
    }
    setState(() {
      _cards = cards;
      _isAnalyzing = false;
    });
  }

  void _selectFolder(Folder? folder) {
    setState(() {
      _selectedFolder = folder;
    });
    _refreshCards();
  }

  List<MemoCard> get _filteredCards {
    // 검색 중이면 DB 전문 검색(FTS) 결과를 기준으로 필터링.
    // 검색 결과가 아직 도착하지 않았으면(디바운스 대기) 기존 목록으로 임시 필터.
    List<MemoCard> filtered;
    if (_searchQuery.isNotEmpty && _searchResults != null) {
      filtered = _searchResults!;
    } else if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = _cards.where((card) {
        return card.title.toLowerCase().contains(query) ||
               card.summary.toLowerCase().contains(query) ||
               (card.ocrText?.toLowerCase().contains(query) ?? false) ||
               card.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    } else {
      filtered = _cards;
    }

    // 1. Filter by Folder
    if (_selectedFolder != null) {
      filtered = filtered.where((card) => card.folderId == _selectedFolder!.id).toList();
    }

    // 2. Filter by Favorite
    if (_showFavoriteOnly) {
      filtered = filtered.where((card) => card.isFavorite).toList();
    }

    // 3. Filter by Type (SourceType)
    if (_selectedType != null) {
      filtered = filtered.where((card) => card.sourceType == _selectedType).toList();
    }

    // 4. Sort by captureDate (latest first)
    filtered = List<MemoCard>.from(filtered)
      ..sort((a, b) => b.captureDate.compareTo(a.captureDate));

    return filtered;
  }

  Future<void> _handleCapture() async {
    logInfo('🔵 _handleCapture called', name: 'Home');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
            left: BorderSide(color: Theme.of(context).dividerColor),
            right: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildSheetOption(
              icon: Platform.isMacOS ? Icons.add_photo_alternate_outlined : Icons.screenshot_monitor,
              title: Platform.isMacOS ? AppLocalizations.of(context)!.sheetImportGallery : AppLocalizations.of(context)!.sheetImportScreenshot,
              subtitle: Platform.isMacOS
                  ? AppLocalizations.of(context)!.sheetImportImageSubtitleDesktop
                  : AppLocalizations.of(context)!.sheetImportImageSubtitleMobile,
              onTap: () {
                logInfo('🟢 Import Image button tapped', name: 'Home');
                Navigator.pop(ctx);
                _importLastScreenshot();
              },
            ),
            const SizedBox(height: 12),
            _buildSheetOption(
              icon: Platform.isMacOS ? Icons.photo_library_outlined : Icons.camera_alt_outlined,
              title: Platform.isMacOS ? AppLocalizations.of(context)!.sheetImportGallery : AppLocalizations.of(context)!.sheetTakePhoto,
              subtitle: Platform.isMacOS
                  ? AppLocalizations.of(context)!.sheetTakePhotoSubtitleDesktop
                  : AppLocalizations.of(context)!.sheetTakePhotoSubtitleMobile,
              onTap: () {
                logInfo('🟡 Choose Image button tapped', name: 'Home');
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
            const SizedBox(height: 12),
            _buildSheetOption(
              icon: Icons.link,
              title: AppLocalizations.of(context)!.sheetPasteUrl,
              subtitle: AppLocalizations.of(context)!.sheetPasteUrlSubtitle,
              onTap: () {
                logInfo('🔵 Paste URL button tapped', name: 'Home');
                Navigator.pop(ctx);
                _handlePasteUrl();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    logInfo('🟣 _pickImageFromGallery started', name: 'Home');
    try {
      logInfo('🟣 Opening image picker...', name: 'Home');
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      logInfo('🟣 Image picker returned: ${image?.path ?? "null"}', name: 'Home');
      
      if (image == null) {
        logInfo('🟣 No image selected', name: 'Home');
        setState(() => _isAnalyzing = false);
        return;
      }

      final permanentPath = await _saveToDocuments(File(image.path));
      logInfo('🟣 Image saved to: $permanentPath', name: 'Home');
    
      // macOS에서는 네이티브 서비스 사용 불가, fallback 사용
      String ocrText = _generateMacOSFallback(permanentPath);
      final suggestedTags = ['Imported', 'Photo'];
      final suggestedCategory = 'Inbox';

      await _createCardFromAnalysis(
        permanentPath, 
        ocrText, 
        suggestedTags, 
        suggestedCategory,
        sourceType: 'photo',
      );
    } catch (e) {
      logInfo('🔴 Error in _pickImageFromGallery: $e', name: 'Home');
      setState(() => _isAnalyzing = false);
    }
  }

  /// URL 붙여넣기 및 처리
  Future<void> _handlePasteUrl() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;

      if (text == null || text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.msgClipboardEmpty)),
          );
        }
        return;
      }

      // 간단한 URL 확인
      final urlRegExp = RegExp(r"(https?:\/\/[^\s]+[\w\/])|(www\.[^\s]+[\w\/])");
      if (!urlRegExp.hasMatch(text)) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.msgInvalidUrl)),
          );
        }
        return;
      }

      setState(() => _isAnalyzing = true);

      // Create a temporary SharedItem to leverage existing ShareService logic
      final tempItem = SharedItem(
        type: 'url',
        url: text,
        timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
        title: 'Analyzing Link...',
      );

      // Process it
      final processedItem = await _shareService.processSharedItem(tempItem);
      
      // Create Card
      await _createCardFromSharedItem(processedItem, saveToDb: true);
      
      // UI Update
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
               content: Text(AppLocalizations.of(context)!.msgLinkSaved),
               backgroundColor: AppTheme.accentTeal,
            ),
         );
      }

    } catch (e) {
      logInfo('URL Paste Error: $e', name: 'Home');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.msgUrlProcessError('$e'))),
        );
      }
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // macOS용 Fallback (iOS/Android는 네이티브 서비스 사용)
  String _generateMacOSFallback(String imagePath) {
    logInfo('ℹ️ macOS detected - Using fallback content', name: 'Home');
    final fileName = imagePath.split('/').last;
    final now = DateTime.now();
    
    return 'Visual Memory Captured\n'
        'Import Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}\n'
        'Time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}\n'
        'Source: $fileName\n\n'
        'Tap to edit and add your own notes and insights about this image. '
        'You can describe what you see, add context, or save important details for future reference.\n\n'
        'Note: Advanced OCR text extraction is available on iOS and Android devices.';
  }

  /// UI 노이즈가 필터링된 깨끗한 OCR 텍스트 생성
  String _generateCleanOcrText(List<OCRBlock> blocks) {
    // OnDeviceLLMService의 필터링 로직 재사용
    final cleanedBlocks = OnDeviceLLMService.filterUINoiseBlocksPublic(blocks);

    if (cleanedBlocks.isEmpty) return '';

    // 블록을 위치 기준으로 정렬 (위에서 아래로, 왼쪽에서 오른쪽으로)
    cleanedBlocks.sort((a, b) {
      // Y 위치가 비슷하면 (3% 이내) X 위치로 정렬
      if ((a.boundingBox.top - b.boundingBox.top).abs() < 0.03) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return a.boundingBox.top.compareTo(b.boundingBox.top);
    });

    // 문단 그룹화 (줄 간격 기반)
    final paragraphs = <String>[];
    List<String> currentLine = [];
    double lastBottom = 0;

    for (final block in cleanedBlocks) {
      final text = block.text.trim();
      if (text.isEmpty) continue;

      final verticalGap = block.boundingBox.top - lastBottom;

      // 줄 간격이 크면 새 문단
      if (lastBottom > 0 && verticalGap > 0.04 && currentLine.isNotEmpty) {
        paragraphs.add(currentLine.join(' '));
        currentLine = [];
      }

      currentLine.add(text);
      lastBottom = block.boundingBox.bottom;
    }

    if (currentLine.isNotEmpty) {
      paragraphs.add(currentLine.join(' '));
    }

    return paragraphs.join('\n\n');
  }

  /// 가장 최근 스크린샷 불러오기 (Photos Library) - Enhanced
  Future<void> _importLastScreenshot() async {
    setState(() => _isAnalyzing = true);
    
    // 권한 요청
    if (await Permission.photos.request().isGranted) {
      try {
        // 1. Enhanced 분석 (NEW)
        final analysisData = await NativeService.getLastScreenshotAnalysisEnhanced();
        
        if (analysisData.isEmpty) {
          throw Exception(AppLocalizations.of(context)!.errNoScreenshotFound);
        }
        
        // 2. OCR 블록 변환
        final ocrBlocks = (analysisData['ocrBlocks'] as List?)
            ?.map((block) => OCRBlock.fromNative(Map<String, dynamic>.from(block)))
            .toList() ?? [];
        
        if (ocrBlocks.isEmpty) {
          throw Exception(AppLocalizations.of(context)!.analysisEmptyText);
        }
        
        // Image Path Handling (분석 전에 복사해 Vision 분석에 사용)
        final imagePath = analysisData['imagePath'];
        final permanentPath = await _saveToDocuments(File(imagePath));

        // 3. 통합 분석 서비스 사용
        final analysis = await UnifiedAnalysisService.analyze(
          blocks: ocrBlocks,
          ocrText: analysisData['ocrText'] as String?,
          suggestedCategory: null,
          imageSize: analysisData['imageSize'],
          layoutRegions: analysisData['layoutRegions'],
          importantAreas: analysisData['importantAreas'],
          sourceType: 'screenshot',
          imagePath: permanentPath,
        );

        // 4. MemoCard 생성 — 분석 결과의 카테고리/태그/인사이트를 그대로 반영
        final card = MemoCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: analysis.title,
          summary: analysis.summary,
          category: analysis.category ?? 'Inbox',
          contentType: analysis.contentType,
          tags: analysis.tags,
          keyInsights: analysis.keyInsights,
          captureDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
          imageUrl: permanentPath,
          ocrText: analysisData['ocrText'] ?? '',
          sourceUrl: '',
          folderId: _selectedFolder?.id,
          sourceType: 'screenshot', // Explicitly set sourceType
        );

        // 5. DB 저장
        await _repository.create(card);
        
        // 6. UI 업데이트
        setState(() {
          _cards.insert(0, card);
        });
        
        // 성공 메시지
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.msgMemoCreated(card.title)),
                backgroundColor: AppTheme.accentTeal,
              ),
            );
        }
        
      } catch (e) {
        logInfo('Import failed: $e', name: 'Home');
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.msgAnalysisFailed('$e'))),
            );
        }
      } finally {
        if (mounted) setState(() => _isAnalyzing = false);
      }
    } else {
        if (mounted) setState(() => _isAnalyzing = false);
        openAppSettings();
    }
  }

  /// AI 분석 결과를 바탕으로 카드 생성 및 저장
  Future<void> _createCardFromAnalysis(
    String imagePath,
    String ocrText,
    List<String> suggestedTags,
    String suggestedCategory, {
    String? suggestedTitle,
    String? sourceUrl,
    List<OCRBlock>? ocrBlocks, // Optional blocks for better analysis
    ScreenshotAnalysis? preAnalysis, // Optional pre-computed analysis
    String sourceType = 'screenshot', // New parameter
  }) async {
    try {
      // 1. Analyze Content (Structure, Summary)
      // If we already analyzed it (e.g. in _pickImage or _handleNewScreenshot), use it.
      ScreenshotAnalysis analysis;
      if (preAnalysis != null) {
          analysis = preAnalysis;
      } else {
          // Otherwise, analyze now.
          // Note: If ocrBlocks is null, it falls back to line-based estimation.
          analysis = await _analyzeScreenshotOnDevice(
              ocrText,
              ocrBlocks: ocrBlocks,
              suggestedCategory: suggestedCategory,
              imagePath: imagePath,
          );
      }

      // 2. Finalize Metadata
      // Use suggested title if analysis title is generic or empty, but prefer analysis if structured
      String title = analysis.title;
      if ((title == "New Memory" || title.isEmpty) && suggestedTitle != null && suggestedTitle.isNotEmpty) {
           title = suggestedTitle;
      }

      // 카테고리/태그: 분석 결과 우선, 없으면 호출부 제안값 사용
      final String category = analysis.category ?? suggestedCategory;
      final List<String> tags = analysis.tags.isNotEmpty ? analysis.tags : suggestedTags;

      // 3. Create Card Object
      final newCard = MemoCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.length > 50 ? "${title.substring(0, 47)}..." : title,
        summary: analysis.summary,
        category: category,
        contentType: analysis.contentType,
        tags: tags,
        captureDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        imageUrl: imagePath,
        ocrText: ocrText,
        sourceUrl: sourceUrl,
        keyInsights: analysis.keyInsights,
        sourceType: sourceType, // Use the new parameter
      );

      // 4. Save to DB
      await _repository.create(newCard);

      // 5. Refresh UI
      if (mounted) {
          setState(() {
            _cards.insert(0, newCard);
          });
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(AppLocalizations.of(context)!.msgMemoCreated(newCard.title)),
               backgroundColor: AppTheme.accentTeal,
               duration: const Duration(seconds: 2),
             ),
          );
      }
      
    } catch (e) {
      logInfo("Error creating card: $e", name: 'Home');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating card: ${e.toString()}")),
        );
      }
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }
  
  /// 온디바이스 스크린샷 분석 (규칙 기반 구조 분석 + 도메인 분류)
  Future<ScreenshotAnalysis> _analyzeScreenshotOnDevice(
    String ocrText, {
    List<OCRBlock>? ocrBlocks,
    String? suggestedCategory,
    String? imagePath,
  }) async {
    if (ocrText.trim().isEmpty) {
      return ScreenshotAnalysis(
        title: AppLocalizations.of(context)!.analysisEmptyTitle,
        summary: AppLocalizations.of(context)!.analysisEmptyText,
        keyInsights: [],
      );
    }

    // 🆕 Bounding Box가 있으면 직접 사용, 없으면 줄 단위로 생성
    List<OCRBlock> blocks;
    if (ocrBlocks != null && ocrBlocks.isNotEmpty) {
      blocks = ocrBlocks;
      logInfo('   ✅ Bounding Box 정보 사용: ${blocks.length}개 블록', name: 'Home');
    } else {
      // Fallback: 줄 단위로 OCR 블록 생성 (Bounding Box 없음)
      final lines = ocrText.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && line.length > 2)
          .toList();

      if (lines.isEmpty) {
        return ScreenshotAnalysis(
          title: "New Memory",
          summary: AppLocalizations.of(context)!.analysisSavedText,
          keyInsights: [],
        );
      }

      // 줄 번호 기반으로 대략적인 위치 추정 (DocumentParserService를 위해 가짜 박스 생성)
      blocks = lines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;
        final estimatedTop = index / lines.length;
        
        // 텍스트 길이로 너비 대략 추정
        final estimatedWidth = (line.length * 0.02).clamp(0.1, 0.9);

        return OCRBlock(
          text: line,
          boundingBox: BoundingBox(
            top: estimatedTop,
            left: 0.05,
            width: estimatedWidth.toDouble(), // double casting
            height: 0.03,
          ),
        );
      }).toList();
      logInfo('   ⚠️ Bounding Box 없음, 줄 기반 추정 사용: ${blocks.length}개 블록', name: 'Home');
    }

    // 🚀 통합 분석 서비스 사용 (단계적 Fallback 포함)
    return await UnifiedAnalysisService.analyze(
      blocks: blocks,
      ocrText: ocrText,
      suggestedCategory: suggestedCategory,
      imagePath: imagePath,
    );
  }

  Future<void> _pickImage() async {
    logInfo('🟠 _pickImage started', name: 'Home');
    try {
      logInfo('🟠 Opening image picker (${Platform.isMacOS ? "gallery" : "camera"})...', name: 'Home');
      final XFile? image = await _picker.pickImage(
        source: Platform.isMacOS ? ImageSource.gallery : ImageSource.camera,
      );
      logInfo('🟠 Image picker returned: ${image?.path ?? "null"}', name: 'Home');
      
      if (image == null) {
        logInfo('🟠 No image selected', name: 'Home');
        return;
      }

    setState(() => _isAnalyzing = true);

    final permanentPath = await _saveToDocuments(File(image.path));

    if (Platform.isIOS) {
        // iOS: Native Vision Framework Analysis
        logInfo('🟠 Running native analysis on iOS...', name: 'Home');
        final result = await NativeService.analyzeImageWithBoxes(permanentPath);
        
        if (result != null) {
             final ocrText = result['ocrText'] as String? ?? '';
             final suggestedTags = List<String>.from(result['suggestedTags'] ?? ['Photo']);
             final suggestedCategory = result['suggestedCategory'] as String? ?? 'Inbox';
             
             // 🆕 Bounding Box 정보가 포함된 OCR 블록 파싱 (Checking for existence)
             final rawOcrBlocks = result['ocrBlocks'] as List? ?? [];
             List<OCRBlock>? ocrBlocks;

             if (rawOcrBlocks.isNotEmpty) {
                 ocrBlocks = rawOcrBlocks.map<OCRBlock>((block) {
                    if (block is Map) {
                      return OCRBlock.fromNative(Map<String, dynamic>.from(block));
                    }
                    return OCRBlock(
                      text: block.toString(),
                      boundingBox: BoundingBox(top: 0, left: 0, width: 0, height: 0),
                    );
                  }).toList();
             }

             // 통합 분석 서비스 사용 (Vision 활성 시 이미지 포함)
             final analysis = await UnifiedAnalysisService.analyze(
                blocks: ocrBlocks,
                ocrText: ocrText,
                suggestedCategory: suggestedCategory,
                sourceType: 'photo',
                imagePath: permanentPath,
             );

             // Create card with analyzed data
             // preAnalysis 전달로 중복 분석(이중 API 호출) 방지
             await _createCardFromAnalysis(
                permanentPath,
                ocrText,
                suggestedTags,
                suggestedCategory,
                suggestedTitle: analysis.title,
                preAnalysis: analysis,
                sourceType: 'photo', // Explicitly set sourceType
             );
        } else {
             // Fallback if native analysis fails
             logInfo('🔴 Native analysis returned null', name: 'Home');
             await _createCardFromAnalysis(
                permanentPath,
                "",
                ['Photo'],
                'Inbox',
                suggestedTitle: AppLocalizations.of(context)!.titleNewMemo,
                sourceType: 'photo',
             );
        }

      } else {
        // macOS / Other: Fallback
        String ocrText = _generateMacOSFallback(permanentPath);
        final suggestedTags = ['Camera', 'Photo'];
        final suggestedCategory = 'Inbox';

        await _createCardFromAnalysis(
          permanentPath, 
          ocrText, 
          suggestedTags, 
          suggestedCategory,
          sourceType: 'photo',
        );
      }
    } catch (e) {
      logInfo('🔴 Error in _pickImage: $e', name: 'Home');
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  Future<String> _saveToDocuments(File sourceFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = "capture_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final targetPath = "${directory.path}/$fileName";
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              if (_showSearch) _buildSearchBar(),
              if (_selectedFolder != null) _buildFolderBanner(),
              _buildFilterBar(),
              Expanded(child: _buildContent()),
            ],
          ),

          // Loading Overlay
          if (_isAnalyzing) _buildLoadingOverlay(),

          // FAB - Fixed position (Right-bottom corner)
          Positioned(
            bottom: 24, // Adjusted position since nav bar is gone
            right: 24,
            child: _buildFAB(),
          ),

          // Custom Bottom Navigation Bar
// Custom Bottom Navigation Bar removed as per request
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   right: 0,
          //   child: _buildBottomNavBar(),
          // ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        // Border removed for cleaner look
        // border: Border(
        //   bottom: BorderSide(color: Theme.of(context).dividerColor),
        // ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Area
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.transparent, 
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Rememo",
                style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Right actions: Search | Settings
          Row(
            children: [
              _buildHeaderIconButton(
                icon: _showSearch ? Icons.close : Icons.search,
                isActive: _showSearch,
                onTap: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchQuery = '';
                    _searchController.clear();
                    _searchResults = null;
                    _searchDebounce?.cancel();
                  }
                }),
              ),
              const SizedBox(width: 8),
              _buildHeaderIconButton(
                icon: Icons.settings_outlined,
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                   ).then((_) => _loadFolders()); 
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon, 
    VoidCallback? onTap, 
    bool isActive = false
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40, 
          height: 40,
          alignment: Alignment.center,
          decoration: isActive ? BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ) : null,
          child: Icon(
            icon,
            color: isActive 
                ? Theme.of(context).primaryColor 
                : Theme.of(context).iconTheme.color,
            size: 24,
          ),
        ),
      ),
    );
  }

  // _buildBottomNavBar method removed

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      color: Theme.of(context).appBarTheme.backgroundColor, 
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: _onSearchChanged,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchHint,
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none, 
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Widget _buildFolderBanner() {
    if (_selectedFolder == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _hexToColor(_selectedFolder!.color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hexToColor(_selectedFolder!.color).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.folder,
              color: _hexToColor(_selectedFolder!.color),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedFolder!.name,
                style: TextStyle(
                  color: _hexToColor(_selectedFolder!.color),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _selectFolder(null),
              child: Icon(
                Icons.close,
                color: _hexToColor(_selectedFolder!.color),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: bgColor,
      child: Row(
        children: [
          // Favorite Toggle (독립 토글)
          _buildFavoriteToggle(),
          const SizedBox(width: 12),

          // Folders Dropdown
          Expanded(
            child: _buildFilterDropdown<Folder?>(
              label: _selectedFolder?.name ?? AppLocalizations.of(context)!.filterFolder,
              icon: Icons.folder_outlined,
              items: [
                DropdownMenuItem<Folder?>(value: null, child: Text(AppLocalizations.of(context)!.filterAll)),
                ..._folders.map((f) => DropdownMenuItem<Folder?>(
                  value: f,
                  child: Text(f.name),
                )),
              ],
              value: _selectedFolder,
              onChanged: (Folder? folder) {
                setState(() => _selectedFolder = folder);
              },
            ),
          ),
          const SizedBox(width: 8),

          // Type Dropdown (Source Type)
          Expanded(
            child: _buildFilterDropdown<String?>(
              label: _selectedType != null
                  ? (_selectedType == 'screenshot' ? AppLocalizations.of(context)!.typeScreenshot
                      : _selectedType == 'url' ? AppLocalizations.of(context)!.typeUrl
                      : AppLocalizations.of(context)!.typePhoto)
                  : AppLocalizations.of(context)!.filterType,
              icon: Icons.category_outlined,
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(AppLocalizations.of(context)!.filterAll)),
                DropdownMenuItem<String?>(value: 'screenshot', child: Text(AppLocalizations.of(context)!.typeScreenshot)),
                DropdownMenuItem<String?>(value: 'url', child: Text(AppLocalizations.of(context)!.typeUrl)),
                DropdownMenuItem<String?>(value: 'photo', child: Text(AppLocalizations.of(context)!.typePhoto)),
              ],
              value: _selectedType,
              onChanged: (String? type) {
                setState(() => _selectedType = type);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _showFavoriteOnly;

    return GestureDetector(
      onTap: () => setState(() => _showFavoriteOnly = !_showFavoriteOnly),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.amber.withOpacity(0.15)
              : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Colors.amber.withOpacity(0.4)
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.star : Icons.star_outline,
              size: 18,
              color: isActive ? Colors.amber : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF636366)),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.filterFavorite,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildFilterDropdown<T>({
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required T? value,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161616) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1A1A1A);
    final iconColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF636366);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5EA),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: Icon(Icons.arrow_drop_down, color: iconColor, size: 20),
          isExpanded: true,
          isDense: true,
          dropdownColor: bgColor,
          style: TextStyle(fontSize: 14, color: textColor),
          items: items,
          onChanged: onChanged,
          hint: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 14, color: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final displayCards = _filteredCards;

    if (displayCards.isEmpty && !_isAnalyzing) {
      if (_searchQuery.isNotEmpty) {
        return _buildNoSearchResultsView();
      }
      return EmptyStateView(
        onAddFirst: _handleCapture,
        onLearnMore: () {},
      );
    }

    return Padding(
      padding: EdgeInsets.zero, // Removed bottom padding using zero
      child: LibraryListView(
        cards: displayCards,
        folders: _folders,
        onSelect: _navigateToDetail,
        onDelete: _deleteCard,
        onTitleEdit: _updateCardTitle,
      ),
    );
  }

  Widget _buildNoSearchResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_outlined,
                size: 48,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.emptyFilter,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.searchNoResult(_searchQuery),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).disabledColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Analyzing...",
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _handleCapture,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
             BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
              offset: const Offset(0, 8),
              blurRadius: 24,
              spreadRadius: -4,
             )
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white, 
          size: 28,
        ),
      ),
    );
  }

  Future<void> _updateCardTitle(MemoCard card, String newTitle) async {
    final updatedCard = card.copyWith(title: newTitle);
    await _repository.update(updatedCard);
    
    if (mounted) {
       setState(() {
         final index = _cards.indexWhere((c) => c.id == card.id);
         if (index != -1) _cards[index] = updatedCard;
       });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(AppLocalizations.of(context)!.msgTitleUpdated), backgroundColor: Theme.of(context).cardColor)
       );
    }
  }

  Future<void> _deleteCard(MemoCard card) async {
    await _repository.delete(card.id);
    if (!card.imageUrl.startsWith('http')) {
      try {
        final file = File(card.imageUrl);
        if (await file.exists()) await file.delete();
      } catch (e) { logWarn('이미지 파일 삭제 실패: $e', name: 'Home'); }
    }
    setState(() {
      _cards.removeWhere((c) => c.id == card.id);
    });
  }

  void _navigateToDetail(MemoCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailViewScreen(
          card: card,
          folders: _folders,
          onDelete: () async { await _deleteCard(card); },
          onUpdate: (updatedCard) async {
            await _repository.update(updatedCard);
            setState(() {
              final index = _cards.indexWhere((c) => c.id == updatedCard.id);
              if (index != -1) _cards[index] = updatedCard;
            });
          },
          onOpenLink: (url) async {
            final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
        ),
      ),
    );
  }
}
