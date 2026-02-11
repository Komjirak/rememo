import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// OpenAI API 서비스
/// 
/// 스크린샷/URL의 OCR 텍스트를 GPT-4o-mini로 분석하여
/// 고품질 제목, 요약, 태그, 카테고리를 생성합니다.
/// 
/// 기존 온디바이스 분석 파이프라인의 Level 0로 동작:
/// Level 0 (OpenAI) → Level 1 (EnhancedContentAnalyzer) → Level 2 (OnDeviceLLM) → ...
class OpenAIService {
  static const String _apiKeyPrefKey = 'openai_api_key';
  static const String _modelPrefKey = 'openai_model';
  static const String _enabledPrefKey = 'openai_enabled';
  
  // 기본 모델 설정
  static const String defaultModel = 'gpt-4o-mini';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  // 사용 가능한 모델 목록
  static const List<Map<String, String>> availableModels = [
    {'id': 'gpt-4o-mini', 'name': 'GPT-4o Mini', 'description': '빠르고 저렴 (추천)'},
    {'id': 'gpt-4o', 'name': 'GPT-4o', 'description': '최고 품질, 비용 높음'},
    {'id': 'gpt-4.1-mini', 'name': 'GPT-4.1 Mini', 'description': '최신 경량 모델'},
    {'id': 'gpt-4.1-nano', 'name': 'GPT-4.1 Nano', 'description': '가장 저렴'},
  ];
  
  // 캐싱된 설정값
  static String? _cachedApiKey;
  static String? _cachedModel;
  static bool? _cachedEnabled;
  
  // ============================================
  // API Key 관리
  // ============================================
  
