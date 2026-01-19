import 'package:flutter/material.dart';
import 'package:stribe/theme/app_theme.dart';

enum ViewMode { library, smart, collections, settings }

class FolioNavigationBar extends StatelessWidget {
  final ViewMode currentView;
  final ValueChanged<ViewMode> onViewChanged;

  const FolioNavigationBar({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark.withAlpha(204), // 80% opacity
        border: const Border(
          top: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(
            AppTheme.backgroundDark.withAlpha(51),
            BlendMode.srcOver,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    icon: Icons.grid_view,
                    activeIcon: Icons.grid_view,
                    label: "Library",
                    mode: ViewMode.library,
                  ),
                  _buildNavItem(
                    icon: Icons.auto_awesome_outlined,
                    activeIcon: Icons.auto_awesome,
                    label: "Smart",
                    mode: ViewMode.smart,
                  ),
                  _buildNavItem(
                    icon: Icons.folder_copy_outlined,
                    activeIcon: Icons.folder_copy,
                    label: "Collections",
                    mode: ViewMode.collections,
                  ),
                  _buildNavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: "Settings",
                    mode: ViewMode.settings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ViewMode mode,
  }) {
    final bool isActive = currentView == mode;
    return GestureDetector(
      onTap: () => onViewChanged(mode),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.accentTeal : AppTheme.textDisabled,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.accentTeal : AppTheme.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
