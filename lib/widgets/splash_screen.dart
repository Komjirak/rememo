import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:stribe/theme/app_theme.dart';

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
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Scan animation controller (looping)
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();
    _scanController.repeat();

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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon with scanning animation
                _buildAppIconWithScan(isDark, accentTeal),
                const SizedBox(height: 32),

                // Brand name
                Text(
                  'Rememo',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'YOUR AI MEMORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppIconWithScan(bool isDark, Color accentColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // App icon image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27), // 22.5% of 120
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
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
