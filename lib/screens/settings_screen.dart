import 'dart:io';
import 'package:stribe/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stribe/l10n/app_localizations.dart';
import 'package:stribe/services/obsidian_auto_export_service.dart';
import 'package:stribe/services/obsidian_export_service.dart';
import 'package:stribe/services/obsidian_folder_channel.dart';
import 'package:stribe/services/theme_service.dart';
import 'package:stribe/services/openai_service.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/widgets/folder_management_view.dart';
import 'package:stribe/services/database_helper.dart';
import 'package:stribe/services/unified_analysis_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = ''; // Initial empty, set in initState or build
  String _buildNumber = '';
  int _totalItems = 0;
  double _storageSize = 0.0;
  bool _isLoadingStorage = true;
  bool _isExporting = false;

  // 옵시디언 자동 내보내기 상태
  String? _obsidianFolderName;
  bool _autoExportEnabled = false;
  int _autoExportFrequencyDays = 7;
  DateTime? _autoExportLastRunAt;
  bool _isRunningAutoExportNow = false;
  
  // OpenAI 설정 상태
  bool _openaiEnabled = false; // 프라이버시 보호: 기본 꺼짐 (opt-in)
  bool _openaiHasKey = false;
  bool _openaiVisionEnabled = true;
  String _openaiModel = OpenAIService.defaultModel;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    _loadStorageInfo();
    _loadOpenAISettings();
    _loadObsidianAutoExportSettings();
  }

  Future<void> _loadObsidianAutoExportSettings() async {
    final folderName = await ObsidianFolderChannel.folderName();
    final enabled = await ObsidianAutoExportService.isEnabled();
    final frequency = await ObsidianAutoExportService.frequencyDays();
    final lastRun = await ObsidianAutoExportService.lastRunAt();
    if (mounted) {
      setState(() {
        _obsidianFolderName = folderName;
        _autoExportEnabled = enabled;
        _autoExportFrequencyDays = frequency;
        _autoExportLastRunAt = lastRun;
      });
    }
  }

  Future<void> _loadOpenAISettings() async {
    final enabled = await OpenAIService.isEnabled();
    final hasKey = await OpenAIService.hasApiKey();
    final model = await OpenAIService.getModel();
    final visionEnabled = await OpenAIService.isVisionEnabled();
    if (mounted) {
      setState(() {
        _openaiEnabled = enabled;
        _openaiHasKey = hasKey;
        _openaiModel = model;
        _openaiVisionEnabled = visionEnabled;
      });
    }
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

      // Add database size (실제 DB 파일명은 folio.db)
      final dbDir = await getDatabasesPath();
      final dbFile = File('$dbDir/folio.db');
      if (await dbFile.exists()) {
        totalSize += await dbFile.length();
      }

      setState(() {
        _storageSize = totalSize / (1024 * 1024); // Convert to MB
        _isLoadingStorage = false;
      });
    } catch (e) {
      logWarn('Error loading storage info: $e', name: 'Settings');
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
          AppLocalizations.of(context)!.settingsTitle,
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
              _buildSectionHeader(AppLocalizations.of(context)!.settingsAppearance, secondaryTextColor),
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
                        Text(AppLocalizations.of(context)!.settingsTheme, style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildThemeOption(
                          label: AppLocalizations.of(context)!.settingsThemeLight,
                          mode: ThemeMode.light,
                          currentMode: themeService.themeMode,
                          isDark: isDark,
                          textColor: textColor,
                          selectedColor: accentTeal,
                        ),
                        _buildThemeOption(
                          label: AppLocalizations.of(context)!.settingsThemeDark,
                          mode: ThemeMode.dark,
                          currentMode: themeService.themeMode,
                          isDark: isDark,
                          textColor: textColor,
                          selectedColor: accentTeal,
                        ),
                        _buildThemeOption(
                          label: AppLocalizations.of(context)!.settingsThemeSystem,
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
              
              _buildSectionHeader(AppLocalizations.of(context)!.settingsOrganization, secondaryTextColor),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildListTile(
                  icon: Icons.folder,
                  iconColor: accentTeal,
                  iconBgColor: accentTeal.withOpacity(0.1),
                  label: AppLocalizations.of(context)!.folderManage,
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
              
              _buildSectionHeader(AppLocalizations.of(context)!.settingsData, secondaryTextColor),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.ios_share,
                      iconColor: accentTeal,
                      iconBgColor: accentTeal.withOpacity(0.1),
                      label: AppLocalizations.of(context)!.settingsExportObsidian,
                      onTap: _isExporting ? () {} : _exportToObsidian,
                      showDivider: true,
                      textColor: textColor,
                      trailing: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    _buildListTile(
                      icon: Icons.cleaning_services,
                      iconColor: secondaryTextColor,
                      iconBgColor: secondaryTextColor.withOpacity(0.1),
                      label: AppLocalizations.of(context)!.settingsClearCache,
                      onTap: _showClearCacheDialog,
                      showDivider: false,
                      textColor: textColor,
                      subtitle: _isLoadingStorage
                          ? AppLocalizations.of(context)!.commonLoading
                          : "${_formatStorage(_storageSize)} • ${AppLocalizations.of(context)!.folderItemCount(_totalItems)}",
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  AppLocalizations.of(context)!.settingsExportObsidianDesc,
                  style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.3),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  AppLocalizations.of(context)!.msgCacheClearDesc,
                  style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.3),
                ),
              ),

              const SizedBox(height: 28),

              // ============================================
              // 옵시디언 자동 내보내기 섹션
              // ============================================
              _buildSectionHeader(AppLocalizations.of(context)!.settingsAutoExport, secondaryTextColor),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.folder_special_outlined,
                      iconColor: accentTeal,
                      iconBgColor: accentTeal.withOpacity(0.1),
                      label: AppLocalizations.of(context)!.settingsVaultFolder,
                      onTap: _pickObsidianFolder,
                      showDivider: true,
                      textColor: textColor,
                      subtitle: _obsidianFolderName ?? AppLocalizations.of(context)!.settingsVaultFolderNotSet,
                    ),
                    _buildListTile(
                      icon: Icons.schedule,
                      iconColor: secondaryTextColor,
                      iconBgColor: secondaryTextColor.withOpacity(0.1),
                      label: AppLocalizations.of(context)!.settingsAutoExportToggle,
                      onTap: () => _toggleAutoExport(!_autoExportEnabled),
                      showDivider: _autoExportEnabled,
                      textColor: textColor,
                      subtitle: _autoExportEnabled
                          ? _AutoExportFrequency.fromDays(_autoExportFrequencyDays).label(context)
                          : null,
                      trailing: Switch.adaptive(
                        value: _autoExportEnabled,
                        onChanged: _toggleAutoExport,
                      ),
                    ),
                    if (_autoExportEnabled)
                      _buildListTile(
                        icon: Icons.play_circle_outline,
                        iconColor: secondaryTextColor,
                        iconBgColor: secondaryTextColor.withOpacity(0.1),
                        label: AppLocalizations.of(context)!.settingsRunAutoExportNow,
                        onTap: _isRunningAutoExportNow ? () {} : _runAutoExportNow,
                        showDivider: false,
                        textColor: textColor,
                        subtitle: _autoExportLastRunAt == null
                            ? AppLocalizations.of(context)!.settingsAutoExportNeverRun
                            : AppLocalizations.of(context)!.settingsAutoExportLastRun(
                                _formatDateTime(_autoExportLastRunAt!),
                              ),
                        trailing: _isRunningAutoExportNow
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  AppLocalizations.of(context)!.settingsAutoExportDesc,
                  style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.3),
                ),
              ),

              const SizedBox(height: 28),

              // ============================================
              // OpenAI API 설정 섹션
              // ============================================
              _buildSectionHeader(AppLocalizations.of(context)!.settingsAISectionHeader, secondaryTextColor),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10A37F).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Color(0xFF10A37F), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('OpenAI GPT', style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                _openaiHasKey
                                    ? AppLocalizations.of(context)!.settingsOpenAIActive(_openaiModel)
                                    : AppLocalizations.of(context)!.settingsOpenAIKeyNeeded,
                                style: TextStyle(fontSize: 12, color: _openaiHasKey ? const Color(0xFF10A37F) : secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                        // 활성화 토글
                        Switch.adaptive(
                          value: _openaiEnabled && _openaiHasKey,
                          onChanged: _openaiHasKey ? (value) async {
                            await OpenAIService.setEnabled(value);
                            setState(() => _openaiEnabled = value);
                          } : null,
                          activeColor: const Color(0xFF10A37F),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5EA), height: 1),
                    const SizedBox(height: 12),
                    
                    // API Key 설정 버튼
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showApiKeyDialog(textColor, cardColor, secondaryTextColor),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.key, color: secondaryTextColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('API Key', style: TextStyle(fontSize: 15, color: textColor)),
                            ),
                            if (_openaiHasKey)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10A37F).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(AppLocalizations.of(context)!.settingsConfigured, style: const TextStyle(fontSize: 12, color: Color(0xFF10A37F), fontWeight: FontWeight.w500)),
                              )
                            else
                              Text(AppLocalizations.of(context)!.settingsConfigNeeded, style: TextStyle(fontSize: 13, color: secondaryTextColor)),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, color: secondaryTextColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 모델 선택
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showModelSelectionDialog(textColor, cardColor, secondaryTextColor),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.smart_toy, color: secondaryTextColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(AppLocalizations.of(context)!.settingsModelLabel, style: TextStyle(fontSize: 15, color: textColor)),
                            ),
                            Text(
                              OpenAIService.availableModels.firstWhere(
                                (m) => m['id'] == _openaiModel,
                                orElse: () => {'name': _openaiModel},
                              )['name'] ?? _openaiModel,
                              style: TextStyle(fontSize: 13, color: secondaryTextColor),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, color: secondaryTextColor, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Vision(이미지 분석) 토글
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.image_search, color: secondaryTextColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context)!.settingsVisionLabel, style: TextStyle(fontSize: 15, color: textColor)),
                                const SizedBox(height: 2),
                                Text(
                                  AppLocalizations.of(context)!.settingsVisionDescription,
                                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _openaiVisionEnabled,
                            onChanged: _openaiHasKey ? (value) async {
                              await OpenAIService.setVisionEnabled(value);
                              setState(() => _openaiVisionEnabled = value);
                            } : null,
                            activeColor: const Color(0xFF10A37F),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  AppLocalizations.of(context)!.settingsOpenAIPrivacyNotice,
                  style: TextStyle(fontSize: 12, color: secondaryTextColor, height: 1.4),
                ),
              ),
              
              const SizedBox(height: 28),
              
              _buildSectionHeader(AppLocalizations.of(context)!.settingsInfo, secondaryTextColor),
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
                      label: AppLocalizations.of(context)!.settingsVersion,
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
          SnackBar(content: Text(AppLocalizations.of(context)!.errUrlLaunch)),
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

  /// 모든/일부(기간 선택) 메모를 옵시디언 호환 마크다운으로 변환해 zip으로
  /// 내보내고 OS 공유 시트(파일에 저장/AirDrop 등)로 전달한다. 서버를 거치지
  /// 않고 기기 안에서만 처리한다.
  Future<void> _exportToObsidian() async {
    if (_isExporting) return;

    final period = await _showExportPeriodDialog();
    if (period == null || !mounted) return; // 사용자가 취소

    final allCards = await DatabaseHelper.instance.readAllMemoCards();
    final cutoff = period.cutoffDate;
    final cards = cutoff == null
        ? allCards
        : allCards.where((c) {
            final captured = DateTime.tryParse(c.captureDate.replaceFirst(' ', 'T'));
            return captured != null && captured.isAfter(cutoff);
          }).toList();

    if (cards.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.msgExportEmpty)),
        );
      }
      return;
    }

    setState(() => _isExporting = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.msgExportPreparing),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      final folders = await DatabaseHelper.instance.readAllFolders();
      final zipFile = await ObsidianExportService.exportToZip(cards, folders: folders);

      if (!mounted) return;
      await Share.shareXFiles([XFile(zipFile.path)]);
    } catch (e) {
      logInfo('❌ Obsidian export 실패: $e', name: 'Settings');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.msgExportFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// 내보낼 기간을 고르는 다이얼로그. 취소하면 null을 반환한다.
  Future<_ExportPeriod?> _showExportPeriodDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return showDialog<_ExportPeriod>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppLocalizations.of(dialogContext)!.exportPeriodTitle,
            style: TextStyle(color: textColor, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _ExportPeriod.values.map((period) {
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pop(dialogContext, period),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: secondaryTextColor),
                      const SizedBox(width: 12),
                      Text(
                        period.label(dialogContext),
                        style: TextStyle(fontSize: 15, color: textColor),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(dialogContext)!.commonCancel),
            ),
          ],
        );
      },
    );
  }

  /// Vault 폴더를 선택(또는 변경)한다. 최초 1회만 하면 되고, 이후
  /// 자동/수동 폴더 내보내기가 이 폴더에 직접 쓴다.
  Future<void> _pickObsidianFolder() async {
    final folderName = await ObsidianFolderChannel.pickFolder();
    if (!mounted) return;
    if (folderName != null) {
      setState(() => _obsidianFolderName = folderName);
    }
  }

  /// 자동 내보내기 켜기/끄기. 켤 때는 Vault 폴더가 먼저 지정돼 있어야 하고,
  /// 주기(매일/매주/매월)를 고르게 한다.
  Future<void> _toggleAutoExport(bool value) async {
    if (!value) {
      await ObsidianAutoExportService.disable();
      if (mounted) setState(() => _autoExportEnabled = false);
      return;
    }

    if (_obsidianFolderName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.msgSelectFolderFirst)),
      );
      return;
    }

    final frequency = await _showFrequencyDialog();
    if (frequency == null || !mounted) return;

    await ObsidianAutoExportService.enable(frequencyDays: frequency.days);
    if (mounted) {
      setState(() {
        _autoExportEnabled = true;
        _autoExportFrequencyDays = frequency.days;
      });
    }
  }

  Future<_AutoExportFrequency?> _showFrequencyDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return showDialog<_AutoExportFrequency>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppLocalizations.of(dialogContext)!.settingsAutoExportFrequencyTitle,
            style: TextStyle(color: textColor, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _AutoExportFrequency.values.map((freq) {
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pop(dialogContext, freq),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: secondaryTextColor),
                      const SizedBox(width: 12),
                      Text(freq.label(dialogContext), style: TextStyle(fontSize: 15, color: textColor)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(dialogContext)!.commonCancel),
            ),
          ],
        );
      },
    );
  }

  /// 주기와 무관하게 지금 즉시 Vault 폴더로 내보낸다(설정 확인용 수동 테스트).
  Future<void> _runAutoExportNow() async {
    if (_isRunningAutoExportNow) return;
    setState(() => _isRunningAutoExportNow = true);

    final success = await ObsidianAutoExportService.runNow();

    if (mounted) {
      setState(() {
        _isRunningAutoExportNow = false;
        if (success) _autoExportLastRunAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? AppLocalizations.of(context)!.msgAutoExportSuccess
                : AppLocalizations.of(context)!.msgAutoExportFailed,
          ),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _showClearCacheDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.msgClearAllDataTitle),
        content: Text(AppLocalizations.of(context)!.msgClearAllDataConfirm(_totalItems)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.commonDelete),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.msgAllDataCleared),
          backgroundColor: AppTheme.accentTeal,
        ),
      );
    }
  }
  
  // ============================================
  // OpenAI 설정 다이얼로그
  // ============================================
  
  void _showApiKeyDialog(Color textColor, Color cardColor, Color secondaryTextColor) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isTesting = false;
        String? testResult;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.key, color: Color(0xFF10A37F), size: 24),
                  const SizedBox(width: 8),
                  Text('OpenAI API Key', style: TextStyle(color: textColor, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.settingsApiKeyHelpText,
                      style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      obscureText: true,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'sk-...',
                        hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: Icon(Icons.vpn_key_outlined, color: secondaryTextColor, size: 20),
                      ),
                    ),
                    if (testResult != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            testResult == 'success' ? Icons.check_circle : Icons.error,
                            color: testResult == 'success' ? const Color(0xFF10A37F) : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            testResult == 'success'
                                ? AppLocalizations.of(context)!.msgConnectionSuccess
                                : AppLocalizations.of(context)!.msgConnectionFailed,
                            style: TextStyle(
                              fontSize: 13,
                              color: testResult == 'success' ? const Color(0xFF10A37F) : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_openaiHasKey) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () async {
                          await OpenAIService.clearApiKey();
                          Navigator.pop(dialogContext);
                          _loadOpenAISettings();
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(this.context)!.msgApiKeyDeleted), backgroundColor: AppTheme.accentTeal),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        label: Text(AppLocalizations.of(context)!.settingsDeleteExistingKey, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(AppLocalizations.of(context)!.commonCancel, style: TextStyle(color: secondaryTextColor)),
                ),
                // 테스트 버튼
                TextButton(
                  onPressed: isTesting ? null : () async {
                    final key = controller.text.trim();
                    if (key.isEmpty || !key.startsWith('sk-')) {
                      setDialogState(() => testResult = 'fail');
                      return;
                    }
                    setDialogState(() { isTesting = true; testResult = null; });
                    final success = await OpenAIService.testApiKey(key);
                    setDialogState(() {
                      isTesting = false;
                      testResult = success ? 'success' : 'fail';
                    });
                  },
                  child: isTesting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10A37F)))
                      : Text(AppLocalizations.of(context)!.commonTest, style: const TextStyle(color: Color(0xFF10A37F))),
                ),
                // 저장 버튼
                TextButton(
                  onPressed: () async {
                    final key = controller.text.trim();
                    if (key.isEmpty || !key.startsWith('sk-')) {
                      setDialogState(() => testResult = 'fail');
                      return;
                    }
                    await OpenAIService.setApiKey(key);
                    await OpenAIService.setEnabled(true);
                    // 이전 키의 영구 오류/쿨다운 상태 해제 (Level 0 재활성화)
                    UnifiedAnalysisService.resetOpenAIError();
                    Navigator.pop(dialogContext);
                    _loadOpenAISettings();
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(this.context)!.msgApiKeySaved), backgroundColor: AppTheme.accentTeal),
                      );
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.commonSave, style: const TextStyle(color: Color(0xFF10A37F), fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showModelSelectionDialog(Color textColor, Color cardColor, Color secondaryTextColor) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.smart_toy, color: Color(0xFF10A37F), size: 24),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(dialogContext)!.settingsModelSelectTitle, style: TextStyle(color: textColor, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: OpenAIService.availableModels.map((model) {
                final isSelected = model['id'] == _openaiModel;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    await OpenAIService.setModel(model['id']!);
                    Navigator.pop(dialogContext);
                    _loadOpenAISettings();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF10A37F).withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? Border.all(color: const Color(0xFF10A37F), width: 1) : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model['name']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                model['description']!,
                                style: TextStyle(fontSize: 12, color: secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Color(0xFF10A37F), size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class FolderManagementWrapper extends StatelessWidget {
  const FolderManagementWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.folderManage)),
      body: FolderManagementView(onFolderSelected: (_) {}),
    );
  }
}

