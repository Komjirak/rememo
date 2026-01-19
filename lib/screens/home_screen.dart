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
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  List<MemoCard> _cards = [];
  List<Folder> _folders = [];
  Folder? _selectedFolder;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshCards();
    _loadFolders();
    _startScreenshotMonitoring(); // 스크린샷 자동 모니터링 시작
  }

  @override
  void dispose() {
    _searchController.dispose();
    _stopScreenshotMonitoring(); // 스크린샷 모니터링 중지
    super.dispose();
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

    // UI 업데이트: 분석 중 표시
    if (mounted) {
      setState(() => _isAnalyzing = true);
    }

    try {
      final imagePath = data['imagePath'] as String;
      final ocrText = data['ocrText'] as String? ?? '';
      final suggestedTags = List<String>.from(data['suggestedTags'] ?? []);
      final suggestedCategory = data['suggestedCategory'] as String? ?? 'Inbox';

      // 이미지를 앱의 영구 저장소에 복사
      final permanentPath = await _saveToDocuments(File(imagePath));

      // OCR 텍스트가 비어있으면 플레이스홀더 사용
      String finalOcrText = ocrText;
      if (finalOcrText.isEmpty) {
        final fileName = imagePath.split('/').last;
        final now = DateTime.now();
        finalOcrText = "Screenshot captured on ${now.month}/${now.day}/${now.year} at ${now.hour}:${now.minute}. Filename: $fileName. Add personal notes for insights.";
      }

      // URL 추출
      final urlRegExp = RegExp(r"(https?:\/\/[^\s]+[\w\/])|(www\.[^\s]+[\w\/])|([a-zA-Z0-9-]+\.com\/[^\s]*)");
      final String? foundUrl = urlRegExp.firstMatch(finalOcrText)?.group(0);

      // 스마트 제목 및 요약 생성
      final summary = _generateSmartSummary(finalOcrText);
      final title = _generateSmartTitle(finalOcrText, suggestedTags);

      // 새 카드 생성
      final newCard = MemoCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.length > 40 ? "${title.substring(0, 40)}..." : title,
        summary: summary,
        category: suggestedCategory,
        tags: suggestedTags.isEmpty ? ['Screenshot', 'Auto-Detected'] : suggestedTags,
        captureDate: "Just now",
        imageUrl: permanentPath,
        ocrText: finalOcrText,
        sourceUrl: foundUrl,
        personalNote: null,
        folderId: _selectedFolder?.id, // 현재 선택된 폴더에 저장
      );

      // 데이터베이스에 저장
      await DatabaseHelper.instance.create(newCard);

      // UI 새로고침
      await _refreshCards();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing screenshot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
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
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.borderColor),
            left: BorderSide(color: AppTheme.borderColor),
            right: BorderSide(color: AppTheme.borderColor),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textDisabled,
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
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.accentTeal, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importLastScreenshot() async {
    print('🔴 _importLastScreenshot started');
    // macOS에서는 permission_handler가 작동하지 않으므로, 플랫폼 체크
    if (Platform.isIOS) {
      final status = await Permission.photos.request();

      if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enable Photo permissions in Settings")),
          );
          openAppSettings();
        }
        return;
      }

      if (!status.isGranted && !status.isLimited) return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // iOS에서는 네이티브 서비스 사용
      if (Platform.isIOS) {
        final result = await NativeService.getLastScreenshotAnalysis();

        if (result == null) {
          setState(() => _isAnalyzing = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No screenshot found or analysis failed")),
            );
          }
          return;
        }

        final tempPath = result['imagePath'] as String;
        final permanentPath = await _saveToDocuments(File(tempPath));

        final ocrText = result['ocrText'] as String;
        final suggestedTags = List<String>.from(result['suggestedTags'] ?? []);
        final suggestedCategory = result['suggestedCategory'] as String? ?? "Inbox";

        await _createCardFromAnalysis(permanentPath, ocrText, suggestedTags, suggestedCategory);
      } else {
        // macOS/기타 플랫폼에서는 파일 선택기 사용
        await _pickImageFromGallery();
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
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
    
      // Google ML Kit으로 다국어 텍스트 인식
      String ocrText = await _performMultiLanguageOCR(permanentPath);
      
      print('🟣 OCR Result: $ocrText');
      
      // OCR 결과가 없으면 기본 텍스트 사용
      if (ocrText.isEmpty) {
        ocrText = 'Image imported from gallery';
      }

      // 텍스트로부터 태그와 카테고리 추출
      final suggestedTags = _extractTagsFromText(ocrText);
      final suggestedCategory = _detectCategory(ocrText);

      await _createCardFromAnalysis(permanentPath, ocrText, suggestedTags, suggestedCategory);
    } catch (e) {
      print('🔴 Error in _pickImageFromGallery: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  Future<String> _performMultiLanguageOCR(String imagePath) async {
    print('🔵 Starting multi-language OCR...');
    
    // macOS에서는 ML Kit이 지원되지 않으므로 더 나은 기본값 제공
    if (Platform.isMacOS) {
      print('ℹ️ macOS detected - Using enhanced default content');
      final fileName = imagePath.split('/').last;
      final now = DateTime.now();
      
      // 더 의미있는 기본 텍스트 생성
      final extractedInfo = 'Visual Memory Captured\n'
          'Import Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}\n'
          'Time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}\n'
          'Source: $fileName\n\n'
          'Tap to edit and add your own notes and insights about this image. '
          'You can describe what you see, add context, or save important details for future reference.\n\n'
          'Note: Advanced OCR text extraction is available on iOS and Android devices.';
      
      print('✅ Generated enhanced default content');
      return extractedInfo;
    }
    
    // iOS/Android 실제 기기에서는 ML Kit 사용
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final allTexts = <String>[];

      // 지원할 스크립트 목록
      final scripts = [
        TextRecognitionScript.latin,
        TextRecognitionScript.korean,
        TextRecognitionScript.chinese,
        TextRecognitionScript.japanese,
      ];

      // 각 스크립트로 OCR 시도
      for (final script in scripts) {
        try {
          print('🔵 Trying script: $script');
          final textRecognizer = TextRecognizer(script: script);
          final recognizedText = await textRecognizer.processImage(inputImage);
          await textRecognizer.close();

          if (recognizedText.text.isNotEmpty) {
            print('✅ Found text with $script: ${recognizedText.text.substring(0, recognizedText.text.length > 50 ? 50 : recognizedText.text.length)}...');
            allTexts.add(recognizedText.text);
          }
        } catch (e) {
          print('⚠️ Script $script failed: $e');
          continue;
        }
      }

      // 모든 텍스트 결합 (중복 제거)
      if (allTexts.isEmpty) {
        print('❌ No text found in any language');
        return 'No text detected in image.';
      }

      // 가장 긴 결과를 반환 (보통 가장 정확함)
      allTexts.sort((a, b) => b.length.compareTo(a.length));
      final result = allTexts.first;
      print('✅ Final OCR result length: ${result.length} characters');

      return result;
    } catch (e) {
      // ML Kit 실패 시 (시뮬레이터 등) fallback
      print('⚠️ ML Kit failed (possibly simulator): $e');
      final fileName = imagePath.split('/').last;
      final now = DateTime.now();
      
      return 'Visual Memory Captured\n'
          'Import Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}\n'
          'Time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}\n'
          'Source: $fileName\n\n'
          'Tap to edit and add your own notes.\n\n'
          'Note: OCR requires a real iOS device. Text extraction is not available on simulators.';
    }
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

  Future<void> _createCardFromAnalysis(
    String imagePath,
    String ocrText,
    List<String> suggestedTags,
    String suggestedCategory,
  ) async {
    try {
      final urlRegExp = RegExp(r"(https?:\/\/[^\s]+[\w\/])|(www\.[^\s]+[\w\/])|([a-zA-Z0-9-]+\.com\/[^\s]*)");
      final String? foundUrl = urlRegExp.firstMatch(ocrText)?.group(0);

      final summary = _generateSmartSummary(ocrText);
      final title = _generateSmartTitle(ocrText, suggestedTags);

      final newCard = MemoCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.length > 40 ? "${title.substring(0, 40)}..." : title,
        summary: summary,
        category: suggestedCategory,
        tags: suggestedTags,
        captureDate: "Just now",
        imageUrl: imagePath,
        ocrText: ocrText,
        sourceUrl: foundUrl,
        personalNote: null,
      );

      await DatabaseHelper.instance.create(newCard);
      await _refreshCards();
      
      setState(() => _isAnalyzing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Memory card created successfully!"),
            backgroundColor: AppTheme.accentTeal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating card: ${e.toString()}")),
        );
      }
    }
  }

  String _generateSmartTitle(String text, List<String> tags) {
    final cleanTags = tags.where((t) =>
        !RegExp(r'^\d+$').hasMatch(t) && t.length > 2 && !t.contains('http')
    ).toList();

    if (cleanTags.isNotEmpty) {
      if (cleanTags.length >= 2) {
        return "${cleanTags[0]} & ${cleanTags[1]}";
      }
      return cleanTags.first;
    }

    final lines = text.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(line)) continue;
      if (line.contains('http') || line.contains('www.')) continue;
      if (['Search', 'Back', 'Edit', 'Done', 'Cancel'].contains(line)) continue;
      if (line.length > 50) continue;
      return line;
    }
    return "New Capture";
  }

  String _generateSmartSummary(String text) {
    if (text.isEmpty) return "No text content found.";

    // macOS에서의 기본 텍스트인지 확인
    if (text.contains('Visual Memory Captured') && Platform.isMacOS) {
      return "Image imported successfully. Open the detail view to add your personal notes and insights about this visual memory.";
    }

    final lines = text.split('\n');
    final cleanLines = <String>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(line)) continue;
      if (line.contains('%') && line.length < 5) continue;
      if (line.length < 3) continue;
      if (['Search', 'Edit', 'Back', 'Share', 'Done', 'Cancel'].contains(line)) continue;
      cleanLines.add(line);
    }

    if (cleanLines.isEmpty) return "Captured visual content.";

    cleanLines.sort((a, b) {
      int scoreA = a.length + (a.contains('http') ? 20 : 0);
      int scoreB = b.length + (b.contains('http') ? 20 : 0);
      return scoreB.compareTo(scoreA);
    });

    final summaryLines = cleanLines.take(4).toList();
    return summaryLines.map((l) => "• $l").join("\n\n");
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

      // 다국어 OCR 수행
      String ocrText = await _performMultiLanguageOCR(permanentPath);
      
      print('🟠 OCR Result: $ocrText');
      
      // OCR 결과가 없으면 기본 텍스트 사용
      if (ocrText.isEmpty) {
        ocrText = 'Photo captured from camera/gallery';
      }

      // 텍스트로부터 태그와 카테고리 추출
      final suggestedTags = _extractTagsFromText(ocrText);
      final suggestedCategory = _detectCategory(ocrText);

      await _createCardFromAnalysis(permanentPath, ocrText, suggestedTags, suggestedCategory);
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
      backgroundColor: AppTheme.backgroundDark,
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

          // FAB - Always visible
          Positioned(
            bottom: 32,
            right: 24,
            child: _buildFAB(),
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
        color: AppTheme.backgroundDark.withAlpha(204),
        border: const Border(
          bottom: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: AppTheme.accentTeal,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                "Folio",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Right actions
          Row(
            children: [
              // Folder button
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FolderManagementView(
                        onFolderSelected: _selectFolder,
                      ),
                    ),
                  );
                  _loadFolders();
                },
                child: Icon(
                  Icons.folder_outlined,
                  color: _selectedFolder != null ? AppTheme.accentTeal : AppTheme.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Search button
              GestureDetector(
                onTap: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                }),
                child: Icon(
                  _showSearch ? Icons.close : Icons.search,
                  color: _showSearch ? AppTheme.accentTeal : AppTheme.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      color: AppTheme.backgroundDark,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: "Search memories...",
          hintStyle: const TextStyle(color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
          filled: true,
          fillColor: AppTheme.cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.accentTeal),
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
      color: AppTheme.backgroundDark,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _hexToColor(_selectedFolder!.color).withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hexToColor(_selectedFolder!.color).withAlpha(51),
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
      // 검색 중인데 결과가 없는 경우
      if (_searchQuery.isNotEmpty) {
        return _buildNoSearchResultsView();
      }
      // 카드가 없는 경우 (온보딩)
      return EmptyStateView(
        onAddFirst: _handleCapture,
        onLearnMore: () {},
      );
    }

    return LibraryListView(
      cards: displayCards,
      folders: _folders,
      onSelect: _navigateToDetail,
      onDelete: _deleteCard,
      onTitleEdit: _updateCardTitle,
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
                color: Colors.white.withAlpha(13),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_outlined,
                size: 48,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"$_searchQuery"에 대한 결과를 찾을 수 없습니다.\n다른 키워드로 검색해보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('검색어 지우기'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentTeal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.accentTeal.withAlpha(77)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppTheme.backgroundDark.withAlpha(230),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentTeal,
                  strokeWidth: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Analyzing...",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
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
          color: AppTheme.accentTeal,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentTeal.withAlpha(51),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: AppTheme.backgroundDark,
          size: 28,
        ),
      ),
    );
  }

  Future<void> _updateCardTitle(MemoCard card, String newTitle) async {
    print('✏️ Updating card title: ${card.id} -> $newTitle');

    // 새 제목으로 카드 업데이트
    final updatedCard = card.copyWith(title: newTitle);

    // 데이터베이스에 저장
    await DatabaseHelper.instance.update(updatedCard);

    // UI 갱신
    setState(() {
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        _cards[index] = updatedCard;
      }
    });

    print('✅ Card title updated successfully');

    // 피드백 스낵바 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('제목이 수정되었습니다'),
          backgroundColor: AppTheme.cardDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteCard(MemoCard card) async {
    print('🗑️ Deleting card: ${card.id}');
    
    // 데이터베이스에서 삭제
    await DatabaseHelper.instance.delete(card.id);
    
    // 로컬 이미지 파일 삭제 (URL이 로컬 경로인 경우)
    if (!card.imageUrl.startsWith('http')) {
      try {
        final file = File(card.imageUrl);
        if (await file.exists()) {
          await file.delete();
          print('✅ Image file deleted: ${card.imageUrl}');
        }
      } catch (e) {
        print('⚠️ Failed to delete image file: $e');
      }
    }
    
    // UI 업데이트
    setState(() {
      _cards.removeWhere((c) => c.id == card.id);
    });
    
    print('✅ Card deleted successfully');
  }

  void _navigateToDetail(MemoCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailViewScreen(
          card: card,
          onDelete: () async {
            await _deleteCard(card);
          },
          onUpdate: (updatedCard) async {
            await DatabaseHelper.instance.update(updatedCard);
            setState(() {
              final index = _cards.indexWhere((c) => c.id == updatedCard.id);
              if (index != -1) {
                _cards[index] = updatedCard;
              }
            });
          },
          onOpenLink: (url) async {
            final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not launch URL')),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
