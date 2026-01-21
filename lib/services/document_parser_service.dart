import 'dart:math';
import 'package:stribe/services/ondevice_llm_service.dart'; // Using OCRBlock and ScreenshotAnalysis

enum DocumentDomain {
  webArticle,
  sns, // Tweet, Instagram, Threads
  messenger, // Message bubbles
  shopping, // Product, Price
  mapReservation, // Place, Time
  workTool, // Slack, Jira
  finance, // Receipt, Bank
  generic
}

class DocumentParserService {
  
  /// Main Entry Point: Parse OCR blocks into a structured analysis
  /// purely using layout heuristics and rule-based extraction.
  static ScreenshotAnalysis parseDocument(List<OCRBlock> rawBlocks) {
    // 1. Basic Cleaning & Sort
    // Use the existing noise filter but add sorting
    final noiseFreeBlocks = OnDeviceLLMService.filterUINoiseBlocksPublic(rawBlocks);
    
    if (noiseFreeBlocks.isEmpty) {
      return ScreenshotAnalysis(
        title: "Empty Capture",
        summary: "No readable text found.",
        keyInsights: [],
      );
    }

    // 2. Advanced Layout Analysis (Y-Clustering)
    // Merge broken blocks into visual lines
    final visualLines = _clusterVisualLines(noiseFreeBlocks);
    
    // 3. Domain Classification
    final domain = _identifyDomain(visualLines);
    print('📊 Detected Domain: $domain');

    // 4. Domain-Specific Extraction
    return _extractContentByDomain(domain, visualLines, noiseFreeBlocks);
  }

  // ===========================================================================
  // A. Layout Analysis (Y-Clustering for Visual Lines)
  // ===========================================================================

  static List<String> _clusterVisualLines(List<OCRBlock> blocks) {
    if (blocks.isEmpty) return [];

    // Sort by Top Y primarily
    blocks.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    List<List<OCRBlock>> lines = [];
    
    for (var block in blocks) {
      bool placed = false;
      // Try to fit into existing lines based on Y-overlap
      for (var line in lines) {
        if (_isSameLine(line.first, block)) {
          line.add(block);
          placed = true;
          break;
        }
      }
      if (!placed) {
        lines.add([block]);
      }
    }

    // Sort blocks within each line (Left to Right) and merge text
    return lines.map((line) {
      line.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      return line.map((b) => b.text).join(" ");
    }).toList();
  }

  static bool _isSameLine(OCRBlock ref, OCRBlock target) {
    // If the vertical center of the target is within the vertical range of the ref
    final refCenterY = ref.boundingBox.centerY;
    final top = target.boundingBox.top;
    final bottom = target.boundingBox.bottom;
    
    // Allow some tolerance (e.g. 1% of screen height)
    const tolerance = 0.01; 
    return (refCenterY >= top - tolerance) && (refCenterY <= bottom + tolerance);
  }

  // ===========================================================================
  // B. Domain Identification
  // ===========================================================================

  static DocumentDomain _identifyDomain(List<String> lines) {
    final fullText = lines.join("\n").toLowerCase();
    
    // 1. Shopping (Price, Won, Buy, Cart)
    if (_matchesKeywords(fullText, ['원', '가격', 'price', '결제', '주문', '구매', '장바구니', 'cart', 'buy', '품절', 'sold out', 'delivery', 'shipping', '배송'])) {
         // Stronger checks
         if (fullText.contains('원') && (fullText.contains('주문') || fullText.contains('구매'))) return DocumentDomain.shopping;
         if (fullText.contains('price') || fullText.contains('total')) return DocumentDomain.shopping;
    }

    // 2. SNS (Like, Comment, Share, Follow)
    if (_matchesKeywords(fullText, ['좋아요', '댓글', '공유', '팔로우', 'like', 'comment', 'share', 'follow', 'repost', 'retweet', '@'])) {
        if (fullText.contains('@')) return DocumentDomain.sns; // Handle
    }
    
    // 3. Messenger (Time stamps, Read count, Bubbles - hard to detect by text alone, usually short fragmented lines)
    if (_matchesKeywords(fullText, ['오전', '오후', 'am', 'pm', '읽음', 'read', '전송'])) {
        // Simple heuristic: many lines starting with time
        int timeStartCount = lines.where((l) => RegExp(r'^(\d{1,2}:\d{2})').hasMatch(l)).length;
        if (timeStartCount > 2) return DocumentDomain.messenger;
    }
    
    // 4. Map/Reservation (Map, Reserve, Book, Place)
    if (_matchesKeywords(fullText, ['지도', '예약', 'reserve', 'book', 'location', 'place', '길찾기', '네비', '거리', 'km', '도착'])) {
        return DocumentDomain.mapReservation;
    }
    
    // 5. Work Tool (Slack, Notion, Jira, Ticket, Status)
    if (_matchesKeywords(fullText, ['slack', 'jira', 'notion', 'ticket', 'issue', 'status', 'assigned', 'review', 'pr', 'merge', '회의', '일정', 'todo'])) {
        return DocumentDomain.workTool;
    }

    // Default to Web Article / Generic
    return DocumentDomain.generic;
  }
  
