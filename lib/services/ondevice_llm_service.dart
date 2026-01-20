import 'package:flutter/services.dart';

/// 온디바이스 LLM 서비스 (Core ML + Gemma 2B 사용)
/// 파이프라인: Screenshot → PaddleOCR → UI노이즈 제거 → 문단/제목 추정 → LLM 요약 → Memo Card
class OnDeviceLLMService {
  static const platform = MethodChannel('com.komjirak.stribe/llm');

  /// 스크린샷 분석 파이프라인 (전체 흐름)
  static Future<ScreenshotAnalysis> analyzeScreenshot({
    required String ocrText,
    required List<OCRBlock> ocrBlocks, // bounding box 포함
  }) async {
    print('🔄 스크린샷 분석 파이프라인 시작...');
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

  // ============================================
  // Step 1: UI 노이즈 제거 (향상된 규칙 기반)
  // ============================================
  static List<OCRBlock> _filterUINoiseBlocks(List<OCRBlock> blocks) {
    return blocks.where((block) {
      final text = block.text.trim();
      final box = block.boundingBox;

      // 1. 빈 텍스트 제거
      if (text.isEmpty) return false;

      // 2. 너무 짧은 텍스트 (2자 이하)
      if (text.length <= 2) return false;

      // 3. 상태바 영역 제거 (상단 5%)
      if (box.top < 0.05 && box.height < 0.03) {
        // 시간, 배터리 등 상태바 요소
        if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(text)) return false;
        if (RegExp(r'^\d{1,3}%$').hasMatch(text)) return false;
        if (text.length <= 5) return false;
      }

      // 4. 하단 네비게이션 영역 제거 (하단 8%)
      if (box.top > 0.92) {
        return false;
      }

      // 5. UI 버튼/메뉴 키워드 필터링 (영어)
      final englishUIKeywords = [
        'back', 'next', 'done', 'cancel', 'ok', 'yes', 'no', 'close',
        'search', 'menu', 'home', 'settings', 'edit', 'delete', 'share',
        'save', 'send', 'reply', 'forward', 'more', 'options', 'help',
        'login', 'logout', 'sign in', 'sign up', 'submit', 'continue',
        'skip', 'refresh', 'loading', 'retry', 'accept', 'decline',
      ];

      // 6. UI 버튼/메뉴 키워드 필터링 (한국어)
      final koreanUIKeywords = [
        '뒤로', '다음', '완료', '취소', '확인', '설정', '닫기',
        '검색', '메뉴', '홈', '편집', '삭제', '공유', '저장',
        '보내기', '답장', '전달', '더보기', '옵션', '도움말',
        '로그인', '로그아웃', '가입', '제출', '계속', '건너뛰기',
        '새로고침', '로딩', '재시도', '수락', '거절', '이전',
      ];

      final lowerText = text.toLowerCase();
      if (englishUIKeywords.contains(lowerText)) return false;
      if (koreanUIKeywords.contains(text)) return false;

      // 7. 짧은 버튼 텍스트 (작은 영역 + 짧은 텍스트)
      if (box.width < 0.15 && box.height < 0.04 && text.length < 10) {
        return false;
      }

      // 8. 아이콘/이모지만 있는 경우
      if (RegExp(r'^[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]+$', unicode: true).hasMatch(text)) {
        return false;
      }

      // 9. 네비게이션 바 요소 (좌우 끝에 있는 짧은 텍스트)
      if ((box.left < 0.1 || box.right > 0.9) && box.top < 0.1 && text.length < 15) {
        if (!_containsMeaningfulContent(text)) {
          return false;
        }
      }

      // 10. 탭바/세그먼트 컨트롤 (가로로 배열된 짧은 텍스트들)
      if (box.height < 0.05 && text.length < 15) {
        final buttonLikeKeywords = ['all', 'recent', 'popular', 'new', 'hot',
          '전체', '최신', '인기', '추천', '즐겨찾기', 'favorites'];
        if (buttonLikeKeywords.contains(lowerText)) return false;
      }

      return true;
    }).toList();
  }

  /// 의미있는 콘텐츠인지 확인
  static bool _containsMeaningfulContent(String text) {
    // 숫자나 특수문자만 있는 경우
    if (RegExp(r'^[\d\s\-\+\(\)\*\#\.]+$').hasMatch(text)) return false;

    // 한글이나 알파벳이 포함된 경우 의미있는 콘텐츠로 판단
    if (RegExp(r'[가-힣a-zA-Z]{3,}').hasMatch(text)) return true;

    return text.length > 10;
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

  /// 제목 추정 (여러 전략 조합)
  static String? _estimateTitle(List<OCRBlock> blocks) {
    if (blocks.isEmpty) return null;

    // 전략 1: 상단 20% 영역에서 가장 높이가 큰 텍스트 (큰 폰트 = 제목)
    final topBlocks = blocks.where((b) => b.boundingBox.top < 0.20).toList();

    if (topBlocks.isNotEmpty) {
      // 높이가 가장 큰 블록 찾기
      topBlocks.sort((a, b) => b.boundingBox.height.compareTo(a.boundingBox.height));

      for (final block in topBlocks) {
        final text = block.text.trim();
        // 제목으로 적합한 길이 (5~80자)
        if (text.length >= 5 && text.length <= 80) {
          // URL이 아닌 경우
          if (!text.contains('http') && !text.contains('www')) {
            return text;
          }
        }
      }
    }

    // 전략 2: 첫 번째 의미있는 텍스트
    for (final block in blocks) {
      final text = block.text.trim();
      if (text.length >= 5 && text.length <= 80) {
        if (!text.contains('http') && !_isUIElement(text)) {
          return text;
        }
      }
    }

    return null;
  }

  /// UI 요소인지 확인
  static bool _isUIElement(String text) {
    final lower = text.toLowerCase();
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

  /// Fallback: 규칙 기반 요약 생성
  static String _generateFallbackSummary(DocumentStructure structure) {
    if (structure.paragraphs.isEmpty) {
      return '텍스트 내용이 감지되었습니다.';
    }

    // 처음 2-3개 문단을 120자 이내로 요약
    final combined = structure.paragraphs.take(3).join(' ');
    if (combined.length <= 120) return combined;

    return '${combined.substring(0, 117)}...';
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
