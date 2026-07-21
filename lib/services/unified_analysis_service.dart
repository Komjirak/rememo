import 'package:stribe/services/ondevice_llm_service.dart';
import 'package:stribe/services/document_parser_service.dart';
import 'package:stribe/services/openai_service.dart';
import 'package:stribe/utils/app_logger.dart';
import 'package:stribe/utils/text_heuristics.dart';

/// 통합 분석 서비스
/// 모든 입력 경로에서 일관된 분석 결과를 제공
///
/// 분석 레벨:
/// - Level 0: OpenAI GPT API (최고 품질, 인터넷 필요, opt-in)
/// - Level 1: EnhancedContentAnalyzer (Apple Intelligence / Foundation Models)
/// - Level 2: OnDeviceLLM (NLP 휴리스틱)
/// - Level 3: DocumentParserService (규칙 기반)
/// - Level 4: MinimalAnalysis (최후 Fallback)
class UnifiedAnalysisService {
  // 성능 모니터링을 위한 통계 (Map 전체를 교체해 원자성 보장)
  static Map<String, int> _analysisStats = {
    'level0_success': 0,
    'level1_success': 0,
    'level2_success': 0,
    'level3_success': 0,
    'level4_fallback': 0,
    'total_analyses': 0,
    'level0_perm_error': 0,
  };

  /// Level 0 영구 오류 발생 여부 (잘못된 키 — 키 재설정 전까지 재시도 차단)
  static bool _openAIPermanentErrorOccurred = false;

  /// 429(rate limit) 발생 시 재시도를 미루는 시각 (지수적 확대)
  static DateTime? _openAICooldownUntil;
  static int _consecutiveRateLimits = 0;

  /// 분석 통계 조회 (스냅샷 반환)
  static Map<String, int> getAnalysisStats() => Map<String, int>.from(_analysisStats);

  /// 통계 초기화
  static void resetStats() {
    _analysisStats = {for (final k in _analysisStats.keys) k: 0};
    _openAIPermanentErrorOccurred = false;
    _openAICooldownUntil = null;
    _consecutiveRateLimits = 0;
  }

  /// Level 0 오류 상태 초기화 (설정에서 새 API 키 저장 시 호출)
  static void resetOpenAIError() {
    _openAIPermanentErrorOccurred = false;
    _openAICooldownUntil = null;
    _consecutiveRateLimits = 0;
    logInfo('🔄 OpenAI 오류 상태 초기화', name: 'UnifiedAnalysis');
  }

  /// 현재 Level 0 차단 여부 (영구 오류 또는 쿨다운 중)
  static bool get isOpenAIBlocked =>
      _openAIPermanentErrorOccurred ||
      (_openAICooldownUntil != null && DateTime.now().isBefore(_openAICooldownUntil!));

  static void _bumpStat(String key) {
    _analysisStats = {..._analysisStats, key: (_analysisStats[key] ?? 0) + 1};
  }

