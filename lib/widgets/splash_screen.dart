import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:stribe/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _scanController;
  late AnimationController _pulseController;

  // 아이콘 → 브랜드명 → 태그라인 순서로 살짝 시차를 두고 나타나는 연출
  late Animation<double> _iconFade;
  late Animation<double> _iconScale;
  late Animation<double> _titleFade;
  late Animation<double> _titleSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _taglineSlide;
  late Animation<double> _scanAnimation;
  // 아이콘이 은은하게 숨쉬듯 커졌다 작아지는 루프 (주목도를 위한 미세한 움직임)
  late Animation<double> _pulseScale;
  late Animation<double> _pulseGlow;

  @override
  void initState() {
    super.initState();

    // Main entrance controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // Scan animation controller (looping)
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Breathing glow controller (looping)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _iconScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseGlow = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
    _scanController.repeat();
    _pulseController.repeat(reverse: true);

    // Navigate to home after animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine Theme Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Design System Colors
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA);
    final primaryTextColor = isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF636366);
    
    // Accent Teal
    const accentTeal = Color(0xFF2DD4BF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon with scanning + breathing animation
            _buildAppIconWithScan(isDark, accentTeal),
            const SizedBox(height: 32),

            // Brand name (아이콘 다음에 살짝 늦게 나타남)
            FadeTransition(
              opacity: _titleFade,
              child: AnimatedBuilder(
                animation: _titleSlide,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _titleSlide.value),
                  child: child,
                ),
                child: Text(
                  'Rememo',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: primaryTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Tagline (브랜드명 다음에 나타남)
            FadeTransition(
              opacity: _taglineFade,
              child: AnimatedBuilder(
                animation: _taglineSlide,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _taglineSlide.value),
                  child: child,
                ),
                child: Text(
                  AppLocalizations.of(context)!.splashTagline,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIconWithScan(bool isDark, Color accentColor) {
    return FadeTransition(
      opacity: _iconFade,
      child: ScaleTransition(
        scale: _iconScale,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseScale.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 라이트 모드 전용: 어두운 아이콘 타일이 밝은 배경 위에서
                  // 붕 뜬 것처럼 보이지 않도록 은은한 후광을 깔아 자연스럽게
                  // 붙어 보이게 한다. 다크 모드는 배경과 이미 잘 어우러지므로
                  // 최소한의 틴트만 준다.
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withOpacity(
                            (isDark ? 0.16 : 0.10) * _pulseGlow.value,
                          ),
                          accentColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  // App icon image
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(27), // 22.5% of 120
                      border: isDark
                          ? null
                          : Border.all(
                              color: Colors.black.withOpacity(0.06),
                              width: 1,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.22 * _pulseGlow.value),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(27),
                      child: Image.asset(
                        'assets/icon.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Scanning line overlay (R 우측 하단)
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(120, 120),
                        painter: ScanningLinePainter(
                          progress: _scanAnimation.value,
                          color: accentColor,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Scanning Line Painter for R 우측 하단
class ScanningLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  ScanningLinePainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // R 우측 하단 영역 정의
    final scanAreaWidth = size.width * 0.5; // 오른쪽 절반
    final scanAreaHeight = size.height * 0.5; // 아래쪽 절반
    final scanStartX = size.width * 0.5; // 중앙에서 시작
    final scanStartY = size.height * 0.5; // 중앙에서 시작
    
    // 스캔 라인 위치 계산 (우측 하단으로 대각선 이동)
    final endX = scanStartX + (scanAreaWidth * progress);
    final endY = scanStartY + (scanAreaHeight * progress);
    
    // 그라데이션 효과를 위한 shader 생성
    final gradient = ui.Gradient.linear(
      Offset(scanStartX, scanStartY),
      Offset(endX, endY),
      [
        color.withOpacity(0.0),
        color.withOpacity(0.9),
        color.withOpacity(0.0),
      ],
      [0.0, 0.5, 1.0],
    );
    
    // 메인 스캔 라인 페인트
    final gradientPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    // 우측 하단 영역에 대각선 스캔 라인 그리기
    canvas.drawLine(
      Offset(scanStartX, scanStartY),
      Offset(endX, endY),
      gradientPaint,
    );
    
    // 글로우 효과 (스캔 라인 주변)
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(scanStartX, scanStartY),
      Offset(endX, endY),
      glowPaint,
    );
    
    // 스캔된 영역 하이라이트
    if (progress > 0.2 && progress < 0.95) {
      final highlightPaint = Paint()
        ..color = color.withOpacity(0.08)
        ..style = PaintingStyle.fill;
      
      // 스캔된 영역을 삼각형으로 하이라이트
      final path = Path()
        ..moveTo(scanStartX, scanStartY)
        ..lineTo(endX, endY)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, scanStartY)
        ..close();
      
      canvas.drawPath(path, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(ScanningLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
