import 'package:flutter/material.dart';
import 'package:stribe/theme/app_theme.dart';
import 'dart:math' as math;

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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _controller.forward();

    // Navigate to home after animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine Theme Mode
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    
    // Design System Colors
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA);
    final primaryTextColor = isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF636366);
    
    // Signature Teal Accent
    const accentTeal = Color(0xFF4FD1C5);

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
                // App icon
                _buildAppIcon(isDark, accentTeal),
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

  Widget _buildAppIcon(bool isDark, Color accentColor) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27), // 22.5% of 120
        color: const Color(0xFF161616),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: _buildIconContent(isDark, accentColor),
      ),
    );
  }

  Widget _buildIconContent(bool isDark, Color accentColor) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corner brackets
          _buildCornerBrackets(accentColor),

          // Aperture lines
          AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: AperturePainter(color: accentColor),
                ),
              );
            },
          ),

          // Center core
          _buildCenterCore(accentColor),
        ],
      ),
    );
  }

  Widget _buildCornerBrackets(Color color) {
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: _corner(color.withOpacity(0.6), true, false, false, false)),
        Positioned(top: 0, right: 0, child: _corner(color.withOpacity(0.6), false, true, false, false)),
        Positioned(bottom: 0, left: 0, child: _corner(color.withOpacity(0.6), false, false, true, false)),
        Positioned(bottom: 0, right: 0, child: _corner(color.withOpacity(0.6), false, false, false, true)),
      ],
    );
  }
  
  Widget _corner(Color color, bool tl, bool tr, bool bl, bool br) {
    return CustomPaint(
      size: const Size(16, 16),
      painter: CornerBracketPainter(
        color: color,
        topLeft: tl,
        topRight: tr,
        bottomLeft: bl,
        bottomRight: br,
      ),
    );
  }

  Widget _buildCenterCore(Color accentColor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.7),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid pattern
          CustomPaint(
            size: const Size(36, 36),
            painter: GridPatternPainter(color: accentColor),
          ),

          // Center diamond
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor,
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Painters

class AperturePainter extends CustomPainter {
  final Color color;
  AperturePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    const bladeCount = 7;
    for (int i = 0; i < bladeCount; i++) {
      final angle1 = (i * 2 * math.pi / bladeCount);
      final angle2 = ((i + 1) * 2 * math.pi / bladeCount);

      final p1 = Offset(
        center.dx + radius * 0.3 * math.cos(angle1),
        center.dy + radius * 0.3 * math.sin(angle1),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle2),
        center.dy + radius * math.sin(angle2),
      );

      canvas.drawLine(p1, p2, paint);
    }

    // Outer circle
    final circlePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    canvas.drawCircle(center, radius * 0.9, circlePaint);
  }

  @override
  bool shouldRepaint(AperturePainter oldDelegate) => false;
}

class CornerBracketPainter extends CustomPainter {
  final Color color;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  CornerBracketPainter({
    required this.color,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    if (topLeft) {
      canvas.drawLine(Offset(0, size.height * 0.4), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.4, 0), paint);
    } else if (topRight) {
      canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height * 0.4), paint);
    } else if (bottomLeft) {
      canvas.drawLine(Offset(0, size.height * 0.6), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width * 0.4, size.height), paint);
    } else if (bottomRight) {
      canvas.drawLine(Offset(size.width * 0.6, size.height), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height * 0.6), paint);
    }
  }

  @override
  bool shouldRepaint(CornerBracketPainter oldDelegate) => false;
}

class GridPatternPainter extends CustomPainter {
  final Color color;
  GridPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    const gridSize = 6.0;
    const dotSize = 0.8;
    
    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        final d = math.sqrt(
          math.pow(x - size.width / 2, 2) + math.pow(y - size.height / 2, 2),
        );
        if (d < size.width / 2) {
          canvas.drawCircle(Offset(x, y), dotSize, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(GridPatternPainter oldDelegate) => false;
}
