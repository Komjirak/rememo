import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stribe/l10n/app_localizations.dart';
import 'package:stribe/services/theme_service.dart';
import 'package:stribe/services/openai_service.dart';
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
  String _version = ''; // Initial empty, set in initState or build
  String _buildNumber = '';
  int _totalItems = 0;
  double _storageSize = 0.0;
  bool _isLoadingStorage = true;
  
  // OpenAI 설정 상태
  bool _openaiEnabled = true;
  bool _openaiHasKey = false;
  String _openaiModel = OpenAIService.defaultModel;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    _loadStorageInfo();
    _loadOpenAISettings();
  }
  
  Future<void> _loadOpenAISettings() async {
    final enabled = await OpenAIService.isEnabled();
    final hasKey = await OpenAIService.hasApiKey();
    final model = await OpenAIService.getModel();
    if (mounted) {
      setState(() {
        _openaiEnabled = enabled;
        _openaiHasKey = hasKey;
        _openaiModel = model;
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
                child: _buildListTile(
                  icon: Icons.cleaning_services,
                  iconColor: secondaryTextColor,
                  iconBgColor: secondaryTextColor.withOpacity(0.1),
                  label: AppLocalizations.of(context)!.settingsClearCache,
                  onTap: _showClearCacheDialog,
                  showDivider: false,
                  textColor: textColor,
                  subtitle: _isLoadingStorage
                      ? AppLocalizations.of(context)!.commonLoading
                      : "${_formatStorage(_storageSize)} • $_totalItems items",
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  AppLocalizations.of(context)!.msgCacheClearDesc,
                  style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.3),
                ),
              ),
              
              const SizedBox(height: 28),
              
              // ============================================
              // OpenAI API 설정 섹션
              // ============================================
              _buildSectionHeader('AI ANALYSIS', secondaryTextColor),
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
                                _openaiHasKey ? '활성화됨 • $_openaiModel' : 'API Key를 설정하세요',
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
                                child: const Text('설정됨', style: TextStyle(fontSize: 12, color: Color(0xFF10A37F), fontWeight: FontWeight.w500)),
                              )
                            else
                              Text('설정 필요', style: TextStyle(fontSize: 13, color: secondaryTextColor)),
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
                              child: Text('모델', style: TextStyle(fontSize: 15, color: textColor)),
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'OpenAI API를 사용하면 스크린샷 및 URL의 AI 요약 품질이 크게 향상됩니다. API Key는 기기에만 저장되며 외부로 전송되지 않습니다.',
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
                      'platform.openai.com에서 API Key를 발급받을 수 있습니다.',
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
                            testResult == 'success' ? '✅ 연결 성공!' : '❌ 연결 실패. Key를 확인하세요.',
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
                              const SnackBar(content: Text('🗑️ API Key가 삭제되었습니다'), backgroundColor: AppTheme.accentTeal),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        label: const Text('기존 Key 삭제', style: TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('취소', style: TextStyle(color: secondaryTextColor)),
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
                      : const Text('테스트', style: TextStyle(color: Color(0xFF10A37F))),
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
                    Navigator.pop(dialogContext);
                    _loadOpenAISettings();
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('✅ API Key가 저장되었습니다'), backgroundColor: AppTheme.accentTeal),
                      );
                    }
                  },
                  child: const Text('저장', style: TextStyle(color: Color(0xFF10A37F), fontWeight: FontWeight.w600)),
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
              Text('모델 선택', style: TextStyle(color: textColor, fontSize: 18)),
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
      appBar: AppBar(title: const Text("Folders")),
      body: FolderManagementView(onFolderSelected: (_) {}),
    );
  }
}