  /// 통합 분석 메인 API
  ///
  /// [blocks]: OCR 블록 리스트 (필수)
  /// [ocrText]: OCR 텍스트 (선택, blocks가 없을 때 사용)
  /// [suggestedCategory]: 제안된 카테고리 (선택)
  /// [imageSize]: 이미지 크기 (선택)
  /// [layoutRegions]: 레이아웃 영역 (선택)
  /// [importantAreas]: 중요 영역 (선택)
  /// [sourceType]: 'screenshot', 'url', 'photo' 등 (OpenAI 프롬프트용)
  /// [urlTitle]: URL 메타데이터 제목 (OpenAI 참고용)
  /// [urlDescription]: URL 메타데이터 설명 (OpenAI 참고용)
  /// [imagePath]: 원본 이미지 경로 — OpenAI Vision 분석에 사용 (opt-in 시)
  ///
  /// Returns: ScreenshotAnalysis 결과 (category/tags/contentType 포함)
  static Future<ScreenshotAnalysis> analyze({
    required List<OCRBlock>? blocks,
    String? ocrText,
    String? suggestedCategory,
    Map<dynamic, dynamic>? imageSize,
    List<dynamic>? layoutRegions,
    List<dynamic>? importantAreas,
    String sourceType = 'screenshot',
    String? urlTitle,
    String? urlDescription,
    String? imagePath,
  }) async {
    final stopwatch = Stopwatch()..start();
    _bumpStat('total_analyses');

    logInfo(
      '🚀 분석 시작 — OCR 블록: ${blocks?.length ?? 0}개, '
      '텍스트: ${ocrText?.length ?? 0}자, 제안 카테고리: $suggestedCategory, '
      '소스: $sourceType, 이미지: ${imagePath != null ? "있음" : "없음"}',
      name: 'UnifiedAnalysis',
    );

    // 입력 검증
    if (blocks == null || blocks.isEmpty) {
      if (ocrText == null || ocrText.isEmpty) {
        logWarn('입력 데이터 없음', name: 'UnifiedAnalysis');
        return ScreenshotAnalysis(
          title: 'Empty Capture',
          summary: 'No readable text found.',
          keyInsights: [],
          category: suggestedCategory,
        );
      }
      // OCR 텍스트만 있는 경우, 간단한 블록 생성
      blocks = _createBlocksFromText(ocrText);
    }

    // OCR 텍스트가 없으면 블록에서 생성
    ocrText ??= _generateOcrTextFromBlocks(blocks);

    // ============================================
    // Level 0: OpenAI GPT API (최고 품질)
    // ============================================
    final level0 = await _tryLevel0(
      ocrText: ocrText,
      sourceType: sourceType,
      urlTitle: urlTitle,
      urlDescription: urlDescription,
      imagePath: imagePath,
      stopwatch: stopwatch,
    );
    if (level0 != null) return level0;

    // ============================================
    // Level 1: EnhancedContentAnalyzer (Apple Intelligence)
    // ============================================
    try {
      logInfo('🔍 [Level 1] EnhancedContentAnalyzer 시도...', name: 'UnifiedAnalysis');

      final enhancedResult = await OnDeviceLLMService.analyzeSummaryEnhanced(
        blocks: blocks,
        layoutRegions: layoutRegions,
        importantAreas: importantAreas,
        imageSize: imageSize ?? {'width': 1000.0, 'height': 2000.0},
      );

      if (_isValidResult(enhancedResult)) {
        stopwatch.stop();
        _bumpStat('level1_success');
        logInfo(
          '✅ [Level 1] Enhanced 분석 성공: ${enhancedResult['title']} (${stopwatch.elapsedMilliseconds}ms)',
          name: 'UnifiedAnalysis',
        );
        final tags = List<String>.from(enhancedResult['tags'] ?? []);
        // 네이티브가 "insights"(문장형 핵심 포인트)를 별도로 반환한다.
        // 과거엔 이 필드가 전달되지 않아 짧은 tags를 keyInsights로 잘못 재사용했었다
        // (예: "네이버앱", "앱" 같은 UI 라벨이 핵심 포인트로 표시되는 버그).
        final insights = TextHeuristics.filterInsights(
          List<String>.from(enhancedResult['insights'] ?? enhancedResult['keyInsights'] ?? []),
        );
        return ScreenshotAnalysis(
          title: enhancedResult['title'] ?? 'New Memory',
          summary: enhancedResult['summary'] ?? '',
          keyInsights: insights,
          tags: _shortTags(tags, fallbackText: ocrText),
          category: _resolveCategory(suggestedCategory, ocrText),
          contentType: enhancedResult['contentType'] ?? 'general',
          analysisLevel: 1,
        );
      } else {
        logWarn('[Level 1] Enhanced 결과가 유효하지 않음', name: 'UnifiedAnalysis');
      }
    } catch (e, stackTrace) {
      logWarn('[Level 1] Enhanced 분석 실패: $e', name: 'UnifiedAnalysis');
      logError('Level 1 상세', name: 'UnifiedAnalysis', error: e, stackTrace: stackTrace);
    }

    // Level 2: OnDeviceLLM (중간 품질)
    try {
      logInfo('🔍 [Level 2] OnDeviceLLM 시도...', name: 'UnifiedAnalysis');

      final analysis = await OnDeviceLLMService.analyzeScreenshotLegacy(
        ocrText: ocrText,
        ocrBlocks: blocks,
      );

      if (_isValidAnalysis(analysis)) {
        stopwatch.stop();
        _bumpStat('level2_success');
        logInfo(
          '✅ [Level 2] OnDeviceLLM 분석 성공: ${analysis.title} (${stopwatch.elapsedMilliseconds}ms)',
          name: 'UnifiedAnalysis',
        );
        return _withDerivedMetadata(analysis, ocrText, suggestedCategory, level: 2);
      } else {
        logWarn('[Level 2] OnDeviceLLM 결과가 유효하지 않음', name: 'UnifiedAnalysis');
      }
    } catch (e, stackTrace) {
      logError('[Level 2] OnDeviceLLM 분석 실패: $e',
          name: 'UnifiedAnalysis', error: e, stackTrace: stackTrace);
    }

    // Level 3: DocumentParserService (기본 품질)
    try {
      logInfo('🔍 [Level 3] DocumentParserService 시도...', name: 'UnifiedAnalysis');

      final parsed = DocumentParserService.parseDocument(
        blocks,
        externalCategory: suggestedCategory,
      );

      if (_isValidAnalysis(parsed)) {
        stopwatch.stop();
        _bumpStat('level3_success');
        logInfo(
          '✅ [Level 3] DocumentParser 분석 성공: ${parsed.title} (${stopwatch.elapsedMilliseconds}ms)',
          name: 'UnifiedAnalysis',
        );
        return _withDerivedMetadata(parsed, ocrText, suggestedCategory, level: 3);
      } else {
        logWarn('[Level 3] DocumentParser 결과가 유효하지 않음', name: 'UnifiedAnalysis');
      }
    } catch (e, stackTrace) {
      logError('[Level 3] DocumentParser 분석 실패: $e',
          name: 'UnifiedAnalysis', error: e, stackTrace: stackTrace);
    }

    // Level 4: 최소한의 Fallback (최후의 수단)
    stopwatch.stop();
    _bumpStat('level4_fallback');
    logInfo('🔍 [Level 4] 최소한의 Fallback 생성 (${stopwatch.elapsedMilliseconds}ms)',
        name: 'UnifiedAnalysis');

    final result = _generateMinimalAnalysis(blocks, ocrText, suggestedCategory);
    logInfo(
      '📊 [통계] Level 0 (OpenAI): ${_analysisStats['level0_success']}, '
      'Level 1: ${_analysisStats['level1_success']}, '
      'Level 2: ${_analysisStats['level2_success']}, '
      'Level 3: ${_analysisStats['level3_success']}, '
      'Level 4: ${_analysisStats['level4_fallback']}',
      name: 'UnifiedAnalysis',
    );

    return result;
  }

