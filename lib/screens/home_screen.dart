import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/models/folder.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/widgets/library_list_view.dart';
import 'package:stribe/widgets/detail_view_screen.dart';
import 'package:stribe/widgets/empty_state_view.dart';
import 'package:stribe/widgets/folder_management_view.dart';
import 'package:stribe/services/database_helper.dart';
import 'package:stribe/services/native_service.dart';
import 'package:stribe/services/ondevice_llm_service.dart';
import 'package:stribe/services/share_service.dart';
import 'package:stribe/services/document_parser_service.dart';
import 'package:stribe/screens/settings_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
// Google ML Kit removed - using native Vision Framework (iOS) instead
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
  bool _isAnalyzing = false;
  List<MemoCard> _cards = [];
  List<Folder> _folders = [];
  Folder? _selectedFolder;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    _stopScreenshotMonitoring(); // 스크린샷 모니터링 중지
    super.dispose();
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
        print('📥 ${items.length}개의 공유된 항목 발견');
        setState(() {
          _pendingSharedItems = items;
          _hasNewSharedItems = true;
        });

        // 자동으로 공유된 항목 처리
        _processSharedItems();
      }
    } catch (e) {
      print('❌ 공유된 항목 확인 실패: $e');
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

        print('📦 처리 중: ${item.type} - ${item.displayTitle}');

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
            content: Text('📥 $count개의 공유된 항목이 저장되었습니다!'),
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
      print('❌ 공유된 항목 처리 실패: $e');
      // On error, remove temp cards
      setState(() {
         _cards.removeWhere((c) => c.id.startsWith('temp_'));
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공유된 항목 처리 중 오류: $e'),
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

    // 🚀 Advanced Analysis using DocumentParserService logic
    // Even for web links, we can use the parser to extract better summary & insights
    String finalTitle = item.displayTitle;
    String finalSummary = item.summary ?? '';
    List<String> finalInsights = [];
    String finalCategory = item.category ?? 'Inbox';
    List<String> finalTags = item.tags ?? ['Shared'];
    String finalOcrText = item.ocrText ?? item.text ?? '';

    if (finalOcrText.isNotEmpty) {
        try {
            print("🔍 Analyzing shared content via DocumentParserService...");
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
            if (finalTitle.isEmpty || finalTitle == 'Web Link') {
                finalTitle = analysis.title;
            }
            finalInsights = analysis.keyInsights;
            
            // Add detailed insights to tags if tags are sparse
            if (finalTags.length < 3) {
                 finalTags.addAll(finalInsights.take(2));
                 finalTags = finalTags.toSet().toList(); // Dedup
            }

            print("✅ Web content analyzed: ${analysis.title}");
        } catch (e) {
            print("⚠️ Shared content analysis passed (using defaults): $e");
        }
    }

    // Fallback Summary Logic
    if (finalSummary.isEmpty) {
        if (finalOcrText.isNotEmpty) {
           finalSummary = finalOcrText.length > 200 
               ? '${finalOcrText.substring(0, 200)}...' 
               : finalOcrText;
        } else {
           finalSummary = item.hasUrl ? '웹 링크가 저장되었습니다.' : '공유된 컨텐츠가 저장되었습니다.';
        }
    }

    final newCard = MemoCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: finalTitle.length > 50 ? "${finalTitle.substring(0, 47)}..." : finalTitle,
      summary: finalSummary,
      category: finalCategory,
      tags: finalTags,
      captureDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      imageUrl: finalImagePath,
      ocrText: finalOcrText,
      sourceUrl: item.sourceUrl,
      personalNote: item.selectedText,
      folderId: _selectedFolder?.id,
      keyInsights: finalInsights, // Now we have insights!
    );
     
    if (saveToDb) {
        await DatabaseHelper.instance.create(newCard);
        print('✅ 공유된 항목 저장됨: ${newCard.title}');
    }

    return newCard;
  }

  /// 스크린샷 자동 모니터링 시작
  Future<void> _startScreenshotMonitoring() async {
    // iOS에서만 권한 요청 (macOS는 permission_handler가 지원 안 함)
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (!status.isGranted && !status.isLimited) {
        print('📸 Photo permission not granted, skipping screenshot monitoring');
        return;
      }
    }

    final success = await NativeService.startScreenshotMonitoring(
      onScreenshotDetected: _handleNewScreenshot,
    );

    if (success) {
      print('✅ Screenshot monitoring started successfully');
    } else {
      print('❌ Failed to start screenshot monitoring');
    }
  }

  /// 스크린샷 모니터링 중지
  Future<void> _stopScreenshotMonitoring() async {
    await NativeService.stopScreenshotMonitoring();
    print('⏹️ Screenshot monitoring stopped');
  }

  /// 새 스크린샷이 감지되었을 때 자동으로 호출되는 핸들러
  Future<void> _handleNewScreenshot(Map<String, dynamic> data) async {
    print('📸 New screenshot detected: ${data['imagePath']}');

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

      print('   - OCR 블록 수: ${ocrBlocks.length}');

      // 이미지를 앱의 영구 저장소에 복사
      final permanentPath = await _saveToDocuments(File(imagePath));

      // 🎯 온디바이스 분석으로 스마트한 제목과 요약 생성 (Bounding Box 포함)
      final analysis = await _analyzeScreenshotOnDevice(
          ocrText, 
          ocrBlocks: ocrBlocks,
          suggestedCategory: suggestedCategory
      );

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

      // Summary는 간결하게 유지 (블릿 포인트 제거)
      String summary = analysis.summary;

      // 태그 및 카테고리
      List<String> finalTags = suggestedTags.isEmpty
          ? _extractTagsFromText(finalOcrText)
          : suggestedTags;

      String finalCategory = suggestedCategory != 'Inbox'
          ? suggestedCategory
          : _detectCategory(finalOcrText);

      // 새 카드 생성 (Real Card)
      final newCard = MemoCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: analysis.title.length > 40 ? "${analysis.title.substring(0, 40)}..." : analysis.title,
        summary: summary,
        category: analysis.title == 'Shopping Item' ? 'Shopping' : finalCategory, // Simple override check
        tags: finalTags,
        captureDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        imageUrl: permanentPath,
        ocrText: finalOcrText,
        sourceUrl: foundUrl,
        personalNote: null,
        folderId: _selectedFolder?.id, // 현재 선택된 폴더에 저장
      );

      // 데이터베이스에 저장
      await DatabaseHelper.instance.create(newCard);

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

      print('✅ Screenshot automatically processed and saved!');
    } catch (e) {
      print('❌ Error processing new screenshot: $e');
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
    final folders = await DatabaseHelper.instance.readAllFolders();
    setState(() {
      _folders = folders;
    });
  }

  Future<void> _refreshCards() async {
    setState(() => _isAnalyzing = true);
    List<MemoCard> cards;
    if (_selectedFolder != null) {
      cards = await DatabaseHelper.instance.readMemoCardsByFolder(_selectedFolder!.id);
    } else {
      cards = await DatabaseHelper.instance.readAllMemoCards();
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
    if (_searchQuery.isEmpty) return _cards;
    final query = _searchQuery.toLowerCase();
    return _cards.where((c) =>
        c.title.toLowerCase().contains(query) ||
        c.summary.toLowerCase().contains(query) ||
        c.category.toLowerCase().contains(query) ||
        c.tags.any((t) => t.toLowerCase().contains(query)) ||
        (c.ocrText?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  Future<void> _handleCapture() async {
    print('🔵 _handleCapture called');
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
              title: Platform.isMacOS ? "Import Image" : "Import Last Screenshot",
              subtitle: Platform.isMacOS ? "Add image from your library" : "Analyze your most recent capture",
              onTap: () {
                print('🟢 Import Image button tapped');
                Navigator.pop(ctx);
                _importLastScreenshot();
              },
            ),
            const SizedBox(height: 12),
            _buildSheetOption(
              icon: Platform.isMacOS ? Icons.photo_library_outlined : Icons.camera_alt_outlined,
              title: Platform.isMacOS ? "Choose Image" : "Take Photo",
              subtitle: Platform.isMacOS ? "Select from your files" : "Capture something new",
              onTap: () {
                print('🟡 Choose Image button tapped');
                Navigator.pop(ctx);
                _pickImage();
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
            border: Border.all(color: Theme.of(context).dividerColor),
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
    print('🟣 _pickImageFromGallery started');
    try {
      print('🟣 Opening image picker...');
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      print('🟣 Image picker returned: ${image?.path ?? "null"}');
      
      if (image == null) {
        print('🟣 No image selected');
        setState(() => _isAnalyzing = false);
        return;
      }

      final permanentPath = await _saveToDocuments(File(image.path));
      print('🟣 Image saved to: $permanentPath');
    
      // macOS에서는 네이티브 서비스 사용 불가, fallback 사용
      String ocrText = _generateMacOSFallback(permanentPath);
      final suggestedTags = ['Imported', 'Screenshot'];
      final suggestedCategory = 'Inbox';

      await _createCardFromAnalysis(permanentPath, ocrText, suggestedTags, suggestedCategory);
    } catch (e) {
      print('🔴 Error in _pickImageFromGallery: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  // macOS용 Fallback (iOS/Android는 네이티브 서비스 사용)
  String _generateMacOSFallback(String imagePath) {
    print('ℹ️ macOS detected - Using fallback content');
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

  List<String> _extractTagsFromText(String text) {
    final tags = <String>[];
    final lowerText = text.toLowerCase();
    
    // 다국어 키워드 기반 태그 추출
    final keywords = {
      // English
      'design': 'Design',
      'ui': 'Design',
      'ux': 'Design',
      'code': 'Tech',
      'programming': 'Tech',
      'tech': 'Tech',
      'development': 'Tech',
      'food': 'Food',
      'recipe': 'Food',
      'cooking': 'Food',
      'restaurant': 'Food',
      'work': 'Work',
      'meeting': 'Work',
      'office': 'Work',
      'project': 'Work',
      'buy': 'Shopping',
      'shopping': 'Shopping',
      'purchase': 'Shopping',
      'inspiration': 'Inspiration',
      'idea': 'Inspiration',
      'creative': 'Inspiration',
      
      // Korean
      '디자인': 'Design',
      '개발': 'Tech',
      '코드': 'Tech',
      '프로그래밍': 'Tech',
      '음식': 'Food',
      '요리': 'Food',
      '레시피': 'Food',
      '맛집': 'Food',
      '식당': 'Food',
      '회의': 'Work',
      '업무': 'Work',
      '작업': 'Work',
      '프로젝트': 'Work',
      '쇼핑': 'Shopping',
      '구매': 'Shopping',
      '영감': 'Inspiration',
      '아이디어': 'Inspiration',
    };
    
    for (final entry in keywords.entries) {
      if (lowerText.contains(entry.key.toLowerCase()) && !tags.contains(entry.value)) {
        tags.add(entry.value);
      }
    }
    
    if (tags.isEmpty) {
      tags.add('Screenshot');
      tags.add('Imported');
    }
    
    return tags.take(3).toList();
  }

  String _detectCategory(String text) {
    final lowerText = text.toLowerCase();
    
    // Design - English & Korean
    if (lowerText.contains('design') || 
        lowerText.contains('ui') || 
        lowerText.contains('ux') ||
        lowerText.contains('디자인')) {
      return 'Design';
    } 
    
    // Tech - English & Korean
    else if (lowerText.contains('code') || 
             lowerText.contains('programming') || 
             lowerText.contains('tech') ||
             lowerText.contains('development') ||
             lowerText.contains('코드') ||
             lowerText.contains('개발') ||
             lowerText.contains('프로그래밍')) {
      return 'Tech';
    } 
    
    // Food - English & Korean
    else if (lowerText.contains('food') || 
             lowerText.contains('recipe') ||
             lowerText.contains('cooking') ||
             lowerText.contains('restaurant') ||
             lowerText.contains('음식') ||
             lowerText.contains('요리') ||
             lowerText.contains('레시피') ||
             lowerText.contains('맛집') ||
             lowerText.contains('식당')) {
      return 'Food';
    } 
    
    // Work - English & Korean
    else if (lowerText.contains('work') || 
             lowerText.contains('meeting') ||
             lowerText.contains('office') ||
             lowerText.contains('project') ||
             lowerText.contains('업무') ||
             lowerText.contains('회의') ||
             lowerText.contains('작업') ||
             lowerText.contains('프로젝트')) {
      return 'Work';
    } 
    
    // Shopping - English & Korean
    else if (lowerText.contains('buy') || 
             lowerText.contains('shopping') ||
             lowerText.contains('purchase') ||
             lowerText.contains('쇼핑') ||
             lowerText.contains('구매')) {
      return 'Shopping';
    } 
    
    // Inspiration - English & Korean
    else if (lowerText.contains('inspiration') || 
             lowerText.contains('idea') ||
             lowerText.contains('creative') ||
             lowerText.contains('영감') ||
             lowerText.contains('아이디어')) {
      return 'Inspiration';
    }
    
    return 'Inbox';
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
          throw Exception('No screenshot found');
        }
        
        // 2. OCR 블록 변환
        final ocrBlocks = (analysisData['ocrBlocks'] as List?)
            ?.map((block) => OCRBlock.fromNative(Map<String, dynamic>.from(block)))
            .toList() ?? [];
        
        if (ocrBlocks.isEmpty) {
          throw Exception('No text detected');
        }
        
        // 3. Enhanced LLM 분석 (NEW)
        final llmResult = await OnDeviceLLMService.analyzeSummaryEnhanced(
          blocks: ocrBlocks,
          layoutRegions: analysisData['layoutRegions'],     // NEW
          importantAreas: analysisData['importantAreas'],   // NEW
          imageSize: analysisData['imageSize'],             // NEW
        );
        
        String title = llmResult['title'] ?? 'New Memory';
        String summary = llmResult['summary'] ?? '';
        List<String> tags = List<String>.from(llmResult['tags'] ?? []);
        String category = llmResult['contentType'] != 'general' ? llmResult['contentType'] : 'Inbox';
        
        // 대문자화 (Category)
        if (category.isNotEmpty) {
            category = category[0].toUpperCase() + category.substring(1);
        }
        
        // Image Path Handling
        final imagePath = analysisData['imagePath'];
        final permanentPath = await _saveToDocuments(File(imagePath));

        // 4. MemoCard 생성
        final card = MemoCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          summary: summary,
          category: category,
          tags: tags,
          captureDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
          imageUrl: permanentPath,
          ocrText: analysisData['ocrText'] ?? '',
          sourceUrl: '',
          folderId: _selectedFolder?.id,
        );
        
        // 5. DB 저장
        await DatabaseHelper.instance.create(card);
        
        // 6. UI 업데이트
        setState(() {
          _cards.insert(0, card);
        });
        
        // 성공 메시지
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✨ 메모가 생성되었습니다: ${card.title}'),
                backgroundColor: AppTheme.accentTeal,
              ),
            );
        }
        
      } catch (e) {
        print('Import failed: $e');
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('분석 실패: $e')),
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
              suggestedCategory: suggestedCategory
          );
      }

      // 2. Finalize Metadata
      // Use suggested title if analysis title is generic or empty, but prefer analysis if structured
      String title = analysis.title;
      if ((title == "New Memory" || title.isEmpty) && suggestedTitle != null && suggestedTitle.isNotEmpty) {
           title = suggestedTitle;
      }
      
      // Force Shopping category if determined by parser
      String category = suggestedCategory;
      if (analysis.title == "Shopping Item" || (analysis.keyInsights.any((k) => k.contains("가격")))) {
           category = "Shopping";
      }

      // 3. Create Card Object
      final newCard = MemoCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.length > 50 ? "${title.substring(0, 47)}..." : title,
        summary: analysis.summary,
        category: category,
        tags: suggestedTags, // Can merge with analysis.keyInsights if desired
        captureDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        imageUrl: imagePath,
        ocrText: ocrText,
        sourceUrl: sourceUrl,
        keyInsights: analysis.keyInsights
      );

      // 4. Save to DB
      await DatabaseHelper.instance.create(newCard);

      // 5. Refresh UI
      if (mounted) {
          setState(() {
            _cards.insert(0, newCard);
          });
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Memo created from screenshot!'),
               backgroundColor: AppTheme.accentTeal,
               duration: Duration(seconds: 2),
             ),
          );
      }
      
    } catch (e) {
      print("Error creating card: $e");
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
  }) async {
    if (ocrText.trim().isEmpty) {
      return ScreenshotAnalysis(
        title: "빈 스크린샷",
        summary: "텍스트가 감지되지 않았습니다.",
        keyInsights: [],
      );
    }

    // 🆕 Bounding Box가 있으면 직접 사용, 없으면 줄 단위로 생성
    List<OCRBlock> blocks;
    if (ocrBlocks != null && ocrBlocks.isNotEmpty) {
      blocks = ocrBlocks;
      print('   ✅ Bounding Box 정보 사용: ${blocks.length}개 블록');
    } else {
      // Fallback: 줄 단위로 OCR 블록 생성 (Bounding Box 없음)
      final lines = ocrText.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && line.length > 2)
          .toList();

      if (lines.isEmpty) {
        return ScreenshotAnalysis(
          title: "New Memory",
          summary: "스크린샷이 저장되었습니다.",
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
      print('   ⚠️ Bounding Box 없음, 줄 기반 추정 사용: ${blocks.length}개 블록');
    }

    // 🚀 OnDeviceLLMService 사용 (iOS Native NLP 활용)
    try {
      print('🔍 OnDeviceLLMService 시작 (Native NLP)...');
      
      // Native AI Analysis
      final analysis = await OnDeviceLLMService.analyzeScreenshotLegacy(
          ocrText: ocrText,
          ocrBlocks: blocks ?? []
      );
      
      print('✅ 분석 완료: Title="${analysis.title}"');
      return analysis;

    } catch (e) {
      print('❌ Native LLM 분석 실패 (Fallback to Basic Parser): $e');
      
      // Fallback: DocumentParserService
      try {
         return DocumentParserService.parseDocument(
            blocks ?? [], 
            externalCategory: suggestedCategory
         );
      } catch (e2) {
         return ScreenshotAnalysis(
            title: "Screen Capture",
            summary: ocrText.length > 100 ? "${ocrText.substring(0, 100)}..." : ocrText,
            keyInsights: [],
         );
      }
    }
  }

  Future<void> _pickImage() async {
    print('🟠 _pickImage started');
    try {
      print('🟠 Opening image picker (${Platform.isMacOS ? "gallery" : "camera"})...');
      final XFile? image = await _picker.pickImage(
        source: Platform.isMacOS ? ImageSource.gallery : ImageSource.camera,
      );
      print('🟠 Image picker returned: ${image?.path ?? "null"}');
      
      if (image == null) {
        print('🟠 No image selected');
        return;
      }

    setState(() => _isAnalyzing = true);

    final permanentPath = await _saveToDocuments(File(image.path));

    if (Platform.isIOS) {
        // iOS: Native Vision Framework Analysis
        print('🟠 Running native analysis on iOS...');
        final result = await NativeService.analyzeImageWithBoxes(permanentPath);
        
        if (result != null) {
             final ocrText = result['ocrText'] as String? ?? '';
             final suggestedTags = List<String>.from(result['suggestedTags'] ?? ['Photo']);
             final suggestedCategory = result['suggestedCategory'] as String? ?? 'Inbox';
             final suggestedTitle = result['suggestedTitle'] as String? ?? "New Capture";
             
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

             // On-device analysis using extracted text and blocks
             final analysis = await _analyzeScreenshotOnDevice(
                ocrText, 
                ocrBlocks: ocrBlocks
             );
             
             // Create card with analyzed data
             await _createCardFromAnalysis(
                permanentPath, 
                ocrText, 
                analysis.keyInsights.isNotEmpty ? suggestedTags : suggestedTags, // Can refine tags
                suggestedCategory,
                suggestedTitle: analysis.title,
             );
        } else {
             // Fallback if native analysis fails
             print('🔴 Native analysis returned null');
             await _createCardFromAnalysis(
                permanentPath, 
                "", 
                ['Photo'], 
                'Inbox',
                suggestedTitle: 'New Photo'
             );
        }

      } else {
        // macOS / Other: Fallback
        String ocrText = _generateMacOSFallback(permanentPath);
        final suggestedTags = ['Camera', 'Photo'];
        final suggestedCategory = 'Inbox';

        await _createCardFromAnalysis(permanentPath, ocrText, suggestedTags, suggestedCategory);
      }
    } catch (e) {
      print('🔴 Error in _pickImage: $e');
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
              Expanded(child: _buildContent()),
            ],
          ),

          // Loading Overlay
          if (_isAnalyzing) _buildLoadingOverlay(),

          // FAB - Fixed position (Right-bottom corner, above bottom nav)
          Positioned(
            bottom: 110, 
            right: 24,
            child: _buildFAB(),
          ),

          // Custom Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavBar(),
          ),
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
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
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

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark 
        ? const Color(0xFF0A0A0A).withOpacity(0.9) 
        : const Color(0xFFFFFFFF).withOpacity(0.9);
    
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
           top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.grid_view, "Library", true),
          _buildNavItem(Icons.auto_awesome, "Insights", false),
          _buildNavItem(Icons.history, "Timeline", false),
          _buildNavItem(Icons.person_outline, "Profile", false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    final color = isActive 
        ? Theme.of(context).primaryColor 
        : Theme.of(context).disabledColor;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color, 
            fontSize: 10, 
            fontWeight: FontWeight.w600
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      color: Theme.of(context).appBarTheme.backgroundColor, 
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: "Search memories...",
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

  Widget _buildContent() {
    final displayCards = _searchQuery.isEmpty ? _cards : _filteredCards;

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
      padding: const EdgeInsets.only(bottom: 80), 
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
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"$_searchQuery"에 대한 결과를 찾을 수 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
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
    await DatabaseHelper.instance.update(updatedCard);
    
    if (mounted) {
       setState(() {
         final index = _cards.indexWhere((c) => c.id == card.id);
         if (index != -1) _cards[index] = updatedCard;
       });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: const Text('Title updated'), backgroundColor: Theme.of(context).cardColor)
       );
    }
  }

  Future<void> _deleteCard(MemoCard card) async {
    await DatabaseHelper.instance.delete(card.id);
    if (!card.imageUrl.startsWith('http')) {
      try {
        final file = File(card.imageUrl);
        if (await file.exists()) await file.delete();
      } catch (e) { print(e); }
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
            await DatabaseHelper.instance.update(updatedCard);
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
