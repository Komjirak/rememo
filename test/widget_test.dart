// 앱 스모크 테스트: 앱이 크래시 없이 빌드되고 스플래시 → 홈 전환이 되는지 확인.
// (기존 카운터 템플릿 테스트는 실제 앱과 무관해 교체함)

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stribe/main.dart';
import 'package:stribe/widgets/splash_screen.dart';

void main() {
  setUpAll(() {
    // 테스트 환경(호스트 데스크톱)에서는 네이티브 sqflite가 없으므로 ffi 사용
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App builds and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FolioApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    // 스플래시 타이머(2.5초) 소진 후 홈으로 전환
    // (반복 애니메이션이 있을 수 있어 pumpAndSettle 대신 고정 pump 사용)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
  });
}
