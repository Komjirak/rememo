import 'package:flutter/material.dart';
import 'package:stribe/screens/home_screen.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/widgets/splash_screen.dart';
import 'package:stribe/services/theme_service.dart';

void main() {
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
          title: 'Folio',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          home: _showSplash
              ? SplashScreen(onComplete: _onSplashComplete)
              : const HomeScreen(),
        );
      },
    );
  }
}
