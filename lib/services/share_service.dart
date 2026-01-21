import 'dart:async';
import 'package:flutter/services.dart';

/// Model for shared content received from Share Extension
class SharedItem {
  final String type; // 'url', 'image', 'text', 'webpage'
  final String? url;
  final String? imagePath;
  final String? text;
  final String? title;
  final String? selectedText;
  final double timestamp;
  final String status; // 'pending', 'processing', 'ready', 'error'

  // AI-analyzed data (populated after processing)
  String? ocrText;
  String? summary;
  List<String>? tags;
  String? category;
  String? suggestedTitle;

  SharedItem({
    required this.type,
    this.url,
    this.imagePath,
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
    return SharedItem(
      type: map['type'] as String? ?? 'unknown',
      url: map['url'] as String?,
      imagePath: map['imagePath'] as String?,
      text: map['text'] as String?,
      title: map['title'] as String?,
      selectedText: map['selectedText'] as String?,
      timestamp: (map['timestamp'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      ocrText: map['ocrText'] as String?,
      summary: map['summary'] as String?,
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
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// Check if this item has a URL
  bool get hasUrl => url != null && url!.isNotEmpty;

  SharedItem copyWith({
    String? status,
    String? ocrText,
    String? summary,
    List<String>? tags,
    String? category,
    String? suggestedTitle,
  }) {
    return SharedItem(
      type: type,
      url: url,
      imagePath: imagePath,
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

  URLMetadata({
    required this.url,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  factory URLMetadata.fromMap(Map<String, dynamic> map) {
    return URLMetadata(
      url: map['url'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
    );
  }
}

/// Service for handling Share Extension data
class ShareService {
  static const _channel = MethodChannel('com.rememo.komjirak/share');

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
        // Fetch URL metadata
        if (item.url != null) {
          final metadata = await fetchURLMetadata(item.url!);
          if (metadata != null) {
            processedItem = processedItem.copyWith(
              status: 'ready',
              suggestedTitle: metadata.title,
              summary: metadata.description,
              category: 'Web',
              tags: _extractTagsFromText(metadata.title + ' ' + metadata.description),
            );
          }
        }
      } else if (item.type == 'text') {
        // Process text content
        final text = item.text ?? item.selectedText ?? '';
        final extractedUrl = _extractURL(text);

        if (extractedUrl != null) {
          // If text contains URL, fetch its metadata
          final metadata = await fetchURLMetadata(extractedUrl);
          processedItem = SharedItem(
            type: 'text',
            url: extractedUrl,
            imagePath: item.imagePath,
            text: text,
            title: metadata?.title ?? item.title,
            selectedText: item.selectedText,
            timestamp: item.timestamp,
            status: 'ready',
            ocrText: item.ocrText,
            summary: metadata?.description,
            tags: _extractTagsFromText(text),
            category: 'Web',
            suggestedTitle: metadata?.title ?? _generateTitleFromText(text),
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
