import 'dart:developer' as developer;
import 'package:stribe/services/ondevice_llm_service.dart';
import 'package:stribe/services/document_parser_service.dart';

/// 통합 분석 서비스
/// 모든 입력 경로에서 일관된 분석 결과를 제공
/// 
/// 성능 최적화:
/// - 중복 분석 방지
/// - 결과 캐싱 (향후 구현)
/// - 단계적 Fallback으로 빠른 실패 처리
class UnifiedAnalysisService {
  // 성능 모니터링을 위한 통계
  static final Map<String, int> _analysisStats = {
    'level1_success': 0,
    'level2_success': 0,
    'level3_success': 0,
    'level4_fallback': 0,
    'total_analyses': 0,
  };
  
  /// 분석 통계 조회
  static Map<String, int> getAnalysisStats() => Map<String, int>.from(_analysisStats);
  
  /// 통계 초기화
  static void resetStats() {
    _analysisStats.updateAll((key, value) => 0);
  }
  /// 통합 분석 메인 API
  /// 
  /// [blocks]: OCR 블록 리스트 (필수)
  /// [ocrText]: OCR 텍스트 (선택, blocks가 없을 때 사용)
  /// [suggestedCategory]: 제안된 카테고리 (선택)
  /// [imageSize]: 이미지 크기 (선택)
  /// [layoutRegions]: 레이아웃 영역 (선택)
  /// [importantAreas]: 중요 영역 (선택)
  /// 
  /// Returns: ScreenshotAnalysis 결과
  static Future<ScreenshotAnalysis> analyze({
    required List<OCRBlock>? blocks,
    String? ocrText,
    String? suggestedCategory,
    Map<dynamic, dynamic>? imageSize,
    List<dynamic>? layoutRegions,
    List<dynamic>? importantAreas,
  }) async {
    final stopwatch = Stopwatch()..start();
    _analysisStats['total_analyses'] = (_analysisStats['total_analyses'] ?? 0) + 1;
    
    developer.log(
      '🚀 [UnifiedAnalysis] 분석 시작',
      name: 'UnifiedAnalysis',
      error: null,
    );
    developer.log(
      '   - OCR 블록: ${blocks?.length ?? 0}개\n'
      '   - OCR 텍스트 길이: ${ocrText?.length ?? 0}\n'
      '   - 제안 카테고리: $suggestedCategory',
      name: 'UnifiedAnalysis',
    );
    
    // 입력 검증
    if (blocks == null || blocks.isEmpty) {
      if (ocrText == null || ocrText.isEmpty) {
        print('⚠️ [UnifiedAnalysis] 입력 데이터 없음');
        return ScreenshotAnalysis(
          title: 'Empty Capture',
          summary: 'No readable text found.',
          keyInsights: [],
        );
      }
      // OCR 텍스트만 있는 경우, 간단한 블록 생성
      blocks = _createBlocksFromText(ocrText);
    }
    
    // 단계적 Fallback 전략
    // Level 1: EnhancedContentAnalyzer (최고 품질)
    try {
      print('🔍 [Level 1] EnhancedContentAnalyzer 시도...');
      
      final enhancedResult = await OnDeviceLLMService.analyzeSummaryEnhanced(
        blocks: blocks,
        layoutRegions: layoutRegions,
        importantAreas: importantAreas,
        imageSize: imageSize ?? {'width': 1000.0, 'height': 2000.0},
      );
      
      if (_isValidResult(enhancedResult)) {
        stopwatch.stop();
        _analysisStats['level1_success'] = (_analysisStats['level1_success'] ?? 0) + 1;
        developer.log(
          '✅ [Level 1] Enhanced 분석 성공: ${enhancedResult['title']} (${stopwatch.elapsedMilliseconds}ms)',
          name: 'UnifiedAnalysis',
        );
        return ScreenshotAnalysis(
          title: enhancedResult['title'] ?? 'New Memory',
          summary: enhancedResult['summary'] ?? '',
          keyInsights: List<String>.from(enhancedResult['tags'] ?? []),
        );
      } else {
        developer.log('⚠️ [Level 1] Enhanced 결과가 유효하지 않음', name: 'UnifiedAnalysis');
      }
    } catch (e, stackTrace) {
      developer.log(
        '⚠️ [Level 1] Enhanced 분석 실패: $e',
        name: 'UnifiedAnalysis',
        error: e,
        stackTrace: stackTrace,
      );
    }
    
    // Level 2: OnDeviceLLM (중간 품질)
    try {
      print('🔍 [Level 2] OnDeviceLLM 시도...');
      
      final analysis = await OnDeviceLLMService.analyzeScreenshotLegacy(
        ocrText: ocrText ?? _generateOcrTextFromBlocks(blocks),
        ocrBlocks: blocks,
      );
      
      if (_isValidAnalysis(analysis)) {
        stopwatch.stop();
        _analysisStats['level2_success'] = (_analysisStats['level2_success'] ?? 0) + 1;
        developer.log(
          '✅ [Level 2] OnDeviceLLM 분석 성공: ${analysis.title} (${stopwatch.elapsedMilliseconds}ms)',
          name: 'UnifiedAnalysis',
        );
        return analysis;
      } else {
        developer.log('⚠️ [Level 2] OnDeviceLLM 결과가 유효하지 않음', name: 'UnifiedAnalysis');
      }
    } catch (e, stackTrace) {
      developer.log(
        '⚠️ [Level 2] OnDeviceLLM 분석 실패: $e',
        name: 'UnifiedAnalysis',
        error: e,
        stackTrace: stackTrace,
      );
    }
    
    // Level 3: DocumentParserService (기본 품질)
    try {
      print('🔍 [Level 3] DocumentParserService 시도...');
      
      final parsed = DocumentParserService.parseDocument(
        blocks,
        externalCategory: suggestedCategory,
      );
      
      if (_isValidAnalysis(parsed)) {
        stopwatch.stop();
        _analysisStats['level3_success'] = (_analysisStats['level3_success'] ?? 0) + 1;
        developer.log(
          '✅ [Level 3] DocumentParser 분석 성공: ${parsed.title} (${stopwatch.elapsedMilliseconds}ms)',
          name: 'UnifiedAnalysis',
        );
        return parsed;
      } else {
        developer.log('⚠️ [Level 3] DocumentParser 결과가 유효하지 않음', name: 'UnifiedAnalysis');
      }
    } catch (e, stackTrace) {
      developer.log(
        '⚠️ [Level 3] DocumentParser 분석 실패: $e',
        name: 'UnifiedAnalysis',
        error: e,
        stackTrace: stackTrace,
      );
    }
    
    // Level 4: 최소한의 Fallback (최후의 수단)
    stopwatch.stop();
    _analysisStats['level4_fallback'] = (_analysisStats['level4_fallback'] ?? 0) + 1;
    developer.log(
      '🔍 [Level 4] 최소한의 Fallback 생성 (${stopwatch.elapsedMilliseconds}ms)',
      name: 'UnifiedAnalysis',
    );
    
    final result = _generateMinimalAnalysis(blocks, ocrText);
    developer.log(
      '📊 [통계] Level 1: ${_analysisStats['level1_success']}, '
      'Level 2: ${_analysisStats['level2_success']}, '
      'Level 3: ${_analysisStats['level3_success']}, '
      'Level 4: ${_analysisStats['level4_fallback']}',
      name: 'UnifiedAnalysis',
    );
    
    return result;
  }
  