  static bool _matchesKeywords(String text, List<String> keywords) {
      return keywords.any((k) => text.contains(k));
  }

  // ===========================================================================
  // C. Structured Extraction & Summary Generation
  // ===========================================================================

  static ScreenshotAnalysis _extractContentByDomain(DocumentDomain domain, List<String> lines, List<OCRBlock> originalBlocks) {
      String title = _extractTitleGeneric(lines, originalBlocks);
      String summary = "";
      List<String> keyInsights = [];

      switch (domain) {
          case DocumentDomain.shopping:
              final productInfo = _extractShoppingInfo(lines);
              title = productInfo['product'] ?? title;
              summary = "🛍️ 쇼핑 아이템 발견\n";
              if (productInfo['price'] != null) summary += "💰 가격: ${productInfo['price']}\n";
              if (productInfo['product'] != null) keyInsights.add("상품: ${productInfo['product']}");
              if (productInfo['option'] != null) keyInsights.add("옵션: ${productInfo['option']}");
              break;
              
          case DocumentDomain.mapReservation:
              final mapInfo = _extractMapInfo(lines);
              title = mapInfo['place'] ?? title;
              summary = "📍 장소/예약 정보\n";
              if (mapInfo['place'] != null) summary += "장소: ${mapInfo['place']}\n";
              if (mapInfo['date'] != null) keyInsights.add("일시: ${mapInfo['date']}");
              break;

          case DocumentDomain.sns:
              final author = _extractSNSAuthor(lines);
              if (author != null) title = "Post by $author";
              summary = _extractBodyText(lines, limit: 100);
              keyInsights.add("SNS 게시물");
              break;
              
          case DocumentDomain.workTool:
               title = "Work Item / Task";
               summary = _extractBodyText(lines, limit: 120);
               keyInsights.add("업무 관련");
               break;

          default:
              // Web Article or Generic
              // Use sophisticated body extraction
              summary = _extractBodyText(lines, limit: 150);
      }
      
      if (summary.trim().isEmpty) summary = "Content detected.";
      if (keyInsights.isEmpty) keyInsights = _extractGenericKeyPoints(lines);

      return ScreenshotAnalysis(
          title: title, 
          summary: summary, 
          keyInsights: keyInsights
      );
  }

  // --- Domain Helpers ---

  static Map<String, String?> _extractShoppingInfo(List<String> lines) {
      String? product;
      String? price;
      
      for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Price pattern: 10,000원 or $10.99
          if (price == null && RegExp(r'[\d,]+원').hasMatch(line)) {
              price = RegExp(r'([\d,]+원)').firstMatch(line)?.group(1);
          } else if (price == null && RegExp(r'\$[\d,]+\.?\d*').hasMatch(line)) {
               price = RegExp(r'(\$[\d,]+\.?\d*)').firstMatch(line)?.group(1);
          }
          
          // Product name: Usually top lines, not price, longer than 3 chars
          if (product == null && line.length > 5 && !line.contains('원') && !line.contains(r'$')) {
              product = line;
          }
      }
      return {'product': product, 'price': price};
  }
  
  static Map<String, String?> _extractMapInfo(List<String> lines) {
      String? place;
      String? date;
      
      // Heuristic: Place often comes first or is the largest text (handled by title extraction mostly)
      // Date often follows specific patterns
      for (var l in lines) {
          if (date == null && (l.contains('월') && l.contains('일') || l.contains(':'))) {
              if (RegExp(r'\d{1,2}[:\.]\d{2}').hasMatch(l)) {
                  date = l;
              }
          }
      }
      return {'place': place, 'date': date};
  }

  static String? _extractSNSAuthor(List<String> lines) {
      for (var l in lines) {
          if (l.startsWith('@') || l.length < 20 && !l.contains(' ')) {
              return l; // Potential handle
          }
      }
      return null;
  }

  static String _extractTitleGeneric(List<String> lines, List<OCRBlock> originalBlocks) {
      // Find the block with the largest height (biggest font) in the top 30%
      if (originalBlocks.isEmpty) return (lines.isNotEmpty ? lines.first : "No Title");
      
      final topBlocks = originalBlocks.where((b) => b.boundingBox.top < 0.3).toList();
      if (topBlocks.isNotEmpty) {
          topBlocks.sort((a, b) => b.boundingBox.height.compareTo(a.boundingBox.height));
          final candidate = topBlocks.first.text;
          if (candidate.length > 3) return candidate;
      }
      
      return lines.isNotEmpty ? lines.first : "New Screenshot";
  }

  static String _extractBodyText(List<String> lines, {int limit = 100}) {
     // Join lines that look like paragraphs
     // Filter out very short lines (often UI noise)
     List<String> meaningfulLines = lines.where((l) => l.length > 10).toList();
     if (meaningfulLines.isEmpty) return lines.take(3).join(" ");
     
     String body = meaningfulLines.join(" ");
     if (body.length > limit) return body.substring(0, limit) + "...";
     return body;
  }
  
  static List<String> _extractGenericKeyPoints(List<String> lines) {
      return lines.where((l) => l.length > 10 && l.length < 60).take(3).toList();
  }
}
