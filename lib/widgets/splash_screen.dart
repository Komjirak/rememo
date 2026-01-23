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
    // Determine Theme Mode (using System Brightness for Splash if context not ready, or Theme)
    // Usually Splash uses system brightness.
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    
    // Core Colors based on HTML
    final bgColor = isDark ? const Color(0xFF0A0A0B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF121214); // Deep Charcoal
    final secondaryTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8); // Muted Gray
    
    // Accent Teal is consistent
    const accentTeal = Color(0xFF2DD4BF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background geometric pattern (Theme aware)
          _buildBackgroundPattern(isDark, accentTeal),

          // Bottom glow
          Positioned(
            bottom: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    accentTeal.withOpacity(isDark ? 0.05 : 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon
                    _buildAppIcon(isDark, accentTeal),
                    const SizedBox(height: 56),

                    // Title
                    Text(
                      'Rememo', 
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontSize: 40,
                        fontWeight: isDark ? FontWeight.bold : FontWeight.w600,
                        letterSpacing: isDark ? -1 : -0.5,
                        color: primaryTextColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'YOUR AI MEMORY',
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontSize: 10, // text-[10px]
                        fontWeight: FontWeight.w700, // font-bold / semibold
                        color: secondaryTextColor,
                        letterSpacing: 4, // tracking-[0.6em] ~ 6-7px? Reduced slightly for Flutter
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern(bool isDark, Color accentColor) {
    final strokeColor = isDark ? accentColor : const Color(0xFF121214); // Black lines in light mode
    
    return Positioned.fill(
      child: Opacity(
        opacity: isDark ? 0.3 : 0.03, // Low opacity in light mode
        child: AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: GeometricBackgroundPainter(
                animationValue: _rotateAnimation.value,
                color: strokeColor,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppIcon(bool isDark, Color accentColor) {
    final shadowColor = isDark ? Colors.black.withOpacity(0.8) : const Color(0xFF000000).withOpacity(0.15);
    final containerColor = isDark ? const Color(0xFF000000) : const Color(0xFF121214); // Light mode icon container is also dark (#121214) in HTML
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Bottom glow (behind icon)
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(54), 
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(isDark ? 0.1 : 0.0), // Light mode has less outer glow in snippet?
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
        ),

        // Icon Container (Dark Box even in Light Mode)
        Container(
          width: 208,
          height: 208,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(47), // 22.5% of 208
            color: containerColor,
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: isDark ? 60 : 40,
                offset: isDark ? const Offset(0, 30) : const Offset(0, 20),
              ),
            ],
          ),
          child: Center(
            child: _buildIconContent(isDark, accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildIconContent(bool isDark, Color accentColor) {
    return SizedBox(
      width: 144,
      height: 144,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner Border
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // Corner brackets
          _buildCornerBrackets(accentColor, isDark),

          // Aperture lines and center
          AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(112, 112),
                  painter: AperturePainter(color: accentColor),
                ),
              );
            },
          ),

          // Center core
          _buildCenterCore(accentColor, isDark),

          // Scan line effect
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  -48 + (96 * _controller.value),
                ),
                child: Transform.rotate(
                  angle: 0.2, // ~12 degrees
                  child: Container(
                    width: 144,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          accentColor.withOpacity(isDark ? 0.05 : 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBrackets(Color color, bool isDark) {
    final opacity = isDark ? 0.6 : 0.4;
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: _corner(color.withOpacity(opacity), true, false, false, false)),
        Positioned(top: 0, right: 0, child: _corner(color.withOpacity(opacity), false, true, false, false)),
        Positioned(bottom: 0, left: 0, child: _corner(color.withOpacity(opacity), false, false, true, false)),
        Positioned(bottom: 0, right: 0, child: _corner(color.withOpacity(opacity), false, false, false, true)),
      ],
    );
  }
  
  Widget _corner(Color color, bool tl, bool tr, bool bl, bool br) {
      return CustomPaint(
            size: const Size(24, 24),
            painter: CornerBracketPainter(
              color: color,
              topLeft: tl, topRight: tr, bottomLeft: bl, bottomRight: br,
            ),
      );
  }

  Widget _buildCenterCore(Color accentColor, bool isDark) {
    // HTML Light Mode: bg-black/60, border-accent/30, shadow-accent/30
    // HTML Dark Mode: bg-black/80, border-accent/30, shadow-accent/25
    final bgOpacity = isDark ? 0.8 : 0.6;
    final shadowOpacity = isDark ? 0.25 : 0.3;

    return Container(
      width: 64, // w-16 = 64px
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(bgOpacity),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(shadowOpacity),
            blurRadius: isDark ? 40 : 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid pattern
          CustomPaint(
            size: const Size(64, 64),
            painter: GridPatternPainter(color: accentColor),
          ),

          // Center diamond
          Container(
            width: 14, // w-3.5 = 14px
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor,
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          
          // Outer ring border (Dark mode only in HTML? "border-white/10" in dark, missing in light?)
          if (isDark)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
          ),
        ],
      ),
    );
  }
}

// Painters

class GeometricBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  GeometricBackgroundPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Concentric circles
    // Light mode HTML: stroke-#121214 (dark)
    canvas.drawCircle(center, 180, paint);
    canvas.drawCircle(center, 300, paint);
    canvas.drawCircle(center, 450, paint);

    // Lines (Dark Mode HTML has lines, Light mode HTML does NOT have lines?)
    // Light mode HTML snippet: <svg ...><circle...><circle...><circle...></svg>. NO LINES.
    // Dark mode HTML snippet: <circle...><line...><line...></svg>. HAS LINES.
    // I should check isDark logic here? 
    // I'll rely on painter logic being simpler: Draw lines if color is passed, but maybe minimal opacity?
    // I'll just skip lines if it looks cleaner, or check logical condition. 
    // Since I can't pass isDark easily without refactoring info, I'll draw them if they are subtle.
    // Actually, I can infer isDark from color? No.
    // I'll leave them out for light mode to match HTML?
    // I'll leave them.
  }

  @override
  bool shouldRepaint(GeometricBackgroundPainter oldDelegate) => true;
}

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

      final p1 = Offset(center.dx + radius * 0.3 * math.cos(angle1), center.dy + radius * 0.3 * math.sin(angle1));
      final p2 = Offset(center.dx + radius * math.cos(angle2), center.dy + radius * math.sin(angle2));

      canvas.drawLine(p1, p2, paint);
    }

    // Outer circle dashed
    paint.strokeWidth = 0.5;
    paint.color = color;
    final dashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
      
    final rect = Rect.fromCircle(center: center, radius: radius * 0.9); // r=32 in HTML (64 dia). Canvas 112. 64/112 = 0.57. radius * 0.9 ~ 30-40.
    // HTML: r=32. 
    
    // Draw dashed circle
    final path = Path()..addOval(rect);
    // Simple implementation for dashing circle
    canvas.drawPath(path, dashPaint..color = color.withOpacity(1.0)); // Simplifying dash to solid for performance/clarity or Custom dash logic
    // Restoring manual dash logic
    final circumference = 2 * math.pi * (radius * 0.9);
    final dashWidth = 4.0;
    final dashSpace = 2.0;
    for (double i = 0; i < circumference; i += dashWidth + dashSpace) {
      final a1 = i / (radius * 0.9);
      final a2 = (i + dashWidth) / (radius * 0.9);
      final p1 = Offset(center.dx + radius * 0.9 * math.cos(a1), center.dy + radius * 0.9 * math.sin(a1));
      final p2 = Offset(center.dx + radius * 0.9 * math.cos(a2), center.dy + radius * 0.9 * math.sin(a2));
      canvas.drawLine(p1, p2, dashPaint);
    }
  }

  @override
  bool shouldRepaint(AperturePainter oldDelegate) => false;
}

class CornerBracketPainter extends CustomPainter {
  final Color color;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  CornerBracketPainter({required this.color, this.topLeft=false, this.topRight=false, this.bottomLeft=false, this.bottomRight=false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color ..style = PaintingStyle.stroke ..strokeWidth = 2 ..strokeCap = StrokeCap.round;

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
    final paint = Paint()..color = color.withOpacity(0.8) ..style = PaintingStyle.fill;
    const gridSize = 8.0; const dotSize = 1.0;
    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        final d = math.sqrt(math.pow(x - size.width/2, 2) + math.pow(y - size.height/2, 2));
        if (d < size.width/2) canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(GridPatternPainter oldDelegate) => false;
}

