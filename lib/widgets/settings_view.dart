import 'package:flutter/material.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/services/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback onClearLibrary;
  final int cardCount;

  const SettingsView({
    super.key,
    required this.onClearLibrary,
    required this.cardCount,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final List<String> _defaultCategories = [
    'Inbox',
    'Shopping',
    'Food',
    'Web',
    'Work',
    'Design',
    'Tech',
    'Reference',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeader(context),
        const SizedBox(height: 32),

        // Library Stats
        _buildSection(
          context,
          title: "Library",
          children: [
            _buildStatTile(
              icon: Icons.collections_bookmark,
              label: "Total Cards",
              value: widget.cardCount.toString(),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Categories
        _buildSection(
          context,
          title: "Categories",
          children: [
            ..._defaultCategories.map((cat) => _buildCategoryTile(cat)),
          ],
        ),
        const SizedBox(height: 24),

        // App Info
        _buildSection(
          context,
          title: "About",
          children: [
            _buildInfoTile(
              icon: Icons.info_outline,
              label: "Version",
              value: "1.0.0",
            ),
            _buildInfoTile(
              icon: Icons.code,
              label: "Built with",
              value: "Flutter + Apple Vision",
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Data Management
        _buildSection(
          context,
          title: "Data",
          children: [
            _buildActionTile(
              icon: Icons.download_outlined,
              label: "Export Library",
              subtitle: "Coming soon",
              enabled: false,
              onTap: () {},
            ),
            _buildActionTile(
              icon: Icons.delete_outline,
              label: "Clear Library",
              subtitle: "Delete all saved cards",
              isDestructive: true,
              onTap: _confirmClearLibrary,
            ),
          ],
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Settings",
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          "Manage your personal library",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.ink.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink.withOpacity(0.4),
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.paper,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.ink, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.ink.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String category) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withOpacity(0.5)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getCategoryColor(category),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Icon(
              Icons.check,
              size: 18,
              color: AppTheme.ink.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'inbox':
        return Colors.grey;
      case 'shopping':
        return Colors.orange;
      case 'food':
        return Colors.green;
      case 'web':
        return Colors.blue;
      case 'work':
        return Colors.purple;
      case 'design':
        return Colors.pink;
      case 'tech':
        return Colors.cyan;
      case 'reference':
        return Colors.amber;
      default:
        return AppTheme.accent;
    }
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withOpacity(0.5)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.ink.withOpacity(0.5), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.ink.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool enabled = true,
  }) {
    final color = isDestructive ? Colors.red : AppTheme.ink;
    final opacity = enabled ? 1.0 : 0.4;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color.withOpacity(opacity), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: color.withOpacity(opacity),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDestructive ? Colors.red : AppTheme.ink).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color.withOpacity(opacity * 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearLibrary() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Library'),
        content: const Text(
          'This will permanently delete all your saved cards. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.clear();
              widget.onClearLibrary();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Library cleared')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
