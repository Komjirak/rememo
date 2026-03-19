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
  static ScreenshotAnalysis parseDocument(List<OCRBlock> rawBlocks, {String? externalCategory}) {
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
    // Prefer external category (from Native AI) if available
    DocumentDomain domain = DocumentDomain.generic;
    if (externalCategory != null) {
        domain = _mapCategoryToDomain(externalCategory);
        if (domain == DocumentDomain.generic) {
             // Fallback to internal heuristic if native mapped to generic
             domain = _identifyDomain(visualLines);
        } else {
             print('📊 Using Native Category: $externalCategory -> $domain');
        }
    } else {
        domain = _identifyDomain(visualLines);
        print('📊 Detected Domain (Rule-based): $domain');
    }

    // 4. Domain-Specific Extraction
    return _extractContentByDomain(domain, visualLines, noiseFreeBlocks);
  }
  
  static DocumentDomain _mapCategoryToDomain(String category) {
      switch (category) {
          case 'Shopping': return DocumentDomain.shopping;
          case 'Food': return DocumentDomain.generic; // Or handle food specific
          case 'Work': return DocumentDomain.workTool;
          case 'Social': return DocumentDomain.sns;
          case 'Finance': return DocumentDomain.finance;
          case 'Map': return DocumentDomain.mapReservation;
          case 'Design': return DocumentDomain.generic;
          default: return DocumentDomain.generic;
      }
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
              final mapBody = _extractBodyText(lines, limit: 80);
              summary = mapInfo['place'] != null
                  ? "📍 ${mapInfo['place']}${mapInfo['date'] != null ? ' · ${mapInfo['date']}' : ''} — $mapBody"
                  : "📍 장소/예약 정보\n$mapBody";
              if (mapInfo['date'] != null) keyInsights.add("일시: ${mapInfo['date']}");
              break;

          case DocumentDomain.sns:
              final author = _extractSNSAuthor(lines);
              if (author != null) title = "Post by $author";
              final snsBody = _extractBodyText(lines, limit: 120);
              summary = author != null ? "$author 게시물 — $snsBody" : snsBody;
              keyInsights.add("SNS 게시물");
              break;

          case DocumentDomain.workTool:
              summary = _extractBodyText(lines, limit: 150);
              // 첫 번째 의미있는 줄을 제목으로 재시도
              final workTitle = lines.firstWhere(
                (l) => l.trim().length >= 5 && l.trim().length <= 60,
                orElse: () => '',
              ).trim();
              if (workTitle.isNotEmpty) title = workTitle;
              keyInsights.add("업무 관련");
              break;

          default:
              // Web Article or Generic: 문장 점수화 기반 요약
              summary = _extractBodyText(lines, limit: 180);
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
    if (originalBlocks.isEmpty) return lines.isNotEmpty ? lines.first : "No Title";

    // 텍스트 전용 모드 감지: height 분산이 작으면 합성 블록 → 줄 기반 전략
    if (originalBlocks.length >= 3) {
      final heights = originalBlocks.map((b) => b.boundingBox.height).toList();
      final mean = heights.reduce((a, b) => a + b) / heights.length;
      final variance = heights.map((h) => (h - mean) * (h - mean)).reduce((a, b) => a + b) / heights.length;

      if (variance < 0.001) {
        // 텍스트 전용: 첫 줄 중 짧고 문장 부호로 끝나지 않는 줄을 제목으로 선택
        for (final line in lines) {
          final t = line.trim();
          if (t.length >= 4 && t.length <= 60 && !t.endsWith('.') && !t.startsWith('@')) {
            return t;
          }
        }
        return lines.isNotEmpty ? lines.first : "New Screenshot";
      }
    }

    // 일반 모드: 상단 30% + 큰 폰트 우선
    final uiExcludePatterns = [
      RegExp(r'^\d{1,2}:\d{2}'),     // 시간
      RegExp(r'^\d{1,3}%$'),          // 배터리
      RegExp(r'^(로그인|회원가입|검색|메뉴|홈|설정|닫기)$'),
    ];

    final topBlocks = originalBlocks
        .where((b) => b.boundingBox.top < 0.3)
        .where((b) {
          final t = b.text.trim();
          return t.length > 3 && !uiExcludePatterns.any((p) => p.hasMatch(t));
        })
        .toList();

    if (topBlocks.isNotEmpty) {
      topBlocks.sort((a, b) => b.boundingBox.height.compareTo(a.boundingBox.height));
      final candidate = topBlocks.first.text.trim();
      if (candidate.length > 3) return candidate;
    }

    return lines.isNotEmpty ? lines.first : "New Screenshot";
  }

  /// 문장 중요도 점수화 (위치 가중치 + 길이 + 키워드 밀도)
  static double _scoreSentence(String sentence, int lineIndex, int totalLines) {
    double score = 0.0;
    final t = sentence.trim();

    // 1. 길이 점수 (20~120자 적합)
    if (t.length >= 20 && t.length <= 120) {
      score += 3.0;
    } else if (t.length > 120) {
      score += 1.0;
    }

    // 2. 위치 점수 (앞 1/3 영역 우선)
    if (totalLines > 0) {
      final relPos = lineIndex / totalLines;
      if (relPos < 0.33) score += 2.0;
      else if (relPos < 0.66) score += 1.0;
    }

    // 3. 완전한 문장 (종결 어미로 끝나면 가산)
    if (t.endsWith('다') || t.endsWith('요') || t.endsWith('.') || t.endsWith('!')) {
      score += 1.5;
    }

    // 4. 숫자/데이터 포함 (정보 밀도 높음)
    if (RegExp(r'\d').hasMatch(t)) score += 1.0;

    // 5. 핵심 키워드 포함
    const importantKw = ['소개', '설명', '발표', '강조', '주장', '밝혔', '특징', '중요', '핵심', '요약'];
    if (importantKw.any((k) => t.contains(k))) score += 0.8;

    return score;
  }

  /// 문장 중요도 기반 요약 생성 (도메인별 길이 제한 조절 가능)
  static String _extractBodyText(List<String> lines, {int limit = 150}) {
    final meaningfulLines = lines.where((l) => l.trim().length > 10).toList();
    if (meaningfulLines.isEmpty) return lines.take(3).join(' ');

    // 문장 분리 + 점수화
    final scored = <MapEntry<String, double>>[];
    for (int i = 0; i < meaningfulLines.length; i++) {
      final sentences = meaningfulLines[i]
          .split(RegExp(r'[.!?。！？]\s*'))
          .map((s) => s.trim())
          .where((s) => s.length >= 10)
          .toList();
      for (final s in sentences) {
        scored.add(MapEntry(s, _scoreSentence(s, i, meaningfulLines.length)));
      }
    }

    if (scored.isEmpty) {
      final raw = meaningfulLines.join(' ');
      return raw.length > limit ? '${raw.substring(0, limit - 3)}...' : raw;
    }

    // 점수 내림차순 정렬 후 상위 선택 (limit 초과 시 중단)
    scored.sort((a, b) => b.value.compareTo(a.value));

    final selected = <String>[];
    int totalLen = 0;
    for (final entry in scored) {
      if (totalLen + entry.key.length > limit) break;
      selected.add(entry.key);
      totalLen += entry.key.length;
      if (selected.length >= 3) break;
    }

    final summary = selected.join(' ');
    return summary.isEmpty
        ? (meaningfulLines.first.length > limit
            ? '${meaningfulLines.first.substring(0, limit - 3)}...'
            : meaningfulLines.first)
        : summary;
  }

  static List<String> _extractGenericKeyPoints(List<String> lines) {
    return lines.where((l) => l.length > 10 && l.length < 60).take(3).toList();
  }
}
