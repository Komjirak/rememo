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
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background geometric pattern
          _buildBackgroundPattern(),

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
                    AppTheme.accentTeal.withOpacity(0.05),
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
                    _buildAppIcon(),
                    const SizedBox(height: 56),

                    // Title
                    Text(
                      'Rememo',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'YOUR AI MEMORY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 4,
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

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.3,
        child: AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: GeometricBackgroundPainter(
                animationValue: _rotateAnimation.value,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Bottom glow
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(54), // 22.5% of 240
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentTeal.withOpacity(0.1),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
        ),

        // Main icon container
        Container(
          width: 208,
          height: 208,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(47), // 22.5% of 208
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A1C),
                Color(0xFF0A0A0B),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 60,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          child: Center(
            child: _buildIconContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildIconContent() {
    return SizedBox(
      width: 144,
      height: 144,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer border
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
          _buildCornerBrackets(),

          // Aperture lines and center
          AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(112, 112),
                  painter: AperturePainter(),
                ),
              );
            },
          ),

          // Center core
          _buildCenterCore(),

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
                  angle: 0.2,
                  child: Container(
                    width: 144,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          AppTheme.accentTeal.withOpacity(0.05),
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

  Widget _buildCornerBrackets() {
    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(24, 24),
            painter: CornerBracketPainter(
              color: AppTheme.accentTeal.withOpacity(0.6),
              topLeft: true,
            ),
          ),
        ),
        // Top-right
        Positioned(
          top: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(24, 24),
            painter: CornerBracketPainter(
              color: AppTheme.accentTeal.withOpacity(0.6),
              topRight: true,
            ),
          ),
        ),
        // Bottom-left
        Positioned(
          bottom: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(24, 24),
            painter: CornerBracketPainter(
              color: AppTheme.accentTeal.withOpacity(0.6),
              bottomLeft: true,
            ),
          ),
        ),
        // Bottom-right
        Positioned(
          bottom: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(24, 24),
            painter: CornerBracketPainter(
              color: AppTheme.accentTeal.withOpacity(0.6),
              bottomRight: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterCore() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.6),
        border: Border.all(
          color: AppTheme.accentTeal.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentTeal.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid pattern
          CustomPaint(
            size: const Size(64, 64),
            painter: GridPatternPainter(),
          ),

          // Center diamond
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: AppTheme.accentTeal,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentTeal,
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Outer ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for geometric background
class GeometricBackgroundPainter extends CustomPainter {
  final double animationValue;

  GeometricBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentTeal.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Concentric circles
    canvas.drawCircle(center, 180, paint..color = AppTheme.accentTeal.withOpacity(0.3));
    canvas.drawCircle(center, 300, paint..color = AppTheme.accentTeal.withOpacity(0.2));
    canvas.drawCircle(center, 450, paint..color = AppTheme.accentTeal.withOpacity(0.1));

    // Cross lines
    paint.color = AppTheme.accentTeal.withOpacity(0.2);
    paint.strokeWidth = 0.2;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paint);

    // Diagonal lines
    paint.color = AppTheme.accentTeal.withOpacity(0.1);
    paint.strokeWidth = 0.1;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(GeometricBackgroundPainter oldDelegate) => true;
}

// Custom painter for aperture effect
class AperturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentTeal.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Aperture blades
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
    paint.strokeWidth = 0.5;
    paint.color = AppTheme.accentTeal;
    final dashPaint = Paint()
      ..color = AppTheme.accentTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final path = Path();
    const dashWidth = 4.0;
    const dashSpace = 2.0;
    double distance = 0.0;
    final circumference = 2 * math.pi * (radius * 0.9);

    for (double i = 0; i < circumference; i += dashWidth + dashSpace) {
      final angle1 = i / (radius * 0.9);
      final angle2 = (i + dashWidth) / (radius * 0.9);

      final p1 = Offset(
        center.dx + radius * 0.9 * math.cos(angle1),
        center.dy + radius * 0.9 * math.sin(angle1),
      );
      final p2 = Offset(
        center.dx + radius * 0.9 * math.cos(angle2),
        center.dy + radius * 0.9 * math.sin(angle2),
      );

      canvas.drawLine(p1, p2, dashPaint);
    }
  }

  @override
  bool shouldRepaint(AperturePainter oldDelegate) => false;
}

// Custom painter for corner brackets
class CornerBracketPainter extends CustomPainter {
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

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
      ..strokeWidth = 2
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

// Custom painter for grid pattern
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentTeal.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    const gridSize = 8.0;
    const dotSize = 1.0;

    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        final distance = math.sqrt(
          math.pow(x - size.width / 2, 2) + math.pow(y - size.height / 2, 2),
        );
        if (distance < size.width / 2) {
          canvas.drawCircle(Offset(x, y), dotSize, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(GridPatternPainter oldDelegate) => false;
}
