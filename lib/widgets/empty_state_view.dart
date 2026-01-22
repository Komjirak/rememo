import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:stribe/theme/app_theme.dart';

class EmptyStateView extends StatelessWidget {
  final VoidCallback onAddFirst;
  final VoidCallback? onLearnMore;

  const EmptyStateView({
    super.key,
    required this.onAddFirst,
    this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Glowing Icon Container
          _buildGlowingIcon(),

          const SizedBox(height: 40),

          // Title & Description
          _buildContent(context),

          const SizedBox(height: 48),

          // Action Buttons
          _buildActions(context),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildGlowingIcon() {
    return Builder(
      builder: (context) {
        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withAlpha(51), // 20% opacity
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),

              // Main container
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(102), // 40% opacity
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                    // Teal glow
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withAlpha(38), // 15% opacity
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Icon
                    Icon(
                      Icons.blur_on,
                      size: 56,
                      color: Theme.of(context).primaryColor,
                    ),
                    // Bottom glow bar
                    Positioned(
                      bottom: 20,
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(102), // 40% opacity
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withAlpha(128),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Text(
          "Your memory starts here",
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Theme.of(context).textTheme.titleLarge?.color, // Adjusted for light theme visibility
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Capture screenshots anywhere and Folio will automatically turn them into organized, searchable knowledge.",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Primary Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAddFirst,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.black.withAlpha(26);
                }
                return null;
              }),
            ),
            child: Text(
              "Add your first memory",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary Button
        TextButton(
          onPressed: onLearnMore,
          child: Text(
            "Learn how it works",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
