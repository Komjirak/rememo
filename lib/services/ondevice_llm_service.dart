import 'package:flutter/services.dart';
import 'package:stribe/services/translation_service.dart';

/// 온디바이스 LLM 서비스 (Core ML + Gemma 2B 사용)
/// 파이프라인: Screenshot → PaddleOCR → UI노이즈 제거 → 문단/제목 추정 → LLM 요약 → 번역 → Memo Card
class OnDeviceLLMService {
  static const platform = MethodChannel('com.rememo.komjirak/llm');
  static final TranslationService _translationService = TranslationService();

  /// 🆕 Enhanced Summary Analysis (calls Native EnhancedContentAnalyzer)
  /// enableTranslation: true면 OS 언어와 다른 경우 자동 번역
  static Future<Map<String, dynamic>> analyzeSummaryEnhanced({
    required List<OCRBlock> blocks,
    List<dynamic>? layoutRegions,
    List<dynamic>? importantAreas,
    Map<dynamic, dynamic>? imageSize,
    bool enableTranslation = true,
  }) async {
    try {
      // OCR 블록을 Map 형태로 변환 (Native가 기대하는 형식)
      final textBlocks = blocks.map((block) => {
        'text': block.text,
        'top': block.boundingBox.top,
        'left': block.boundingBox.left,
        'width': block.boundingBox.width,
        'height': block.boundingBox.height,
        'confidence': block.confidence,
      }).toList();

      // 네이티브 LLM 채널 호출
      final result = await platform.invokeMethod('analyzeSummary', {
        'textBlocks': textBlocks,
        'layoutRegions': layoutRegions ?? [],
        'importantAreas': importantAreas ?? [],
        'imageSize': imageSize ?? {'width': 0.0, 'height': 0.0},
        'enableTranslation': false, // Native 번역은 비활성화 (Flutter에서 처리)
      });

      if (result == null) {
        // 폴백: 기존 로직
        print("⚠️ Native Enhanced Analysis returned null, falling back.");
        final legacy = await analyzeScreenshotLegacy(ocrText: "", ocrBlocks: blocks);
        return {
          'title': legacy.title,
          'summary': legacy.summary,
          'tags': legacy.keyInsights,
          'contentType': 'general',
          'wasTranslated': false,
        };
      }

      final resultMap = Map<String, dynamic>.from(result);
      String summary = resultMap['summary'] ?? '';
      String title = resultMap['title'] ?? '제목 없음';
      bool wasTranslated = false;
      String? originalSummary;
      String? originalTitle;

      // 자동 번역 적용
      if (enableTranslation && summary.isNotEmpty) {
        print('🌐 [OnDeviceLLM] Checking translation need...');
        final translationResult = await _translationService.translateToSystemLanguage(summary);

        if (translationResult.wasTranslated) {
          print('🌐 [OnDeviceLLM] Translation applied');
          originalSummary = summary;
          summary = translationResult.translatedText;
          wasTranslated = true;

          // 제목도 번역
          if (title.isNotEmpty) {
            final titleResult = await _translationService.translateToSystemLanguage(title);
            if (titleResult.wasTranslated) {
              originalTitle = title;
              title = titleResult.translatedText;
            }
          }
        }
      }

      return {
        'title': title,
        'summary': summary,
        'tags': List<String>.from(resultMap['tags'] ?? []),
        'contentType': resultMap['contentType'] ?? 'general',
        'wasTranslated': wasTranslated,
        'originalSummary': originalSummary,
        'originalTitle': originalTitle,
      };

    } catch (e) {
      print('Enhanced LLM analysis failed: $e');
      // 폴백
      final legacy = await analyzeScreenshotLegacy(ocrText: "", ocrBlocks: blocks);
      return {
        'title': legacy.title,
        'summary': legacy.summary,
        'tags': legacy.keyInsights,
        'contentType': 'general',
        'wasTranslated': false,
      };
    }
  }

