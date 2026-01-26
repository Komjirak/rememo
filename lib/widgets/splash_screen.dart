import 'dart:ui';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Design System Colors from HTML
    final bgColor = isDark ? const Color(0xFF121214) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF121214);
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    
    // Accent Teal from HTML (#2dd4bf)
    const accentTeal = Color(0xFF2DD4BF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background gradient blur effect
          Positioned.fill(
            child: Center(
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentTeal.withOpacity(isDark ? 0.05 : 0.03),
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
                    _buildAppIcon(accentTeal),
                    const SizedBox(height: 56),

                    // Brand name
                    Text(
                      'Rememo',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.5,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tagline
                    Text(
                      'YOUR AI MEMORY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                        letterSpacing: 7.0, // 0.7em equivalent
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

  Widget _buildAppIcon(Color accentColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Shadow below icon
        Positioned(
          bottom: -24,
          child: Container(
            width: 160,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // Icon container
        Container(
          width: 224, // 56 * 4 (w-56 h-56 from HTML)
          height: 224,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50.4), // 22.5% of 224
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inner border circle
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Corner brackets
              _buildCornerBrackets(accentColor),
              
              // Center icon
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect behind icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withOpacity(0.3),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    
                    // Material icon
                    Icon(
                      Icons.auto_awesome,
                      size: 56,
                      color: accentColor,
                      shadows: [
                        Shadow(
                          color: accentColor.withOpacity(0.8),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCornerBrackets(Color accentColor) {
    const bracketSize = 32.0;
    const borderWidth = 3.0;
    const cornerRadius = 4.0;
    
    final bracketShadow = [
      BoxShadow(
        color: accentColor.withOpacity(0.6),
        blurRadius: 15,
        spreadRadius: 0,
      ),
    ];
    
    return Stack(
      children: [
        // Top Left
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(cornerRadius),
              ),
              border: Border(
                top: BorderSide(
                  color: accentColor,
                  width: borderWidth,
                ),
                left: BorderSide(
                  color: accentColor,
                  width: borderWidth,
                ),
              ),
              boxShadow: bracketShadow,
            ),
          ),
        ),
        
        // Top Right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(cornerRadius),
              ),
              border: Border(
                top: BorderSide(
                  color: accentColor,
                  width: borderWidth,
                ),
                right: BorderSide(
                  color: accentColor,
                  width: borderWidth,
                ),
              ),
              boxShadow: bracketShadow,
            ),
          ),
        ),
        
        // Bottom Left
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(cornerRadius),
              ),
              border: Border(
                bottom: BorderSide(
                  color: accentColor,
                  width: borderWidth,
                ),
                left: BorderSide(
                  color: accentColor,
                  width: borderWidth,
                ),
              ),
              boxShadow: bracketShadow,
            ),
          ),
        ),
        
        // Bottom Right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(cornerRadius),
              ),
              border: Border(
                bottom: BorderSide(
                  color: accentColor,
                  width: borderWidth,
                ),
                right: BorderSide(
                  color: accentColor,
                  width: borderWidth,
                ),
              ),
              boxShadow: bracketShadow,
            ),
          ),
        ),
      ],
    );
  }
}
