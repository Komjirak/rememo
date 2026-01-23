import 'dart:async';
import 'package:flutter/services.dart';

/// Model for shared content received from Share Extension
class SharedItem {
  final String type; // 'url', 'image', 'text', 'webpage'
  final String? url;
  final String? imagePath;
  final String? imageUrl; // Remote URL for OG image
  final String? text;
  final String? title;
  final String? selectedText;
  final double timestamp;
  final String status; // 'pending', 'processing', 'ready', 'error'

  // AI-analyzed data (populated after processing)
  final String? ocrText;
  final String? summary;
  final List<String>? tags;
  final String? category;
  final String? suggestedTitle;

  SharedItem({
    required this.type,
    this.url,
    this.imagePath,
    this.imageUrl, // Added
    this.text,
    this.title,
    this.selectedText,
    required this.timestamp,
    this.status = 'pending',
    this.ocrText,
    this.summary,
    this.tags,
    this.category,
    this.suggestedTitle,
  });

  factory SharedItem.fromMap(Map<String, dynamic> map) {
    // ShareViewController에서 전달한 description 필드를 summary로 매핑
    final description = map['description'] as String?;
    final summary = map['summary'] as String? ?? description;

    return SharedItem(
      type: map['type'] as String? ?? 'unknown',
      url: map['url'] as String?,
      imagePath: map['imagePath'] as String?,
      imageUrl: map['imageUrl'] as String?, // Added
      text: map['text'] as String?,
      title: map['title'] as String?,
      selectedText: map['selectedText'] as String?,
      timestamp: (map['timestamp'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      ocrText: map['ocrText'] as String?,
      summary: summary,
      tags: (map['tags'] as List?)?.cast<String>(),
      category: map['category'] as String?,
      suggestedTitle: map['suggestedTitle'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'url': url,
      'imagePath': imagePath,
      'imageUrl': imageUrl, // Added
      'text': text,
      'title': title,
      'selectedText': selectedText,
      'timestamp': timestamp,
      'status': status,
      'ocrText': ocrText,
      'summary': summary,
      'tags': tags,
      'category': category,
      'suggestedTitle': suggestedTitle,
    };
  }

  /// Get display title for this shared item
  String get displayTitle {
    if (suggestedTitle != null && suggestedTitle!.isNotEmpty) {
      return suggestedTitle!;
    }
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    if (type == 'url' && url != null) {
      return Uri.tryParse(url!)?.host ?? 'Web Link';
    }
    if (type == 'text' && text != null) {
      return text!.length > 30 ? '${text!.substring(0, 30)}...' : text!;
    }
    return 'New Item';
  }

  /// Get source URL for "Return to Original" feature
  String? get sourceUrl => url;

  /// Check if this item has an image
  bool get hasImage => (imagePath != null && imagePath!.isNotEmpty) || (imageUrl != null && imageUrl!.isNotEmpty);

  /// Check if this item has a URL
  bool get hasUrl => url != null && url!.isNotEmpty;

  SharedItem copyWith({
    String? status,
    String? ocrText,
    String? summary,
    String? imageUrl,
    List<String>? tags,
    String? category,
    String? suggestedTitle,
  }) {
    return SharedItem(
      type: type,
      url: url,
      imagePath: imagePath,
      imageUrl: imageUrl ?? this.imageUrl, // Added
      text: text,
      title: title,
      selectedText: selectedText,
      timestamp: timestamp,
      status: status ?? this.status,
      ocrText: ocrText ?? this.ocrText,
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      suggestedTitle: suggestedTitle ?? this.suggestedTitle,
    );
  }
}

/// URL Metadata fetched from web pages
class URLMetadata {
  final String url;
  final String title;
  final String description;
  final String? imageUrl;
  final String? text; // Added extracted text

  URLMetadata({
    required this.url,
    required this.title,
    required this.description,
    this.imageUrl,
    this.text,
  });

  factory URLMetadata.fromMap(Map<String, dynamic> map) {
    return URLMetadata(
      url: map['url'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      text: map['text'] as String?,
    );
  }
}

/// Service for handling Share Extension data
class ShareService {
  static const _channel = MethodChannel('com.rememo.komjirak/share');
  static const _llmChannel = MethodChannel('com.rememo.komjirak/llm'); // Added

  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  // Callback for when new shared content arrives
  Function(List<SharedItem>)? onSharedItemsReceived;

  /// Get pending shared items from App Group storage
  Future<List<SharedItem>> getPendingSharedItems() async {
    try {
      final result = await _channel.invokeMethod('getPendingSharedItems');
      if (result == null) return [];

      final List<dynamic> items = result as List<dynamic>;
      return items
          .map((item) => SharedItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } on PlatformException catch (e) {
      print("Failed to get pending shared items: '${e.message}'");
      return [];
    }
  }

  /// Clear all pending shared items
  Future<bool> clearPendingSharedItems() async {
    try {
      await _channel.invokeMethod('clearPendingSharedItems');
      return true;
    } on PlatformException catch (e) {
      print("Failed to clear pending shared items: '${e.message}'");
      return false;
    }
  }

  /// Remove a specific pending shared item
  Future<bool> removePendingSharedItem(double timestamp) async {
    try {
      await _channel.invokeMethod('removePendingSharedItem', {
        'timestamp': timestamp,
      });
      return true;
    } on PlatformException catch (e) {
      print("Failed to remove pending shared item: '${e.message}'");
      return false;
    }
  }

  /// Analyze a shared image using on-device OCR
  Future<Map<String, dynamic>?> analyzeSharedImage(String path) async {
    try {
      final result = await _channel.invokeMethod('analyzeSharedImage', {
        'path': path,
      });
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException catch (e) {
      print("Failed to analyze shared image: '${e.message}'");
      return null;
    }
  }

  /// Fetch metadata from a URL (title, description, image)
  Future<URLMetadata?> fetchURLMetadata(String url) async {
    try {
      final result = await _channel.invokeMethod('fetchURLMetadata', {
        'url': url,
      });
      if (result != null) {
        return URLMetadata.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (e) {
      print("Failed to fetch URL metadata: '${e.message}'");
      return null;
    }
  }

  /// Generate AI Summary using On-Device LLM
  Future<Map<String, dynamic>?> _generateAISummary(String title, String content) async {
    try {
        // Split content into paragraphs for the LLM API
        final paragraphs = content.split(RegExp(r'\n+'))
            .map((p) => p.trim())
            .where((p) => p.length > 20)
            .toList();
            
        if (paragraphs.isEmpty) return null;

        // Create synthetic blocks from paragraphs
        final textBlocks = paragraphs.map((p) => {
            'text': p,
            'top': 0.5, // Dummy values
            'left': 0.1,
            'width': 0.8,
            'height': 0.1,
            'confidence': 1.0,
        }).toList();

        final result = await _llmChannel.invokeMethod('analyzeSummary', {
            'textBlocks': textBlocks,
            'imageSize': {'width': 1000.0, 'height': 2000.0}, // Dummy size
             // Optional args
            'layoutRegions': [],
            'importantAreas': [],
        });
        
        if (result != null) {
            return Map<String, dynamic>.from(result);
        }
        return null;
    } catch (e) {
        print("Failed to generate AI summary: $e");
        return null;
    }
  }

  /// Process a shared item with AI analysis
  /// Returns the processed SharedItem with OCR text, tags, category etc.
  Future<SharedItem> processSharedItem(SharedItem item) async {
    SharedItem processedItem = item.copyWith(status: 'processing');

    try {
      if (item.type == 'image' && item.imagePath != null) {
        // Process image with OCR
        final analysis = await analyzeSharedImage(item.imagePath!);
        if (analysis != null) {
          processedItem = processedItem.copyWith(
            status: 'ready',
            ocrText: analysis['ocrText'] as String?,
            tags: (analysis['suggestedTags'] as List?)?.cast<String>(),
            category: analysis['suggestedCategory'] as String?,
            suggestedTitle: analysis['suggestedTitle'] as String?,
          );

          // Extract URL from OCR text if available
          if (processedItem.ocrText != null && !processedItem.hasUrl) {
            final extractedUrl = _extractURL(processedItem.ocrText!);
            if (extractedUrl != null) {
              // Update with extracted URL
              processedItem = SharedItem(
                type: processedItem.type,
                url: extractedUrl,
                imagePath: processedItem.imagePath,
                text: processedItem.text,
                title: processedItem.title,
                selectedText: processedItem.selectedText,
                timestamp: processedItem.timestamp,
                status: processedItem.status,
                ocrText: processedItem.ocrText,
                summary: processedItem.summary,
                tags: processedItem.tags,
                category: processedItem.category,
                suggestedTitle: processedItem.suggestedTitle,
              );
            }
          }
        }
      } else if (item.type == 'url' || item.type == 'webpage') {
        // Share Extension에서 이미 메타데이터를 가져왔는지 확인
        final hasValidTitle = item.title != null &&
            item.title!.isNotEmpty &&
            !_isSecurityPageTitle(item.title!);
        
        String currentTitle = item.title ?? '';
        String currentSummary = item.summary ?? '';
        String? currentImageUrl = item.imageUrl;
        String currentText = item.text ?? '';

        if (!hasValidTitle && item.url != null) {
           // Retry fetching
           final metadata = await fetchURLMetadata(item.url!);
           if (metadata != null) {
               if (!_isSecurityPageTitle(metadata.title)) {
                   currentTitle = metadata.title;
                   currentSummary = metadata.description;
                   currentImageUrl = metadata.imageUrl;
                   if (metadata.text != null && metadata.text!.isNotEmpty) {
                       currentText = metadata.text!;
                   }
               } else {
                   currentTitle = _prettifyHost(item.url!);
               }
           }
        } else if (item.url != null && (currentSummary.isEmpty || currentImageUrl == null)) {
           // 🔹 Title exists but Summary/Image missing? Fetch metadata anyway to enrich!
           print('Title exists ($currentTitle) but missing details. Fetching metadata for ${item.url}...');
           final metadata = await fetchURLMetadata(item.url!);
           if (metadata != null) {
               // Use longer/better content if available
               if (metadata.description.isNotEmpty) currentSummary = metadata.description;
               if (metadata.imageUrl != null && metadata.imageUrl!.isNotEmpty) currentImageUrl = metadata.imageUrl;
               if (metadata.text != null && metadata.text!.isNotEmpty) currentText = metadata.text!;
               
               // Optionally update title if new one is better (not generic) and old one was short
               if (!_isSecurityPageTitle(metadata.title) && metadata.title.length > currentTitle.length) {
                   currentTitle = metadata.title;
               }
           }
        }
        
        // AI Summarization if text is available
        if (currentText.isNotEmpty) {
            final aiResult = await _generateAISummary(currentTitle, currentText);
            if (aiResult != null) {
                if (aiResult['summary'] != null) currentSummary = aiResult['summary'];
                // Could also use aiResult['keyInsights'] for tags or separate field
            }
        }

        processedItem = processedItem.copyWith(
            status: 'ready',
            suggestedTitle: currentTitle.isNotEmpty ? currentTitle : _prettifyHost(item.url ?? ''),
            summary: currentSummary,
            imageUrl: currentImageUrl,
            category: 'Web',
            tags: _extractTagsFromText(currentTitle + ' ' + currentSummary),
            ocrText: currentText, // 🔹 Save web content to ocrText property so it persists in DB
        );
        
      } else if (item.type == 'text') {
        // Process text content
        final text = item.text ?? item.selectedText ?? '';
        final extractedUrl = _extractURL(text);

        if (extractedUrl != null) {
          // If text contains URL, fetch its metadata
          final metadata = await fetchURLMetadata(extractedUrl);
          final hasValidMetadata = metadata != null && !_isSecurityPageTitle(metadata.title);
          
          String summary = hasValidMetadata ? metadata.description : '';
          String title = hasValidMetadata ? metadata.title : _prettifyHost(extractedUrl);
          
          // Try AI Summary for URL content if available from metadata
          if (metadata?.text != null && metadata!.text!.isNotEmpty) {
               final aiResult = await _generateAISummary(title, metadata.text!);
               if (aiResult != null && aiResult['summary'] != null) {
                   summary = aiResult['summary'];
               }
          }

          processedItem = SharedItem(
            type: 'text',
            url: extractedUrl,
            imagePath: item.imagePath,
            imageUrl: metadata?.imageUrl, // Use fetched image URL
            text: text,
            title: title,
            selectedText: item.selectedText,
            timestamp: item.timestamp,
            status: 'ready',
            ocrText: item.ocrText,
            summary: summary.isNotEmpty ? summary : null,
            tags: _extractTagsFromText(text),
            category: 'Web',
            suggestedTitle: title,
          );
        } else {
          processedItem = processedItem.copyWith(
            status: 'ready',
            tags: _extractTagsFromText(text),
            category: _detectCategory(text),
            suggestedTitle: _generateTitleFromText(text),
          );
        }
      }

      return processedItem;
    } catch (e) {
      print("Error processing shared item: $e");
      return item.copyWith(status: 'error');
    }
  }

  /// 보안 페이지 제목인지 확인
  bool _isSecurityPageTitle(String title) {
    final lower = title.toLowerCase();
    return lower.contains('security checkpoint') ||
           lower.contains('checking your browser') ||
           lower.contains('just a moment') ||
           lower.contains('verify') && lower.contains('human') ||
           lower.contains('captcha') ||
           lower.contains('cloudflare');
  }

  /// URL 호스트를 보기 좋은 제목으로 변환
  String _prettifyHost(String urlString) {
    try {
      final uri = Uri.parse(urlString);
      var host = uri.host;
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      final dotIndex = host.indexOf('.');
      if (dotIndex > 0) {
        host = host.substring(0, dotIndex);
      }
      // 첫 글자 대문자
      if (host.isNotEmpty) {
        return host[0].toUpperCase() + host.substring(1);
      }
      return 'Web Link';
    } catch (e) {
      return 'Web Link';
    }
  }

  /// Extract URL from text
  String? _extractURL(String text) {
    final urlRegex = RegExp(
      r'https?://[^\s<>"{}|\\^`\[\]]+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  /// Extract tags from text (simple keyword extraction)
  List<String> _extractTagsFromText(String text) {
    final words = text
        .split(RegExp(r'[\s,.!?;:]+'))
        .where((w) => w.length > 2 && w.length < 20)
        .where((w) => !_stopWords.contains(w.toLowerCase()))
        .take(5)
        .toList();
    return words;
  }

  /// Generate title from text
  String _generateTitleFromText(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return 'New Note';

    final firstLine = lines.first.trim();
    if (firstLine.length <= 30) return firstLine;
    return '${firstLine.substring(0, 27)}...';
  }

  /// Detect category from text
  String _detectCategory(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('원') || lower.contains('결제') || lower.contains('price') || lower.contains('payment')) {
      return 'Shopping';
    }
    if (lower.contains('레시피') || lower.contains('요리') || lower.contains('recipe') || lower.contains('cook')) {
      return 'Food';
    }
    if (lower.contains('http') || lower.contains('.com') || lower.contains('www')) {
      return 'Web';
    }
    if (lower.contains('회의') || lower.contains('미팅') || lower.contains('meeting') || lower.contains('work')) {
      return 'Work';
    }
    if (lower.contains('design') || lower.contains('디자인') || lower.contains('ui')) {
      return 'Design';
    }

    return 'Inbox';
  }

  static const _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been',
    'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
    'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'need',
    'this', 'that', 'these', 'those', 'it', 'its', 'you', 'your', 'we',
    'our', 'they', 'their', 'he', 'his', 'she', 'her', 'i', 'my', 'me',
    '이', '그', '저', '것', '수', '등', '및', '또는', '그리고', '하지만',
  };
}