  /// 스크린샷 분석 파이프라인 (전체 흐름) - Legacy
  static Future<ScreenshotAnalysis> analyzeScreenshotLegacy({
    required String ocrText,
    required List<OCRBlock> ocrBlocks, // bounding box 포함
  }) async {
    print('🔄 스크린샷 분석 파이프라인 (Legacy) 시작...');
    print('   - 입력 블록 수: ${ocrBlocks.length}');

    // Step 1: UI 노이즈 제거
    final cleanedBlocks = _filterUINoiseBlocks(ocrBlocks);
    print('   - UI 노이즈 제거 후: ${cleanedBlocks.length}개 블록');

    // Step 2: 문단 및 제목 추정
    final structuredContent = _estimateDocumentStructure(cleanedBlocks);
    print('   - 제목: ${structuredContent.title}');
    print('   - 문단 수: ${structuredContent.paragraphs.length}');
    print('   - 핵심 포인트: ${structuredContent.keyPoints.length}개');

    // Step 3: 온디바이스 LLM으로 요약 생성
    final summary = await _generateSummaryOnDevice(structuredContent);
    print('✅ 스크린샷 분석 완료: ${summary.title}');

    return summary;
  }
  
  // 테스트용 메서드
  static Future<void> testEnhancedAnalysis() async {
    print('=== Enhanced Analysis Test ===');
    
    final testBlocks = [
      OCRBlock(
        text: '10:30',
        boundingBox: BoundingBox(top: 0.02, left: 0.5, width: 0.1, height: 0.02),
        confidence: 0.95,
      ),
      OCRBlock(
        text: '도로 폭발 사고와 정전 피해',
        boundingBox: BoundingBox(top: 0.15, left: 0.1, width: 0.8, height: 0.05),
        confidence: 0.92,
      ),
      OCRBlock(
        text: '경기도 고양시에서 발생한 도로 폭발 사고로 인해 다수의 가구가 정전 피해를 입었다.',
        boundingBox: BoundingBox(top: 0.25, left: 0.1, width: 0.8, height: 0.15),
        confidence: 0.88,
      ),
    ];
    
    final result = await analyzeSummaryEnhanced(
      blocks: testBlocks,
      imageSize: {'width': 1170.0, 'height': 2532.0},
    );
    
    print('Title: ${result['title']}');
    print('Summary: ${result['summary']}');
    print('Tags: ${result['tags']}');
    print('Type: ${result['contentType']}');
    print('=== Test Complete ===');
  }

  // ============================================
  // Step 1: UI 노이즈 제거 (강화된 규칙 기반)
  // ============================================

  /// Public API for filtering UI noise blocks (외부에서 사용 가능)
  static List<OCRBlock> filterUINoiseBlocksPublic(List<OCRBlock> blocks) {
    return _filterUINoiseBlocks(blocks);
  }

