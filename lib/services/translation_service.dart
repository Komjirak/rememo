import 'dart:ui';
import 'package:stribe/utils/app_logger.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

/// MLKit 기반 온디바이스 번역 서비스
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  OnDeviceTranslator? _translator;

  String? _cachedSourceLang;
  String? _cachedTargetLang;

  /// 시스템 언어 가져오기 (예: "ko", "en", "ja")
  String getSystemLanguage() {
    final locale = PlatformDispatcher.instance.locale;
    return locale.languageCode;
  }

  /// 텍스트 언어 감지
  Future<String?> detectLanguage(String text) async {
    if (text.trim().isEmpty) return null;

    try {
      final language = await _languageIdentifier.identifyLanguage(text);
      logInfo('[TranslationService] Detected language: $language', name: 'Translation');
      return language == 'und' ? null : language;
    } catch (e) {
      logInfo('[TranslationService] Language detection error: $e', name: 'Translation');
      return null;
    }
  }

  /// 번역 필요 여부 확인
  Future<bool> needsTranslation(String text) async {
    final detectedLang = await detectLanguage(text);
    if (detectedLang == null) return false;

    final systemLang = getSystemLanguage();
    final needs = detectedLang != systemLang;

    logInfo('[TranslationService] Needs translation: $needs (detected: $detectedLang, system: $systemLang)', name: 'Translation');
    return needs;
  }

  /// BCP-47 언어 코드를 TranslateLanguage로 변환
  TranslateLanguage? _getTranslateLanguage(String langCode) {
    final Map<String, TranslateLanguage> languageMap = {
      'en': TranslateLanguage.english,
      'ko': TranslateLanguage.korean,
      'ja': TranslateLanguage.japanese,
      'zh': TranslateLanguage.chinese,
      'es': TranslateLanguage.spanish,
      'fr': TranslateLanguage.french,
      'de': TranslateLanguage.german,
      'it': TranslateLanguage.italian,
      'pt': TranslateLanguage.portuguese,
      'ru': TranslateLanguage.russian,
      'ar': TranslateLanguage.arabic,
      'hi': TranslateLanguage.hindi,
      'th': TranslateLanguage.thai,
      'vi': TranslateLanguage.vietnamese,
      'id': TranslateLanguage.indonesian,
      'tr': TranslateLanguage.turkish,
      'pl': TranslateLanguage.polish,
      'nl': TranslateLanguage.dutch,
      'sv': TranslateLanguage.swedish,
      'da': TranslateLanguage.danish,
      'fi': TranslateLanguage.finnish,
      'no': TranslateLanguage.norwegian,
      'cs': TranslateLanguage.czech,
      'el': TranslateLanguage.greek,
      'he': TranslateLanguage.hebrew,
      'hu': TranslateLanguage.hungarian,
      'ro': TranslateLanguage.romanian,
      'uk': TranslateLanguage.ukrainian,
    };
    return languageMap[langCode];
  }

  /// 번역기 초기화 (언어 쌍에 맞게)
  Future<bool> _initTranslator(String sourceLang, String targetLang) async {
    // 이미 같은 언어 쌍으로 초기화되어 있으면 재사용
    if (_translator != null &&
        _cachedSourceLang == sourceLang &&
        _cachedTargetLang == targetLang) {
      return true;
    }

    // 기존 번역기 정리
    await _translator?.close();

    final sourceLanguage = _getTranslateLanguage(sourceLang);
    final targetLanguage = _getTranslateLanguage(targetLang);

    if (sourceLanguage == null || targetLanguage == null) {
      logInfo('[TranslationService] Unsupported language pair: $sourceLang -> $targetLang', name: 'Translation');
      return false;
    }

    _translator = OnDeviceTranslator(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    _cachedSourceLang = sourceLang;
    _cachedTargetLang = targetLang;

    logInfo('[TranslationService] Translator initialized: $sourceLang -> $targetLang', name: 'Translation');
    return true;
  }

  /// 모델 다운로드 확인 및 다운로드
  Future<bool> ensureModelDownloaded(String langCode) async {
    final language = _getTranslateLanguage(langCode);
    if (language == null) return false;

    final modelManager = OnDeviceTranslatorModelManager();

    try {
      final isDownloaded = await modelManager.isModelDownloaded(language.bcpCode);
      if (isDownloaded) {
        logInfo('[TranslationService] Model already downloaded: $langCode', name: 'Translation');
        return true;
      }

      logInfo('[TranslationService] Downloading model: $langCode...', name: 'Translation');
      final success = await modelManager.downloadModel(language.bcpCode);
      logInfo('[TranslationService] Model download ${success ? "complete" : "failed"}: $langCode', name: 'Translation');
      return success;
    } catch (e) {
      logInfo('[TranslationService] Model download error: $e', name: 'Translation');
      return false;
    }
  }

  /// 텍스트를 시스템 언어로 번역
  Future<TranslationResult> translateToSystemLanguage(String text) async {
    if (text.trim().isEmpty) {
      return TranslationResult(
        originalText: text,
        translatedText: text,
        wasTranslated: false,
      );
    }

    try {
      // 언어 감지
      final detectedLang = await detectLanguage(text);
      if (detectedLang == null) {
        logInfo('[TranslationService] Could not detect language', name: 'Translation');
        return TranslationResult(
          originalText: text,
          translatedText: text,
          wasTranslated: false,
        );
      }

      final systemLang = getSystemLanguage();

      // 같은 언어면 번역 불필요
      if (detectedLang == systemLang) {
        logInfo('[TranslationService] Same language, no translation needed', name: 'Translation');
        return TranslationResult(
          originalText: text,
          translatedText: text,
          wasTranslated: false,
          detectedLanguage: detectedLang,
        );
      }

      // 모델 다운로드 확인
      final sourceReady = await ensureModelDownloaded(detectedLang);
      final targetReady = await ensureModelDownloaded(systemLang);

      if (!sourceReady || !targetReady) {
        logInfo('[TranslationService] Model not ready, returning original', name: 'Translation');
        return TranslationResult(
          originalText: text,
          translatedText: text,
          wasTranslated: false,
          detectedLanguage: detectedLang,
          error: 'Translation model not available',
        );
      }

      // 번역기 초기화
      final initialized = await _initTranslator(detectedLang, systemLang);
      if (!initialized) {
        return TranslationResult(
          originalText: text,
          translatedText: text,
          wasTranslated: false,
          detectedLanguage: detectedLang,
          error: 'Translator initialization failed',
        );
      }

      // 번역 실행
      logInfo('[TranslationService] Translating from $detectedLang to $systemLang...', name: 'Translation');
      final translated = await _translator!.translateText(text);

      logInfo('[TranslationService] Translation complete', name: 'Translation');
      logInfo('[TranslationService] Original: ${text.substring(0, text.length > 50 ? 50 : text.length)}...', name: 'Translation');
      logInfo('[TranslationService] Translated: ${translated.substring(0, translated.length > 50 ? 50 : translated.length)}...', name: 'Translation');

      return TranslationResult(
        originalText: text,
        translatedText: translated,
        wasTranslated: true,
        detectedLanguage: detectedLang,
        targetLanguage: systemLang,
      );
    } catch (e) {
      logInfo('[TranslationService] Translation error: $e', name: 'Translation');
      return TranslationResult(
        originalText: text,
        translatedText: text,
        wasTranslated: false,
        error: e.toString(),
      );
    }
  }

  /// 리소스 정리
  Future<void> dispose() async {
    await _translator?.close();
    await _languageIdentifier.close();
    _translator = null;
    _cachedSourceLang = null;
    _cachedTargetLang = null;
  }
}

/// 번역 결과 클래스
class TranslationResult {
  final String originalText;
  final String translatedText;
  final bool wasTranslated;
  final String? detectedLanguage;
  final String? targetLanguage;
  final String? error;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.wasTranslated,
    this.detectedLanguage,
    this.targetLanguage,
    this.error,
  });
}