  /// API Key 저장
  static Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, apiKey);
    _cachedApiKey = apiKey;
    developer.log('✅ [OpenAI] API Key 저장완료', name: 'OpenAI');
  }
  
  /// API Key 가져오기
  static Future<String?> getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;
    final prefs = await SharedPreferences.getInstance();
    _cachedApiKey = prefs.getString(_apiKeyPrefKey);
    return _cachedApiKey;
  }
  
  /// API Key 삭제
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefKey);
    _cachedApiKey = null;
    developer.log('🗑️ [OpenAI] API Key 삭제완료', name: 'OpenAI');
  }
  
  /// API Key가 설정되어 있는지 확인
  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty && key.startsWith('sk-');
  }
  
  /// 모델 설정
  static Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPrefKey, model);
    _cachedModel = model;
  }
  
  /// 현재 모델 가져오기
  static Future<String> getModel() async {
    if (_cachedModel != null) return _cachedModel!;
    final prefs = await SharedPreferences.getInstance();
    _cachedModel = prefs.getString(_modelPrefKey) ?? defaultModel;
    return _cachedModel!;
  }
  
  /// OpenAI 사용 활성화/비활성화
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledPrefKey, enabled);
    _cachedEnabled = enabled;
    developer.log(
      '${enabled ? "✅" : "⏸️"} [OpenAI] ${enabled ? "활성화" : "비활성화"}',
      name: 'OpenAI',
    );
  }
  
  /// OpenAI 사용 활성화 여부 확인
  static Future<bool> isEnabled() async {
    if (_cachedEnabled != null) return _cachedEnabled!;
    final prefs = await SharedPreferences.getInstance();
    _cachedEnabled = prefs.getBool(_enabledPrefKey) ?? true;
    return _cachedEnabled!;
  }
  
  /// OpenAI를 사용할 수 있는 상태인지 확인 (Key 존재 + 활성화)
  static Future<bool> isAvailable() async {
    final enabled = await isEnabled();
    if (!enabled) return false;
    return await hasApiKey();
  }
  
  // ============================================
  // 분석 API
  // ============================================
  
  /// OCR 텍스트를 분석하여 제목, 요약, 태그, 카테고리를 생성
  /// 
  /// [ocrText]: OCR로 추출된 텍스트
  /// [sourceType]: 'screenshot', 'url', 'photo' 등
  /// [urlTitle]: URL의 경우 메타데이터 제목
  /// [urlDescription]: URL의 경우 메타데이터 설명
  static Future<OpenAIAnalysisResult> analyze({
    required String ocrText,
    String sourceType = 'screenshot',
    String? urlTitle,
    String? urlDescription,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw OpenAIException('API Key가 설정되지 않았습니다.');
    }
    
    final model = await getModel();
    
    // 텍스트 길이 제한 (토큰 절약)
    final truncatedText = _truncateText(ocrText, maxLength: 3000);
    
    // 프롬프트 구성
    final systemPrompt = _buildSystemPrompt(sourceType);
    final userPrompt = _buildUserPrompt(
      ocrText: truncatedText,
      sourceType: sourceType,
      urlTitle: urlTitle,
      urlDescription: urlDescription,
    );
    
    developer.log(
      '🚀 [OpenAI] 분석 시작\n'
      '   - 모델: $model\n'
      '   - 소스: $sourceType\n'
      '   - 텍스트 길이: ${truncatedText.length}자',
      name: 'OpenAI',
    );
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.3,
          'max_tokens': 500,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw OpenAIException('요청 시간이 초과되었습니다 (30초).'),
      );
      
      stopwatch.stop();
      
      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? 'HTTP ${response.statusCode}';
        developer.log('❌ [OpenAI] API 오류: $errorMsg', name: 'OpenAI');
        throw OpenAIException('OpenAI API 오류: $errorMsg');
      }
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      // 응답 파싱
      final choices = responseBody['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw OpenAIException('OpenAI 응답이 비어있습니다.');
      }
      
      final content = choices[0]['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      
      final result = OpenAIAnalysisResult(
        title: parsed['title'] as String? ?? 'New Memory',
        summary: parsed['summary'] as String? ?? '',
        tags: List<String>.from(parsed['tags'] ?? []),
        category: _normalizeCategory(parsed['category'] as String? ?? 'Inbox'),
        keyInsights: List<String>.from(parsed['keyInsights'] ?? []),
        contentType: parsed['contentType'] as String? ?? 'general',
      );
      
      // 사용량 로깅
      final usage = responseBody['usage'];
      if (usage != null) {
        developer.log(
          '✅ [OpenAI] 분석 완료 (${stopwatch.elapsedMilliseconds}ms)\n'
          '   - 제목: ${result.title}\n'
          '   - 요약: ${result.summary.length}자\n'
          '   - 태그: ${result.tags.join(", ")}\n'
          '   - 카테고리: ${result.category}\n'
          '   - 콘텐츠 타입: ${result.contentType}\n'
          '   - 토큰: prompt=${usage['prompt_tokens']}, '
          'completion=${usage['completion_tokens']}, '
          'total=${usage['total_tokens']}',
          name: 'OpenAI',
        );
      }
      
      return result;
      
    } catch (e) {
      stopwatch.stop();
      if (e is OpenAIException) rethrow;
      developer.log(
        '❌ [OpenAI] 분석 실패 (${stopwatch.elapsedMilliseconds}ms): $e',
        name: 'OpenAI',
      );
      throw OpenAIException('OpenAI 분석 실패: $e');
    }
  }
  
  /// API Key 유효성 테스트 (최소 토큰 사용)
  static Future<bool> testApiKey(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': 'Hi'},
          ],
          'max_tokens': 5,
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      developer.log('❌ [OpenAI] API Key 테스트 실패: $e', name: 'OpenAI');
      return false;
    }
  }
  
  // ============================================
  // 프롬프트 엔지니어링
  // ============================================
  
  /// 시스템 프롬프트 생성 (소스 타입별 최적화)
  static String _buildSystemPrompt(String sourceType) {
    String contextHint;
    switch (sourceType) {
      case 'screenshot':
        contextHint = '''The text was extracted via OCR from a mobile screen capture.
IGNORE all UI noise: status bar (time, battery, wifi), navigation buttons (back, home, share, menu), 
tab bars, keyboard elements, app headers, and action buttons.
Focus ONLY on the actual content the user wanted to capture.''';
        break;
      case 'url':
      case 'link':
        contextHint = '''The text was extracted from a web page the user saved.
IGNORE navigation menus, ads, cookie notices, sidebar content, footer links, and social share buttons.
Focus on the main article or page content that the user intended to save.''';
        break;
      case 'photo':
        contextHint = '''The text was extracted via OCR from a photo taken by the user.
This could be a document, sign, menu, receipt, business card, whiteboard, poster, or any real-world text.
Identify what type of real-world content this is and analyze accordingly.''';
        break;
      default:
        contextHint = 'The text was shared or captured by the user for later reference.';
    }

    return '''You are an AI assistant for "Rememo", a personal knowledge management app.
Users save screenshots, web pages, and photos to remember important information for later.

Your job: Analyze the captured text and explain what this content IS and WHY it matters to the user.

$contextHint

═══════════════════════════════════════
FIELD RULES
═══════════════════════════════════════

1. **title** (max 50 characters)
   - A clear, specific title that identifies the content at a glance
   - ❌ BAD: "스크린샷", "웹 페이지", "Screenshot", "New Memory"
   - ✅ GOOD: "강남역 이탈리안 맛집 후기", "Flutter 상태관리 비교", "나이키 에어맥스 할인 정보"

2. **summary** (2-3 sentences, user-centric)
   - Explain WHAT this content is and WHY the user would want to recall it later
   - Write as if briefing the user: "이 내용은 ~에 대한 것으로, ~할 때 참고하면 좋습니다"
   - Include the most important details (prices, dates, key facts, conclusions)
   
   Examples by content type:
   - 🍽️ Restaurant: "강남역 근처 이탈리안 레스토랑 '라쿠치나'의 후기입니다. 파스타와 피자가 맛있다는 평이 많고, 런치 세트가 15,000원으로 가성비가 좋습니다."
   - 🛍️ Shopping: "나이키 에어맥스 90이 30% 할인 중인 정보입니다. 할인 기간은 2월 말까지이며, 사이즈별 재고를 확인하고 구매를 고려해볼 만합니다."
   - 📰 Article: "React와 Vue.js의 성능을 비교한 기술 블로그입니다. 대규모 앱에서는 React가, 소규모 프로젝트에서는 Vue가 유리하다는 결론입니다."
   - 💼 Work: "다음 주 수요일 오후 2시 팀 미팅 일정입니다. Q1 실적 리뷰와 Q2 계획 논의가 주요 안건입니다."
   - 📋 Recipe: "토마토 파스타 레시피입니다. 재료는 마늘, 올리브유, 토마토소스, 파르메산 치즈가 필요하며, 조리 시간은 약 20분입니다."

3. **tags** (2-5 SHORT keywords for filtering)
   - Each tag MUST be 1-2 words maximum
   - Tags are used for search and filtering, so make them concise and reusable
   - ❌ BAD: "맛있는 이탈리안 레스토랑 후기", "React와 Vue 성능 비교 분석"
   - ✅ GOOD: "맛집", "이탈리안", "강남", "런치"
   - ✅ GOOD: "React", "Vue", "성능비교", "프론트엔드"
   - ✅ GOOD: "할인", "나이키", "운동화", "세일"
   - ✅ GOOD: "레시피", "파스타", "이탈리안", "간편식"

4. **category** (exactly one of these):
   Design, Tech, Food, Shopping, Work, Inspiration, Web, Personal, Inbox

5. **keyInsights** (2-4 specific, actionable takeaways)
   - Each insight should be a concise but complete point (1 sentence)
   - Focus on facts, numbers, dates, prices, or actionable information
   - ❌ BAD: "좋은 내용입니다", "참고하세요"
   - ✅ GOOD: "런치 세트 15,000원 (11:30-14:00)", "할인 마감 2월 28일", "React는 대규모 앱에 유리"

6. **contentType** (exactly one of these):
   news, article, blog, restaurant, place, product, education, social, general

═══════════════════════════════════════
LANGUAGE RULE
═══════════════════════════════════════
Always respond in the SAME LANGUAGE as the input text.
Korean input → Korean response / English input → English response / Mixed → dominant language

═══════════════════════════════════════
OUTPUT FORMAT
═══════════════════════════════════════
Respond ONLY with a valid JSON object:
{
  "title": "...",
  "summary": "...",
  "tags": ["...", "..."],
  "category": "...",
  "keyInsights": ["...", "..."],
  "contentType": "..."
}''';
  }
  
  /// 사용자 프롬프트 생성
  static String _buildUserPrompt({
    required String ocrText,
    required String sourceType,
    String? urlTitle,
    String? urlDescription,
  }) {
    final buffer = StringBuffer();
    
    // 소스 타입에 따른 컨텍스트 제공
    switch (sourceType) {
      case 'screenshot':
        buffer.writeln('[Source]: 모바일 스크린샷 (OCR 추출)');
        break;
      case 'url':
      case 'link':
        buffer.writeln('[Source]: 웹 페이지');
        break;
      case 'photo':
        buffer.writeln('[Source]: 사진 촬영 (OCR 추출)');
        break;
      default:
        buffer.writeln('[Source]: 공유된 콘텐츠');
    }
    
    if (urlTitle != null && urlTitle.isNotEmpty) {
      buffer.writeln('[Page Title]: $urlTitle');
    }
    if (urlDescription != null && urlDescription.isNotEmpty) {
      buffer.writeln('[Page Description]: $urlDescription');
    }
    
    buffer.writeln('');
    buffer.writeln('[Extracted Text]:');
    buffer.writeln(ocrText);
    
    return buffer.toString();
  }
  
  /// 텍스트 길이 제한 (토큰 절약)
  static String _truncateText(String text, {int maxLength = 3000}) {
    if (text.length <= maxLength) return text;
    
    // 문장 단위로 자르기 시도
    final truncated = text.substring(0, maxLength);
    final lastSentenceEnd = truncated.lastIndexOf(RegExp(r'[.!?。！？\n]'));
    
    if (lastSentenceEnd > maxLength * 0.7) {
      return truncated.substring(0, lastSentenceEnd + 1);
    }
    
    return '$truncated...';
  }
  
  /// 카테고리 정규화
  static String _normalizeCategory(String category) {
    const validCategories = [
      'Design', 'Tech', 'Food', 'Shopping', 'Work',
      'Inspiration', 'Web', 'Personal', 'Inbox',
    ];
    
    // 정확한 매치
    for (final valid in validCategories) {
      if (category.toLowerCase() == valid.toLowerCase()) {
        return valid;
      }
    }
    
    // 부분 매치
    final lower = category.toLowerCase();
    if (lower.contains('design') || lower.contains('디자인')) return 'Design';
    if (lower.contains('tech') || lower.contains('개발') || lower.contains('코드')) return 'Tech';
    if (lower.contains('food') || lower.contains('음식') || lower.contains('맛집')) return 'Food';
    if (lower.contains('shop') || lower.contains('쇼핑') || lower.contains('구매')) return 'Shopping';
    if (lower.contains('work') || lower.contains('업무') || lower.contains('회의')) return 'Work';
    if (lower.contains('inspir') || lower.contains('영감')) return 'Inspiration';
    if (lower.contains('web') || lower.contains('웹')) return 'Web';
    if (lower.contains('personal') || lower.contains('개인')) return 'Personal';
    
    return 'Inbox';
  }
}


// ============================================
// 데이터 모델
// ============================================

/// OpenAI 분석 결과
class OpenAIAnalysisResult {
  final String title;
  final String summary;
  final List<String> tags;
  final String category;
  final List<String> keyInsights;
  final String contentType;
  
  OpenAIAnalysisResult({
    required this.title,
    required this.summary,
    required this.tags,
    required this.category,
    required this.keyInsights,
    required this.contentType,
  });
  
  /// 유효한 결과인지 확인
  bool get isValid =>
      title.isNotEmpty &&
      title != 'New Memory' &&
      summary.isNotEmpty;
  
  @override
  String toString() {
    return 'OpenAIAnalysisResult(\n'
        '  title: $title,\n'
        '  summary: ${summary.length}chars,\n'
        '  tags: $tags,\n'
        '  category: $category,\n'
        '  contentType: $contentType\n'
        ')';
  }
}

/// OpenAI 관련 예외
class OpenAIException implements Exception {
  final String message;
  
  OpenAIException(this.message);
  
  @override
  String toString() => 'OpenAIException: $message';
}