  static List<OCRBlock> _filterUINoiseBlocks(List<OCRBlock> blocks) {
    print('🔍 [UI 노이즈 필터링] 입력 블록: ${blocks.length}개');
    
    final filtered = blocks.where((block) {
      final text = block.text.trim();
      final box = block.boundingBox;

      // 1. 빈 텍스트 제거
      if (text.isEmpty) {
        print('   ❌ 필터링: 빈 텍스트');
        return false;
      }

      // 2. 신뢰도 필터 (0.5 이하 제거) - Swift와 통일
      if (block.confidence < 0.5) {
        print('   ❌ 필터링: 낮은 신뢰도 (${block.confidence})');
        return false;
      }

      // 3. 너무 짧은 텍스트 (2자 이하)
      if (text.length <= 2) {
        print('   ❌ 필터링: 너무 짧음 (${text.length}자)');
        return false;
      }

      // 4. 위치 필터 (상단 5%, 하단 8%로 통일 - Swift 3%/5%와 Dart 8%/10%의 균형)
      if (box.top < 0.05) {
        // 상단 영역: 상태바 요소만 제거
        // 시간 패턴 (다양한 형식)
        if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(text)) {
          print('   ❌ 필터링: 시간 패턴 (상단)');
          return false;
        }
        if (RegExp(r'^\d{1,2}:\d{2}\s*(AM|PM|오전|오후)?$', caseSensitive: false).hasMatch(text)) {
          print('   ❌ 필터링: 시간 패턴 (상단)');
          return false;
        }
        // 배터리/신호
        if (RegExp(r'^\d{1,3}%$').hasMatch(text)) {
          print('   ❌ 필터링: 배터리/신호 (상단)');
          return false;
        }
        // 통신사, 와이파이 등
        if (RegExp(r'^(LTE|5G|4G|3G|Wi-Fi|WiFi)$', caseSensitive: false).hasMatch(text)) {
          print('   ❌ 필터링: 통신사/와이파이 (상단)');
          return false;
        }
        // 짧은 상태바 텍스트
        if (text.length <= 6 && box.height < 0.03) {
          print('   ❌ 필터링: 짧은 상태바 텍스트 (상단)');
          return false;
        }
      }

      // 5. 하단 네비게이션 영역 제거 (하단 8%)
      if (box.top > 0.92) {
        print('   ❌ 필터링: 하단 네비게이션 영역');
        return false;
      }

      // 6. 시간/날짜 패턴 (전체 영역에서)
      if (_isTimeOrDatePattern(text)) {
        print('   ❌ 필터링: 시간/날짜 패턴');
        return false;
      }

      // 7. URL 패턴 필터링 (Swift 로직과 통일)
      final urlPatterns = [
        RegExp(r'^https?://', caseSensitive: false),  // URL 프로토콜로 시작
        RegExp(r'^www\.', caseSensitive: false),      // www로 시작
        RegExp(r'\.[a-z]{2,4}(/|$|\?)', caseSensitive: false),  // .com/, .io 등
        RegExp(r'^[a-z0-9-]+\.[a-z]{2,4}$', caseSensitive: false),  // 단순 도메인
      ];
      
      for (final pattern in urlPatterns) {
        if (pattern.hasMatch(text)) {
          print('   ❌ 필터링: URL 패턴');
          return false;
        }
      }
      
      // 케밥케이스 URL 패턴 (a-b-c.xxx 형태)
      if (RegExp(r'^[a-z]+-[a-z]+.*\.[a-z]+', caseSensitive: false).hasMatch(text)) {
        print('   ❌ 필터링: 케밥케이스 URL');
        return false;
      }
      
      // 하이픈이 2개 이상 포함된 텍스트 (URL일 가능성 높음)
      // 단, 날짜 및 전화번호 패턴은 예외 처리
      final hyphenCount = text.split('-').length - 1;
      if (hyphenCount >= 2 && text.length > 10) {
        // 날짜 패턴: YYYY-MM-DD 또는 YY-MM-DD
        final isDatePattern = RegExp(r'^\d{2,4}-\d{1,2}-\d{1,2}$').hasMatch(text);
        // 전화번호 패턴: 010-1234-5678, 02-123-4567 등
        final isPhonePattern = RegExp(r'^\d{2,4}-\d{3,4}-\d{4}$').hasMatch(text);
        // 날짜 범위 패턴: 2024-01-01 ~ 2024-12-31
        final isDateRangePattern = RegExp(r'\d{4}-\d{2}-\d{2}.*\d{4}-\d{2}-\d{2}').hasMatch(text);
        
        if (!isDatePattern && !isPhonePattern && !isDateRangePattern) {
          print('   ❌ 필터링: 다중 하이픈 (URL 가능성)');
          return false;
        }
      }
      
      // 숫자로만 구성된 텍스트 (섹션 번호)
      if (RegExp(r'^[0-9]+\.$').hasMatch(text)) {
        print('   ❌ 필터링: 섹션 번호');
        return false;
      }

      // 8. UI 버튼/메뉴 키워드 필터링 (영어) - 확장
      final englishUIKeywords = [
        'back', 'next', 'done', 'cancel', 'ok', 'yes', 'no', 'close',
        'search', 'menu', 'home', 'settings', 'edit', 'delete', 'share',
        'save', 'send', 'reply', 'forward', 'more', 'options', 'help',
        'login', 'logout', 'sign in', 'sign up', 'submit', 'continue',
        'skip', 'refresh', 'loading', 'retry', 'accept', 'decline',
        'follow', 'like', 'comment', 'repost', 'bookmark', 'copy', 'report',
        'block', 'mute', 'pin', 'unpin', 'archive', 'download', 'upload',
        'play', 'pause', 'stop', 'prev', 'next', 'shuffle', 'repeat',
        'tap', 'swipe', 'scroll', 'drag', 'drop', 'click', 'press',
        'see more', 'show more', 'view all', 'load more', 'read more',
        'ad', 'ads', 'sponsored', 'promoted', 'advertisement',
      ];

      // 9. UI 버튼/메뉴 키워드 필터링 (한국어) - 확장
      final koreanUIKeywords = [
        '뒤로', '다음', '완료', '취소', '확인', '설정', '닫기',
        '검색', '메뉴', '홈', '편집', '삭제', '공유', '저장',
        '보내기', '답장', '전달', '더보기', '옵션', '도움말',
        '로그인', '로그아웃', '가입', '제출', '계속', '건너뛰기',
        '새로고침', '로딩', '재시도', '수락', '거절', '이전',
        '팔로우', '팔로잉', '좋아요', '댓글', '리포스트', '북마크',
        '복사', '신고', '차단', '뮤트', '고정', '보관', '다운로드',
        '재생', '일시정지', '정지', '이전곡', '다음곡', '셔플', '반복',
        '더 보기', '전체 보기', '모두 보기', '펼치기', '접기',
        '광고', '스폰서', '홍보', '프로모션',
        '알림', '알람', '푸시', '업데이트', '버전',
        '개인정보', '이용약관', '고객센터', '문의',
      ];

      final lowerText = text.toLowerCase();
      if (englishUIKeywords.contains(lowerText)) {
        print('   ❌ 필터링: 영어 UI 키워드');
        return false;
      }
      if (koreanUIKeywords.contains(text)) {
        print('   ❌ 필터링: 한국어 UI 키워드');
        return false;
      }

      // 10. 짧은 버튼 텍스트 (작은 영역 + 짧은 텍스트)
      if (box.width < 0.20 && box.height < 0.05 && text.length < 12) {
        // 의미있는 내용이 아니면 제거
        if (!_containsMeaningfulContent(text)) {
          print('   ❌ 필터링: 짧은 버튼 텍스트 (의미 없음)');
          return false;
        }
      }

      // 11. 아이콘/이모지만 있는 경우
      if (RegExp(r'^[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]+$', unicode: true).hasMatch(text)) {
        print('   ❌ 필터링: 이모지만');
        return false;
      }

      // 12. 네비게이션 바 요소 (좌우 끝에 있는 짧은 텍스트)
      if ((box.left < 0.15 || box.right > 0.85) && box.top < 0.12 && text.length < 15) {
        if (!_containsMeaningfulContent(text)) {
          print('   ❌ 필터링: 네비게이션 바 요소');
          return false;
        }
      }

      // 13. 탭바/세그먼트 컨트롤 (가로로 배열된 짧은 텍스트들)
      if (box.height < 0.05 && text.length < 15) {
        final buttonLikeKeywords = ['all', 'recent', 'popular', 'new', 'hot',
          '전체', '최신', '인기', '추천', '즐겨찾기', 'favorites',
          '피드', 'feed', '탐색', 'explore', '트렌드', 'trending',
          '팔로잉', 'following', '추천', 'for you', 'foryou'];
        if (buttonLikeKeywords.contains(lowerText)) {
          print('   ❌ 필터링: 탭바 키워드');
          return false;
        }
      }

      // 14. 광고/프로모션 패턴
      if (_isAdvertisementPattern(text)) {
        print('   ❌ 필터링: 광고 패턴');
        return false;
      }

      // 15. 앱 이름/브랜드 패턴 (상단에 있는 경우)
      if (box.top < 0.15 && text.length < 20) {
        if (_isAppBrandPattern(text)) {
          print('   ❌ 필터링: 앱 브랜드 패턴');
          return false;
        }
      }

      // 16. 숫자만 있는 경우 (조회수, 좋아요 수 등)
      if (RegExp(r'^[\d,\.]+[KMB]?$', caseSensitive: false).hasMatch(text)) {
        print('   ❌ 필터링: 숫자만');
        return false;
      }

      // 17. 매우 작은 영역의 텍스트 (UI 요소일 가능성 높음)
      if (box.area < 0.002 && text.length < 15) {
        print('   ❌ 필터링: 매우 작은 영역');
        return false;
      }

      print('   ✅ 유지: "$text"');
      return true;
    }).toList();
    
