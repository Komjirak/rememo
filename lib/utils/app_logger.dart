import 'dart:developer' as developer;

/// 앱 전역 로깅 유틸.
/// print() 대신 사용해 릴리즈 빌드 콘솔 오염을 막고 카테고리별 필터링을 가능하게 한다.
void logInfo(String message, {String name = 'Rememo'}) {
  developer.log(message, name: name);
}

void logWarn(String message, {String name = 'Rememo'}) {
  developer.log('⚠️ $message', name: name, level: 900);
}

void logError(String message,
    {String name = 'Rememo', Object? error, StackTrace? stackTrace}) {
  developer.log('❌ $message',
      name: name, level: 1000, error: error, stackTrace: stackTrace);
}