  /// 결과가 유효한지 확인
  static bool _isValidResult(Map<String, dynamic> result) {
    final title = result['title']?.toString() ?? '';
    final summary = result['summary']?.toString() ?? '';
    
    return title.isNotEmpty && 
           title != '제목 없음' && 
           title != 'New Memory' &&
           summary.isNotEmpty;
  }
  
  /// 분석 결과가 유효한지 확인
  static bool _isValidAnalysis(ScreenshotAnalysis analysis) {
    return analysis.title.isNotEmpty && 
           analysis.title != 'New Memory' &&
           analysis.title != 'Empty Capture' &&
           analysis.summary.isNotEmpty;
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
  ) {
    // 필터링된 블록에서 의미있는 텍스트 추출
    final cleanedBlocks = OnDeviceLLMService.filterUINoiseBlocksPublic(blocks);
    
    String title = 'Screen Capture';
    String summary = '';
    List<String> keyInsights = [];
    
    if (cleanedBlocks.isNotEmpty) {
      // 제목: 상단 블록 중 가장 큰 텍스트
      final topBlocks = cleanedBlocks.where((b) => b.boundingBox.top < 0.3).toList();
      if (topBlocks.isNotEmpty) {
        topBlocks.sort((a, b) => b.boundingBox.height.compareTo(a.boundingBox.height));
        final candidate = topBlocks.first.text.trim();
        if (candidate.length >= 5 && candidate.length <= 80) {
          title = candidate;
        }
      }
      
      // 요약: 처음 2-3개 문단을 의미있게 조합
      final paragraphs = <String>[];
      String currentPara = '';
      double lastBottom = 0;
      
      for (final block in cleanedBlocks) {
        final gap = block.boundingBox.top - lastBottom;
        if (lastBottom > 0 && gap > 0.04 && currentPara.isNotEmpty) {
          paragraphs.add(currentPara);
          currentPara = '';
        }
        currentPara += '${block.text.trim()} ';
        lastBottom = block.boundingBox.bottom;
      }
      if (currentPara.isNotEmpty) paragraphs.add(currentPara);
      
      // 상위 3개 문단 선택
      final selected = paragraphs.take(3).join(' ').trim();
      summary = selected.length > 150 
        ? '${selected.substring(0, 147)}...' 
        : selected;
      
      // 키 인사이트: 적절한 길이의 문단
      keyInsights = paragraphs
        .where((p) => p.length >= 10 && p.length <= 100)
        .take(3)
        .toList();
    } else if (ocrText != null && ocrText.isNotEmpty) {
      // OCR 텍스트가 있으면 사용
      summary = ocrText.length > 150 
        ? '${ocrText.substring(0, 147)}...' 
        : ocrText;
      
      // 첫 줄을 제목으로
      final lines = ocrText.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isNotEmpty) {
        final firstLine = lines.first.trim();
        if (firstLine.length >= 5 && firstLine.length <= 80) {
          title = firstLine;
        }
      }
    } else {
      summary = '텍스트 내용이 감지되었습니다.';
    }
    
    developer.log('✅ [Level 4] 최소한의 분석 생성: $title', name: 'UnifiedAnalysis');
    return ScreenshotAnalysis(
      title: title,
      summary: summary,
      keyInsights: keyInsights,
    );
  }
}