    print('🔍 [UI 노이즈 필터링] 출력 블록: ${filtered.length}개 (${blocks.length - filtered.length}개 제거됨)');
    return filtered;
  }

  /// 시간/날짜 패턴 확인
  static bool _isTimeOrDatePattern(String text) {
    final patterns = [
      RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$'), // 12:34, 12:34:56
      RegExp(r'^\d{1,2}:\d{2}\s*(AM|PM|am|pm|오전|오후)$'), // 12:34 PM
      RegExp(r'^\d{1,2}(월|일|시|분|초)$'), // 12월, 5일
      RegExp(r'^\d{4}[-/\.]\d{1,2}[-/\.]\d{1,2}$'), // 2024-01-15
      RegExp(r'^\d{1,2}[-/\.]\d{1,2}[-/\.]\d{2,4}$'), // 01/15/24
      RegExp(r'^(오늘|어제|그저께|내일|모레)$'),
      RegExp(r'^(today|yesterday|tomorrow)$', caseSensitive: false),
      RegExp(r'^\d+\s*(초|분|시간|일|주|달|년)\s*전$'), // 5분 전
      RegExp(r'^\d+\s*(sec|min|hour|day|week|month|year)s?\s*ago$', caseSensitive: false),
      RegExp(r'^just now$', caseSensitive: false),
      RegExp(r'^방금$'),
    ];

    return patterns.any((p) => p.hasMatch(text.trim()));
  }

  /// 광고/프로모션 패턴 확인
  static bool _isAdvertisementPattern(String text) {
    final lower = text.toLowerCase();
    final adPatterns = [
      'sponsored', 'promoted', 'advertisement', 'ad ', ' ad',
      '광고', '스폰서', '홍보', '프로모션', 'promo',
      'install now', 'download now', 'get it now', 'try free',
      '지금 설치', '무료 체험', '다운로드',
      'shop now', 'buy now', 'order now', '지금 구매', '바로 구매',
      'learn more', '자세히 보기', '더 알아보기',
    ];

    return adPatterns.any((p) => lower.contains(p));
  }

  /// 앱 브랜드 패턴 확인
  static bool _isAppBrandPattern(String text) {
    final brandPatterns = [
      RegExp(r'^(Instagram|Twitter|Facebook|TikTok|YouTube|LinkedIn)$', caseSensitive: false),
      RegExp(r'^(카카오톡|카카오|네이버|라인|당근|배민|쿠팡)$'),
      RegExp(r'^(Safari|Chrome|Firefox|Edge)$', caseSensitive: false),
      RegExp(r'^@\w+$'), // @username
    ];

    return brandPatterns.any((p) => p.hasMatch(text.trim()));
  }

  /// 의미있는 콘텐츠인지 확인 (강화)
  static bool _containsMeaningfulContent(String text) {
    // 숫자나 특수문자만 있는 경우
    if (RegExp(r'^[\d\s\-\+\(\)\*\#\.\,\:\/]+$').hasMatch(text)) return false;

    // 단일 문자 반복 (예: "...", "---", "===")
    if (RegExp(r'^(.)\1{2,}$').hasMatch(text)) return false;

    // URL 패턴
    if (text.contains('http://') || text.contains('https://') || text.contains('www.')) {
      return false;
    }

    // 이메일 패턴
    if (RegExp(r'\S+@\S+\.\S+').hasMatch(text)) return false;

    // 전화번호 패턴
    if (RegExp(r'^[\d\-\+\(\)\s]{8,}$').hasMatch(text)) return false;

    // 한글 3자 이상 또는 영문 4자 이상 단어가 포함된 경우 의미있음
    if (RegExp(r'[가-힣]{3,}').hasMatch(text)) return true;
    if (RegExp(r'[a-zA-Z]{4,}').hasMatch(text)) return true;

    // 문장 형태 (주어+동사 등)인 경우
    if (text.length > 15 && (text.contains(' ') || text.contains('.'))) {
      return true;
    }

    return text.length > 20;
  }

  // ============================================
  // Step 2: 문단/제목 추정 (위치 및 크기 기반)
  // ============================================
  static DocumentStructure _estimateDocumentStructure(List<OCRBlock> blocks) {
    if (blocks.isEmpty) {
      return DocumentStructure(title: '', paragraphs: [], keyPoints: []);
    }

    // 블록을 세로 위치 기준으로 정렬
    final sortedBlocks = List<OCRBlock>.from(blocks);
    sortedBlocks.sort((a, b) {
      // Y 위치가 비슷하면 (2% 이내) X 위치로 정렬
      if ((a.boundingBox.top - b.boundingBox.top).abs() < 0.02) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return a.boundingBox.top.compareTo(b.boundingBox.top);
    });

    // 제목 추정 전략
    String? title = _estimateTitle(sortedBlocks);

    // 제목으로 사용된 블록 제거
    List<OCRBlock> contentBlocks = sortedBlocks;
    if (title != null) {
      contentBlocks = sortedBlocks.where((b) => b.text != title).toList();
    }

    // 문단 그룹화
    final paragraphs = _groupIntoParagraphs(contentBlocks);

    // 키 포인트 추출
    final keyPoints = _extractKeyPoints(paragraphs, contentBlocks);

    return DocumentStructure(
      title: title ?? (paragraphs.isNotEmpty ? _generateFallbackTitle(paragraphs.first) : 'New Memory'),
      paragraphs: paragraphs,
      keyPoints: keyPoints,
    );
  }

  /// 제목 추정 (개선된 다중 전략 조합)
  static String? _estimateTitle(List<OCRBlock> blocks) {
    if (blocks.isEmpty) return null;

    // 후보 수집 및 점수화
    final candidates = <MapEntry<OCRBlock, double>>[];

    for (final block in blocks) {
      final text = block.text.trim();
      final box = block.boundingBox;
      
      // 기본 필터링
      if (text.length < 5 || text.length > 80) continue;
      if (text.contains('http') || text.contains('www.')) continue;
      if (_isUIElement(text) || _isTimeOrDatePattern(text)) continue;
      
      double score = 0.0;
      
      // 전략 1: 위치 점수 (상단에 있을수록 높음)
      if (box.top < 0.20) {
        score += 20.0;
        if (box.top < 0.10) score += 10.0; // 더 상단이면 추가 점수
      } else if (box.top < 0.30) {
        score += 10.0;
      } else {
        score -= 5.0; // 하단이면 감점
      }
      
      // 전략 2: 크기 점수 (큰 폰트 = 제목)
      final avgHeight = blocks.map((b) => b.boundingBox.height).reduce((a, b) => a + b) / blocks.length;
      if (box.height > avgHeight * 1.5) {
        score += 15.0; // 평균보다 1.5배 크면 높은 점수
      } else if (box.height > avgHeight) {
        score += 5.0;
      }
      
      // 전략 3: 의미 분석 점수
      // 명사 비율 (간단한 휴리스틱)
      final words = text.split(RegExp(r'\s+'));
      final meaningfulWords = words.where((w) => 
        w.length >= 3 && 
        !RegExp(r'^(the|a|an|and|or|but|in|on|at|to|for|of|with|by|from|as|is|was|are|were|been|be|have|has|had|do|does|did|will|would|could|should|may|might|must|shall|can|need|this|that|these|those|it|its|you|your|we|our|they|their|he|his|she|her|i|my|me|이|그|저|것|수|등|및|또는|그리고|하지만)$', caseSensitive: false).hasMatch(w.toLowerCase())
      ).length;
      
      if (words.isNotEmpty) {
        final meaningfulRatio = meaningfulWords / words.length;
        score += meaningfulRatio * 10.0;
      }
      
      // 전략 4: 길이 점수 (적절한 길이: 10-50자)
      if (text.length >= 10 && text.length <= 50) {
        score += 10.0;
      } else if (text.length >= 5 && text.length < 10) {
        score += 5.0;
      } else if (text.length > 50) {
        score -= 5.0; // 너무 길면 감점
      }
      
      // 전략 5: 중앙 정렬 점수 (제목은 보통 중앙에 위치)
      final centerX = box.centerX;
      if (centerX > 0.3 && centerX < 0.7) {
        score += 5.0;
      }
      
      // 전략 6: UI 요소 제외 강화
      if (_isAppBrandPattern(text)) {
        score -= 20.0;
      }
      
      candidates.add(MapEntry(block, score));
    }
    
    if (candidates.isEmpty) return null;
    
    // 점수 순으로 정렬
    candidates.sort((a, b) => b.value.compareTo(a.value));
    
    // 최고 점수 후보 반환
    final topCandidate = candidates.first;
    print('📌 제목 추정: "${topCandidate.key.text}" (점수: ${topCandidate.value.toStringAsFixed(1)})');
    
    return topCandidate.key.text.trim();
  }

  /// UI 요소인지 확인
  static bool _isUIElement(String text) {
    final uiPatterns = [
      RegExp(r'^\d{1,2}:\d{2}'),  // 시간
      RegExp(r'^\d+%$'),           // 퍼센트
      RegExp(r'^[\d\.\,]+원$'),    // 가격
    ];

    for (final pattern in uiPatterns) {
      if (pattern.hasMatch(text)) return true;
    }

    return false;
  }

  /// 문단 그룹화 (세로 간격 기반)
  static List<String> _groupIntoParagraphs(List<OCRBlock> blocks) {
    if (blocks.isEmpty) return [];

    final paragraphs = <String>[];
    List<String> currentParagraph = [];
    double lastBottom = 0;
    double avgHeight = blocks.map((b) => b.boundingBox.height).reduce((a, b) => a + b) / blocks.length;

    for (final block in blocks) {
      final verticalGap = block.boundingBox.top - lastBottom;

      // 줄 간격이 평균 높이의 2배 이상이면 새 문단
      if (lastBottom > 0 && verticalGap > avgHeight * 2 && currentParagraph.isNotEmpty) {
        paragraphs.add(currentParagraph.join(' '));
        currentParagraph = [];
      }

      currentParagraph.add(block.text.trim());
      lastBottom = block.boundingBox.bottom;
    }

    if (currentParagraph.isNotEmpty) {
      paragraphs.add(currentParagraph.join(' '));
    }

    return paragraphs;
  }

  /// 키 포인트 추출
  static List<String> _extractKeyPoints(List<String> paragraphs, List<OCRBlock> blocks) {
    final keyPoints = <String>[];

    // 방법 1: 적절한 길이의 문단 (10~100자)
    for (final para in paragraphs) {
      if (para.length >= 10 && para.length <= 100) {
        // URL이 포함되지 않은 것
        if (!para.contains('http')) {
          keyPoints.add(para);
        }
      }
      if (keyPoints.length >= 4) break;
    }

    // 방법 2: 키포인트가 부족하면 긴 문단에서 문장 추출
    if (keyPoints.length < 2) {
      for (final para in paragraphs) {
        if (para.length > 100) {
          // 문장 분리
          final sentences = para.split(RegExp(r'[.!?。！？]\s*'));
          for (final sentence in sentences) {
            if (sentence.length >= 10 && sentence.length <= 100) {
              if (!keyPoints.contains(sentence)) {
                keyPoints.add(sentence);
              }
            }
            if (keyPoints.length >= 4) break;
          }
        }
        if (keyPoints.length >= 4) break;
      }
    }

    return keyPoints.take(4).toList();
  }

  // ============================================
  // Step 3: 온디바이스 LLM으로 요약 생성 (Gemma 2B)
  // ============================================
  static Future<ScreenshotAnalysis> _generateSummaryOnDevice(
    DocumentStructure structure
  ) async {
    try {
      print('🤖 온디바이스 LLM (Gemma 2B) 호출 중...');

      // iOS Native에서 Core ML + Gemma 2B 실행
      final result = await platform.invokeMethod('analyzeSummary', {
        'title': structure.title,
        'paragraphs': structure.paragraphs,
        'keyPoints': structure.keyPoints,
      });

      if (result is Map) {
        final title = result['title'] as String? ?? structure.title;
        final summary = result['summary'] as String? ?? _generateFallbackSummary(structure);
        final keyInsights = result['keyInsights'] as List?;

        print('✅ LLM 분석 완료: $title');

        return ScreenshotAnalysis(
          title: title,
          summary: summary,
          keyInsights: keyInsights != null
              ? List<String>.from(keyInsights)
              : structure.keyPoints,
        );
      }

      throw Exception('Invalid result format');
    } catch (e) {
      print('⚠️ 온디바이스 LLM 실패, Fallback 사용: $e');
      // Fallback: 규칙 기반 요약
      return ScreenshotAnalysis(
        title: structure.title,
        summary: _generateFallbackSummary(structure),
        keyInsights: structure.keyPoints,
      );
    }
  }

  /// Fallback: 규칙 기반 제목 생성
  static String _generateFallbackTitle(String firstParagraph) {
    final title = firstParagraph.trim();
    if (title.length <= 20) return title;

    // 단어 단위로 자르기
    final words = title.split(RegExp(r'\s+'));
    String result = '';
    for (final word in words) {
      if ((result + word).length > 20) break;
      result += '$word ';
    }

    return result.trim().isEmpty ? title.substring(0, 20) : result.trim();
  }

  /// Fallback: 규칙 기반 요약 생성 (개선된 알고리즘)
  static String _generateFallbackSummary(DocumentStructure structure) {
    if (structure.paragraphs.isEmpty) {
      return '텍스트 내용이 감지되었습니다.';
    }

    // 문장 중요도 기반 선택
    final allSentences = <MapEntry<String, double>>[];
    
    for (final para in structure.paragraphs) {
      final sentences = _splitIntoSentences(para);
      for (final sentence in sentences) {
        final score = _scoreSentenceForSummary(sentence, structure);
        allSentences.add(MapEntry(sentence, score));
      }
    }
    
    // 점수 순으로 정렬
    allSentences.sort((a, b) => b.value.compareTo(a.value));
    
    // 상위 3개 문장 선택 (최대 150자)
    final selectedSentences = <String>[];
    int totalLength = 0;
    
    for (final entry in allSentences) {
      if (totalLength + entry.key.length > 150) break;
      selectedSentences.add(entry.key);
      totalLength += entry.key.length;
    }
    
    if (selectedSentences.isEmpty) {
      // Fallback: 처음 2-3개 문단을 120자 이내로 요약
      final combined = structure.paragraphs.take(3).join(' ');
      if (combined.length <= 120) return combined;
      return '${combined.substring(0, 117)}...';
    }
    
    final summary = selectedSentences.join(' ');
    return summary.length > 150 ? '${summary.substring(0, 147)}...' : summary;
  }
  
  /// 문장을 문장 단위로 분리
  static List<String> _splitIntoSentences(String text) {
    // 문장 종료 기호로 분리
    final sentences = text.split(RegExp(r'[.!?。！？]\s*'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && s.length >= 10)
      .toList();
    
    return sentences;
  }
  
  /// 문장 중요도 점수화
  static double _scoreSentenceForSummary(String sentence, DocumentStructure structure) {
    double score = 0.0;
    final text = sentence.trim();
    
    // 1. 길이 점수 (적절한 길이: 20-100자)
    if (text.length >= 20 && text.length <= 100) {
      score += 10.0;
    } else if (text.length > 100 && text.length <= 150) {
      score += 5.0;
    } else {
      score -= 5.0;
    }
    
    // 2. 위치 점수 (첫 번째 문단에 있으면 높음)
    bool isInFirstParagraph = false;
    if (structure.paragraphs.isNotEmpty) {
      isInFirstParagraph = structure.paragraphs.first.contains(text);
    }
    if (isInFirstParagraph) score += 5.0;
    
    // 3. 키워드 밀도 (명사, 동사 비율)
    final words = text.split(RegExp(r'\s+'));
    final meaningfulWords = words.where((w) => 
      w.length >= 3 && 
      !RegExp(r'^(the|a|an|and|or|but|in|on|at|to|for|of|with|by|from|as|is|was|are|were|been|be|have|has|had|do|does|did|will|would|could|should|may|might|must|shall|can|need|this|that|these|those|it|its|you|your|we|our|they|their|he|his|she|her|i|my|me)$', caseSensitive: false).hasMatch(w.toLowerCase())
    ).length;
    
    if (words.isNotEmpty) {
      final meaningfulRatio = meaningfulWords / words.length;
      score += meaningfulRatio * 10.0;
    }
    
    // 4. UI 노이즈 제외
    if (_isUIElement(text) || _isTimeOrDatePattern(text)) {
      score -= 100.0; // 강력히 제외
    }
    
    // 5. URL 패턴 제외
    if (text.contains('http://') || text.contains('https://') || text.contains('www.')) {
      score -= 50.0;
    }
    
    // 6. 문장 구조 점수 (주어+동사 형태)
    if (text.contains(' ') && text.length > 15) {
      score += 3.0;
    }
    
    return score;
  }
}