  /// Level 0 (OpenAI) 시도. 성공 시 결과, 실패/차단 시 null.
  static Future<ScreenshotAnalysis?> _tryLevel0({
    required String ocrText,
    required String sourceType,
    String? urlTitle,
    String? urlDescription,
    String? imagePath,
    required Stopwatch stopwatch,
  }) async {
    if (_openAIPermanentErrorOccurred) {
      logInfo('⏭️ [Level 0] 영구오류 이력으로 스킵 (키 재설정 필요)', name: 'UnifiedAnalysis');
      return null;
    }
    if (_openAICooldownUntil != null) {
      if (DateTime.now().isBefore(_openAICooldownUntil!)) {
        logInfo('⏭️ [Level 0] rate limit 쿨다운 중 (${_openAICooldownUntil!.toIso8601String()}까지)',
            name: 'UnifiedAnalysis');
        return null;
      }
      _openAICooldownUntil = null; // 쿨다운 해제
    }

    try {
      final openaiAvailable = await OpenAIService.isAvailable();
      if (!openaiAvailable || ocrText.isEmpty) return null;

      logInfo('🔍 [Level 0] OpenAI GPT 시도...', name: 'UnifiedAnalysis');

      final openaiResult = await OpenAIService.analyze(
        ocrText: ocrText,
        sourceType: sourceType,
        urlTitle: urlTitle,
        urlDescription: urlDescription,
        imagePath: imagePath,
      );

      if (openaiResult.isValid) {
        stopwatch.stop();
        _bumpStat('level0_success');
        _consecutiveRateLimits = 0;
        logInfo(
          '✅ [Level 0] OpenAI 분석 성공: ${openaiResult.title} (${stopwatch.elapsedMilliseconds}ms)',
          name: 'UnifiedAnalysis',
        );
        return ScreenshotAnalysis(
          title: openaiResult.title,
          summary: openaiResult.summary,
          keyInsights: TextHeuristics.filterInsights(openaiResult.keyInsights),
          tags: openaiResult.tags,
          category: openaiResult.category,
          contentType: openaiResult.contentType,
          analysisLevel: 0,
        );
      }
      logWarn('[Level 0] OpenAI 결과가 유효하지 않음', name: 'UnifiedAnalysis');
      return null;
    } on OpenAIException catch (e) {
      if (e.isPermanent) {
        _openAIPermanentErrorOccurred = true;
        _bumpStat('level0_perm_error');
        logError('🚫 [Level 0] 영구오류 — 키 재설정 전까지 Level 0 비활성화: $e',
            name: 'UnifiedAnalysis', error: e);
      } else if (e.isRateLimited) {
        // 지수 백오프: 1분 → 2분 → 4분 ... 최대 30분
        _consecutiveRateLimits++;
        final minutes = (1 << (_consecutiveRateLimits - 1)).clamp(1, 30);
        _openAICooldownUntil = DateTime.now().add(Duration(minutes: minutes));
        logWarn('[Level 0] rate limit — $minutes분 후 재시도', name: 'UnifiedAnalysis');
      } else {
        logWarn('[Level 0] 일시오류 (다음 분석 시 재시도): $e', name: 'UnifiedAnalysis');
      }
      return null;
    } catch (e, stackTrace) {
      logWarn('[Level 0] 일시오류 (다음 분석 시 재시도): $e', name: 'UnifiedAnalysis');
      logError('Level 0 상세', name: 'UnifiedAnalysis', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 온디바이스 분석 결과에 카테고리/태그 메타데이터 보강
  static ScreenshotAnalysis _withDerivedMetadata(
    ScreenshotAnalysis analysis,
    String ocrText,
    String? suggestedCategory, {
    required int level,
  }) {
    return ScreenshotAnalysis(
      title: analysis.title,
      summary: analysis.summary,
      keyInsights: TextHeuristics.filterInsights(analysis.keyInsights),
      tags: analysis.tags.isNotEmpty
          ? analysis.tags
          : _shortTags(analysis.keyInsights, fallbackText: ocrText),
      category: analysis.category ?? _resolveCategory(suggestedCategory, ocrText),
      contentType: analysis.contentType,
      analysisLevel: level,
    );
  }

  /// 제안 카테고리가 유효하면 사용, 아니면 텍스트에서 추정
  static String _resolveCategory(String? suggested, String text) {
    if (suggested != null &&
        suggested.isNotEmpty &&
        suggested != 'Inbox' &&
        TextHeuristics.validCategories.contains(suggested)) {
      return suggested;
    }
    return TextHeuristics.detectCategory(text);
  }

  /// 긴 문장(keyInsights)이 태그로 흘러들지 않도록 짧은 키워드만 추출
  static List<String> _shortTags(List<String> candidates, {required String fallbackText}) {
    final tags = candidates
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && t.length <= 12 && !t.contains(' '))
        .take(5)
        .toList();
    if (tags.isNotEmpty) return tags;
    return TextHeuristics.extractTags(fallbackText);
  }

  /// 결과가 유효한지 확인
  static bool _isValidResult(Map<String, dynamic> result) {
    final title = result['title']?.toString() ?? '';
    final summary = result['summary']?.toString() ?? '';
    return _isUsableTitleSummary(title, summary);
  }

  /// 분석 결과가 유효한지 확인
  static bool _isValidAnalysis(ScreenshotAnalysis analysis) {
    return _isUsableTitleSummary(analysis.title, analysis.summary);
  }

  /// 제목·요약이 사용자에게 보여줄 만한 품질인지 검증.
  /// 저품질이면 false를 반환해 다음 레벨로 fallback이 이어지게 한다.
  static bool _isUsableTitleSummary(String title, String summary) {
    final t = title.trim();
    final s = summary.trim();
    if (t.isEmpty || s.isEmpty) return false;
    if (TextHeuristics.isLowQualityTitle(t)) return false;
    if (s.length < 15) return false;
    // 요약이 제목의 단순 반복이면 무의미
    if (s == t || (s.length < t.length + 10 && s.contains(t))) return false;
    return true;
  }

  /// OCR 텍스트에서 간단한 블록 생성 (구조 힌트 포함)
  static List<OCRBlock> _createBlocksFromText(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final blocks = <OCRBlock>[];

    double currentTop = 0.05;

    for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        final isTopArea = i < 3; // Check first 3 lines

        // 제목 후보 휴리스틱: 상단에 위치하고, 길이가 적당하며, 문장 부호로 끝나지 않음
        // (SNS 게시글의 경우 첫 줄이 작성자일 수 있으므로 2-3번째 줄도 허용)
        final isTitleCandidate = isTopArea &&
            line.length > 3 && line.length < 80 &&
            !line.endsWith('.') && !line.endsWith('?') &&
            !line.startsWith('@'); // Handle is unlikely to be main title

        double height = isTitleCandidate ? 0.08 : 0.04; // 제목이면 2배 크기 힌트

        // 제목일 가능성이 높으면(키워드 포함) 더 큰 힌트 부여
        if (isTitleCandidate && (line.contains('TOP') || line.contains('Insight') || line.contains('요약'))) {
            height = 0.10;
        }

        blocks.add(OCRBlock(
            text: line,
            boundingBox: BoundingBox(
                top: currentTop,
                left: 0.1,
                width: 0.8,
                height: height,
            ),
            confidence: 0.95, // 인위적으로 높은 신뢰도 부여
        ));

        // 다음 블록 위치 계산
        currentTop += height + (isTitleCandidate ? 0.04 : 0.015);
    }

    return blocks;
  }

  /// 블록에서 OCR 텍스트 생성
  static String _generateOcrTextFromBlocks(List<OCRBlock> blocks) {
    return blocks.map((b) => b.text).join('\n');
  }

  /// 최소한의 Fallback 분석 생성
  static ScreenshotAnalysis _generateMinimalAnalysis(
    List<OCRBlock> blocks,
    String? ocrText,
    String? suggestedCategory,
  ) {
    // 필터링된 블록에서 의미있는 텍스트 추출
    final cleanedBlocks = OnDeviceLLMService.filterUINoiseBlocksPublic(blocks);

    String title = 'Screen Capture';
    String summary = '';
    List<String> keyInsights = [];

    if (cleanedBlocks.isNotEmpty) {
      // 제목: 상단 블록을 크기순으로 훑으며 UI 노이즈가 아닌 첫 후보 선택
      final topBlocks = cleanedBlocks.where((b) => b.boundingBox.top < 0.3).toList()
        ..sort((a, b) => b.boundingBox.height.compareTo(a.boundingBox.height));
      for (final block in topBlocks) {
        final candidate = block.text.trim();
        if (candidate.length >= 5 &&
            candidate.length <= 80 &&
            !TextHeuristics.isLowQualityTitle(candidate)) {
          title = candidate;
          break;
        }
      }

      // 요약: 문단 구성 후 문장 중요도 기반 추출 (단순 앞부분 자르기 대체)
      final paragraphs = <String>[];
      String currentPara = '';
      double lastBottom = 0;

      for (final block in cleanedBlocks) {
        final gap = block.boundingBox.top - lastBottom;
        if (lastBottom > 0 && gap > 0.04 && currentPara.isNotEmpty) {
          paragraphs.add(currentPara.trim());
          currentPara = '';
        }
        currentPara += '${block.text.trim()} ';
        lastBottom = block.boundingBox.bottom;
      }
      if (currentPara.isNotEmpty) paragraphs.add(currentPara.trim());

      summary = TextHeuristics.summarizeByImportance(paragraphs.join('\n'));
      if (summary.isEmpty) {
        final selected = paragraphs.take(3).join(' ').trim();
        summary = selected.length > 150
          ? '${selected.substring(0, 147)}...'
          : selected;
      }

      // 키 인사이트: 적절한 길이의 문단
      keyInsights = paragraphs
        .where((p) => p.length >= 10 && p.length <= 100)
        .take(3)
        .toList();
    } else if (ocrText != null && ocrText.isNotEmpty) {
      // OCR 텍스트가 있으면 문장 중요도 기반 요약 사용
      summary = TextHeuristics.summarizeByImportance(ocrText);
      if (summary.isEmpty) {
        summary = ocrText.length > 150
          ? '${ocrText.substring(0, 147)}...'
          : ocrText;
      }

      // 첫 줄 중 저품질(UI 노이즈)이 아닌 줄을 제목으로
      final lines = ocrText.split('\n').where((l) => l.trim().isNotEmpty).toList();
      for (final line in lines.take(5)) {
        final t = line.trim();
        if (t.length >= 5 && t.length <= 80 && !TextHeuristics.isLowQualityTitle(t)) {
          title = t;
          break;
        }
      }
    } else {
      summary = '텍스트 내용이 감지되었습니다.';
    }

    final text = ocrText ?? '';
    logInfo('✅ [Level 4] 최소한의 분석 생성: $title', name: 'UnifiedAnalysis');
    return ScreenshotAnalysis(
      title: title,
      summary: summary,
      keyInsights: TextHeuristics.filterInsights(keyInsights),
      tags: TextHeuristics.extractTags(text.isNotEmpty ? text : summary),
      category: _resolveCategory(suggestedCategory, text.isNotEmpty ? text : summary),
      analysisLevel: 4,
    );
  }
}
