import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stribe/services/theme_service.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/widgets/folder_management_view.dart';
import 'package:stribe/services/database_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = 'Loading...';
  String _buildNumber = '';
  int _totalItems = 0;
  double _storageSize = 0.0;
  bool _isLoadingStorage = true;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    _loadStorageInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _loadStorageInfo() async {
    try {
      // Count total items
      final cards = await DatabaseHelper.instance.readAllMemoCards();
      _totalItems = cards.length;

      // Calculate storage size
      double totalSize = 0.0;
      for (var card in cards) {
        if (card.imageUrl.isNotEmpty && !card.imageUrl.startsWith('http')) {
          try {
            final file = File(card.imageUrl);
            if (await file.exists()) {
              final size = await file.length();
              totalSize += size;
            }
          } catch (_) {}
        }
      }

      // Add database size
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = '${appDir.path}/rememo.db';
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        totalSize += await dbFile.length();
      }

      setState(() {
        _storageSize = totalSize / (1024 * 1024); // Convert to MB
        _isLoadingStorage = false;
      });
    } catch (e) {
      print('Error loading storage info: $e');
      setState(() {
        _isLoadingStorage = false;
      });
    }
  }

  String _formatStorage(double mb) {
    if (mb < 1) {
      return '${(mb * 1024).toStringAsFixed(1)} KB';
    } else if (mb < 1024) {
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Design System Colors
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF161616) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF636366);
    
    // Signature Teal
    const accentTeal = Color(0xFF4FD1C5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: bgColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, size: 20, color: textColor),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("APPEARANCE", secondaryTextColor),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette, color: accentTeal, size: 22),
                        const SizedBox(width: 12),
                        Text("Theme", style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildThemeOption(
                          label: "Light",
                          mode: ThemeMode.light,
                          currentMode: themeService.themeMode,
                          isDark: isDark,
                          textColor: textColor,
                          selectedColor: accentTeal,
                        ),
                        _buildThemeOption(
                          label: "Dark",
                          mode: ThemeMode.dark,
                          currentMode: themeService.themeMode,
                          isDark: isDark,
                          textColor: textColor,
                          selectedColor: accentTeal,
                        ),
                        _buildThemeOption(
                          label: "System",
                          mode: ThemeMode.system,
                          currentMode: themeService.themeMode,
                          isDark: isDark,
                          textColor: textColor,
                          selectedColor: accentTeal,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              _buildSectionHeader("MANAGEMENT", secondaryTextColor),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildListTile(
                  icon: Icons.folder,
                  iconColor: accentTeal,
                  iconBgColor: accentTeal.withOpacity(0.1),
                  label: "Folder Management",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FolderManagementWrapper()),
                    );
                  },
                  showDivider: false,
                  textColor: textColor,
                ),
              ),
              
              const SizedBox(height: 28),
              
              _buildSectionHeader("SYSTEM", secondaryTextColor),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildListTile(
                  icon: Icons.cleaning_services,
                  iconColor: secondaryTextColor,
                  iconBgColor: secondaryTextColor.withOpacity(0.1),
                  label: "Clear Cache",
                  onTap: _showClearCacheDialog,
                  showDivider: false,
                  textColor: textColor,
                  subtitle: _isLoadingStorage
                      ? "Calculating..."
                      : "Storage: ${_formatStorage(_storageSize)} • $_totalItems items",
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  "Clearing cache will remove all memories and images. This action cannot be undone.",
                  style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.3),
                ),
              ),
              
              const SizedBox(height: 28),
              
              _buildSectionHeader("INFO", secondaryTextColor),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.business,
                      iconColor: accentTeal,
                      iconBgColor: accentTeal.withOpacity(0.1),
                      label: "Komjirak Studio",
                      onTap: _openKomjirakStudio,
                      showDivider: true,
                      textColor: textColor,
                    ),
                    _buildListTile(
                      icon: Icons.info_outline,
                      iconColor: secondaryTextColor,
                      iconBgColor: secondaryTextColor.withOpacity(0.1),
                      label: "Version",
                      onTap: () {},
                      showDivider: false,
                      textColor: textColor,
                      trailing: Text(
                        "v$_version (Build $_buildNumber)",
                        style: TextStyle(fontSize: 14, color: secondaryTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF161616),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(Icons.psychology, color: Color(0xFF4FD1C5), size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Rememo",
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "AI-Powered Memory Archive",
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openKomjirakStudio() async {
    final url = Uri.parse('https://www.komjirak.studio');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open website')),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
  
  Widget _buildThemeOption({
    required String label,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required bool isDark,
    required Color textColor,
    required Color selectedColor,
  }) {
    final isSelected = currentMode == mode;
    
    Widget preview;
    if (mode == ThemeMode.light) {
      preview = Container(
        color: Colors.white,
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Container(height: 8, width: double.infinity, color: const Color(0xFFF3F4F6), margin: const EdgeInsets.only(bottom: 2)),
            Container(height: 8, width: 24, color: const Color(0xFFF3F4F6)),
            const Spacer(),
            Container(height: 12, width: double.infinity, color: const Color(0xFF4FD1C5), margin: const EdgeInsets.only(top: 2)),
          ],
        ),
      );
    } else if (mode == ThemeMode.dark) {
      preview = Container(
        color: const Color(0xFF0A0A0A),
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Container(height: 8, width: double.infinity, color: const Color(0xFF161616), margin: const EdgeInsets.only(bottom: 2)),
            Container(height: 8, width: 24, color: const Color(0xFF161616)),
            const Spacer(),
            Container(height: 12, width: double.infinity, color: const Color(0xFF4FD1C5), margin: const EdgeInsets.only(top: 2)),
          ],
        ),
      );
    } else {
      preview = Row(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(height: 8, width: double.infinity, color: const Color(0xFFF3F4F6), margin: const EdgeInsets.all(2)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF0A0A0A),
              child: Column(
                children: [
                  Container(height: 8, width: double.infinity, color: const Color(0xFF161616), margin: const EdgeInsets.all(2)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        ThemeService.instance.setTheme(mode);
        setState(() {});
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? selectedColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: preview,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? textColor : const Color(0xFF8E8E93),
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required VoidCallback onTap,
    required bool showDivider,
    required Color textColor,
    String? subtitle,
    Widget? trailing,
  }) {
    final dividerColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE5E5EA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: showDivider
                    ? BoxDecoration(
                        border: Border(bottom: BorderSide(color: dividerColor, width: 0.5)),
                      )
                    : null,
                padding: showDivider ? const EdgeInsets.only(bottom: 12) : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: TextStyle(fontSize: 16, color: textColor)),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    trailing ?? const Icon(Icons.chevron_right, color: Color(0xFF8E8E93), size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearCacheDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Clear All Data?"),
        content: Text("This will permanently delete $_totalItems items. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
  
  Future<void> _clearAllData() async {
    final cards = await DatabaseHelper.instance.readAllMemoCards();
    for (var card in cards) {
      if (card.imageUrl.isNotEmpty && !card.imageUrl.startsWith('http')) {
        try {
          final file = File(card.imageUrl);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    await DatabaseHelper.instance.clear();
    
    // Reload storage info
    await _loadStorageInfo();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ All data cleared"),
          backgroundColor: AppTheme.accentTeal,
        ),
      );
    }
  }
}

class FolderManagementWrapper extends StatelessWidget {
  const FolderManagementWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Folders")),
      body: FolderManagementView(onFolderSelected: (_) {}),
    );
  }
}