// ============================================
// 데이터 모델
// ============================================

/// OCR 블록 모델 (bounding box 포함)
class OCRBlock {
  final String text;
  final BoundingBox boundingBox;
  final double confidence;

  OCRBlock({
    required this.text,
    required this.boundingBox,
    this.confidence = 1.0,
  });

  /// Native 데이터에서 OCRBlock 생성
  factory OCRBlock.fromNative(Map<String, dynamic> data) {
    return OCRBlock(
      text: data['text'] as String? ?? '',
      boundingBox: BoundingBox(
        top: (data['top'] as num?)?.toDouble() ?? 0,
        left: (data['left'] as num?)?.toDouble() ?? 0,
        width: (data['width'] as num?)?.toDouble() ?? 0,
        height: (data['height'] as num?)?.toDouble() ?? 0,
      ),
      confidence: (data['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Bounding Box 모델
class BoundingBox {
  final double top;
  final double left;
  final double width;
  final double height;

  double get bottom => top + height;
  double get right => left + width;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;
  double get area => width * height;

  BoundingBox({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  });
}

/// 문서 구조 모델
class DocumentStructure {
  final String title;
  final List<String> paragraphs;
  final List<String> keyPoints;

  DocumentStructure({
    required this.title,
    required this.paragraphs,
    required this.keyPoints,
  });
}

/// 스크린샷 분석 결과 모델
class ScreenshotAnalysis {
  final String title;
  final String summary;
  final List<String> keyInsights;

  ScreenshotAnalysis({
    required this.title,
    required this.summary,
    required this.keyInsights,
  });
}
