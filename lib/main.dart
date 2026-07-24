import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'package:stribe/l10n/app_localizations.dart';
import 'package:stribe/screens/home_screen.dart';
import 'package:stribe/services/obsidian_auto_export_service.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/widgets/splash_screen.dart';
import 'package:stribe/services/theme_service.dart';
import 'package:stribe/utils/app_logger.dart';

/// iOS 백그라운드 작업(BGAppRefreshTask)이 깨울 때 실행되는 진입점.
/// 반드시 top-level 함수여야 하며, 별도 Flutter 엔진에서 실행되므로
/// 여기서는 UI 관련 상태에 접근할 수 없다.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    logInfo('🔄 백그라운드 작업 실행: $task', name: 'Workmanager');
    if (task == obsidianAutoExportTaskId) {
      await ObsidianAutoExportService.runIfDue();
    }
    return true;
  });
}

void main() {
  if (Platform.isIOS) {
    Workmanager().initialize(callbackDispatcher);
  }
  runApp(const FolioApp());
}

class FolioApp extends StatefulWidget {
  const FolioApp({super.key});

  @override
  State<FolioApp> createState() => _FolioAppState();
}

class _FolioAppState extends State<FolioApp> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, child) {
        return MaterialApp(
          title: 'Rememo', // Updated title
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', ''), // Korean (Default)
            Locale('en', ''), // English
            Locale('ja', ''), // Japanese
          ],
          home: _showSplash
              ? SplashScreen(onComplete: _onSplashComplete)
              : const HomeScreen(),
        );
      },
    );
  }
}