/// 옵시디언 내보내기 시 대상 기간을 고르는 옵션.
enum _ExportPeriod { all, last7Days, last30Days, last90Days }

extension on _ExportPeriod {
  /// null이면 전체 기간(필터 없음).
  DateTime? get cutoffDate {
    final now = DateTime.now();
    switch (this) {
      case _ExportPeriod.all:
        return null;
      case _ExportPeriod.last7Days:
        return now.subtract(const Duration(days: 7));
      case _ExportPeriod.last30Days:
        return now.subtract(const Duration(days: 30));
      case _ExportPeriod.last90Days:
        return now.subtract(const Duration(days: 90));
    }
  }

  String label(BuildContext context) {
    switch (this) {
      case _ExportPeriod.all:
        return AppLocalizations.of(context)!.exportPeriodAll;
      case _ExportPeriod.last7Days:
        return AppLocalizations.of(context)!.exportPeriodLast7Days;
      case _ExportPeriod.last30Days:
        return AppLocalizations.of(context)!.exportPeriodLast30Days;
      case _ExportPeriod.last90Days:
        return AppLocalizations.of(context)!.exportPeriodLast90Days;
    }
  }
}

/// 자동 내보내기 주기 옵션. iOS는 정확한 시각을 보장하지 않으므로,
/// 여기서는 "최소 이만큼은 지나야 다시 실행" 정도의 목표 주기로 쓰인다.
enum _AutoExportFrequency {
  daily(1),
  weekly(7),
  monthly(30);

  const _AutoExportFrequency(this.days);

  final int days;

  static _AutoExportFrequency fromDays(int days) {
    if (days <= 1) return _AutoExportFrequency.daily;
    if (days <= 7) return _AutoExportFrequency.weekly;
    return _AutoExportFrequency.monthly;
  }

  String label(BuildContext context) {
    switch (this) {
      case _AutoExportFrequency.daily:
        return AppLocalizations.of(context)!.autoExportFrequencyDaily;
      case _AutoExportFrequency.weekly:
        return AppLocalizations.of(context)!.autoExportFrequencyWeekly;
      case _AutoExportFrequency.monthly:
        return AppLocalizations.of(context)!.autoExportFrequencyMonthly;
    }
  }
}
