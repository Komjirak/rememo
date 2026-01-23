import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stribe/services/theme_service.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/widgets/folder_management_view.dart';
import 'package:stribe/services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors derived from design spec
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    
    // Explicit iOS Blue from design
    const iosBlue = Color(0xFF007AFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark 
            ? const Color(0xFF1C1C1E).withOpacity(0.8) 
            : const Color(0xFFF2F2F7).withOpacity(0.8),
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: iosBlue), // chevron_left material is diff from iOS back
          label: const Text("Back", style: TextStyle(fontSize: 17, color: iosBlue)),
          style: TextButton.styleFrom(
             padding: const EdgeInsets.only(left: 8), 
             alignment: Alignment.centerLeft,
          ),
        ),
        leadingWidth: 100,
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
                   borderRadius: BorderRadius.circular(14),
                 ),
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   children: [
                     Row(
                       children: [
                         const Icon(Icons.palette, color: Color(0xFF8E8E93), size: 22),
                         const SizedBox(width: 12),
                         Text("Theme", style: TextStyle(fontSize: 17, color: textColor)),
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
                           selectedColor: iosBlue
                         ),
                         _buildThemeOption(
                           label: "Dark", 
                           mode: ThemeMode.dark, 
                           currentMode: themeService.themeMode, 
                           isDark: isDark,
                           textColor: textColor,
                           selectedColor: iosBlue
                         ),
                         _buildThemeOption(
                           label: "System", 
                           mode: ThemeMode.system, 
                           currentMode: themeService.themeMode, 
                           isDark: isDark,
                           textColor: textColor,
                           selectedColor: iosBlue
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
                   borderRadius: BorderRadius.circular(14),
                 ),
                 child: Column(
                   children: [
                     _buildListTile(
                       icon: Icons.folder,
                       iconColor: iosBlue,
                       iconBgColor: iosBlue.withOpacity(0.1),
                       label: "Folder Management",
                       onTap: () {
                         Navigator.push(
                           context, 
                           MaterialPageRoute(builder: (_) => const FolderManagementWrapper()),
                         );
                       },
                       showDivider: true,
                       textColor: textColor,
                     ),
                     _buildListTile(
                       icon: Icons.auto_awesome,
                       iconColor: Colors.orange,
                       iconBgColor: Colors.orange.withOpacity(0.1),
                       label: "AI Preferences",
                       onTap: () {
                          // Placeholder
                       },
                       showDivider: false,
                       textColor: textColor,
                     ),
                   ],
                 ),
               ),
               
               const SizedBox(height: 28),
               
               _buildSectionHeader("SYSTEM", secondaryTextColor),
               Container(
                 decoration: BoxDecoration(
                   color: cardColor,
                   borderRadius: BorderRadius.circular(14),
                 ),
                 child: _buildListTile(
                   icon: Icons.cleaning_services,
                   iconColor: const Color(0xFF8E8E93),
                   iconBgColor: const Color(0xFF8E8E93).withOpacity(0.1),
                   label: "Clear Cache",
                   onTap: _showClearCacheDialog,
                   showDivider: false,
                   textColor: textColor,
                   subtitle: "Free up space",
                 ),
               ),
               Padding(
                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                 child: Text(
                   "Clearing cache will remove temporary AI models and image previews. Your memories will remain safe.",
                   style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.3),
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
                             color: Colors.black,
                             borderRadius: BorderRadius.circular(5),
                           ),
                           child: const Icon(Icons.flash_on, color: Color(0xFF2DD4BF), size: 16),
                         ),
                         const SizedBox(width: 8),
                         Text(
                           "Rememo", 
                           style: TextStyle(fontWeight: FontWeight.bold, color: textColor)
                         ),
                       ],
                     ),
                     const SizedBox(height: 4),
                     Text(
                       "Version 2.4.0 (2024)",
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

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
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
    
    // Preview Logic...
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
                    Container(height: 12, width: double.infinity, color: const Color(0xFF3B82F6), margin: const EdgeInsets.only(top: 2)),
                ],
            )
        );
    } else if (mode == ThemeMode.dark) {
         preview = Container(
            color: const Color(0xFF18181B),
            padding: const EdgeInsets.all(4),
            child: Column(
                children: [
                    Container(height: 8, width: double.infinity, color: const Color(0xFF27272A), margin: const EdgeInsets.only(bottom: 2)),
                    Container(height: 8, width: 24, color: const Color(0xFF27272A)),
                     const Spacer(),
                    Container(height: 12, width: double.infinity, color: const Color(0xFF3F3F46), margin: const EdgeInsets.only(top: 2)), // Zinc 700
                ],
            )
        );
    } else {
        // System - Split
         preview = Row(
             children: [
                 Expanded(
                    child: Container(color: Colors.white, child: Column(children: [
                        Container(height: 8, width: double.infinity, color: const Color(0xFFF3F4F6), margin: const EdgeInsets.all(2)),
                    ])),
                 ),
                 Expanded(
                    child: Container(color: const Color(0xFF18181B), child: Column(children: [
                        Container(height: 8, width: double.infinity, color: const Color(0xFF27272A), margin: const EdgeInsets.all(2)),
                    ])),
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
            width: 80, // Approximate width
            height: 100, // Aspect 4:5
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? selectedColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: preview
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
                child: Container(width: 4, height: 4, decoration: BoxDecoration(color: selectedColor, shape: BoxShape.circle)),
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
  }) {
    final dividerColor = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF38383A) 
        : const Color(0xFFE5E5EA);

    return InkWell(
      onTap: onTap,
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
                  decoration: showDivider ? BoxDecoration(
                      border: Border(bottom: BorderSide(color: dividerColor, width: 0.5))
                  ) : null,
                  padding: showDivider ? const EdgeInsets.only(bottom: 12) : null,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(label, style: TextStyle(fontSize: 17, color: textColor)),
                                  if (subtitle != null)
                                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                              ],
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC), size: 20),
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
    // Re-use logic
    final count = await DatabaseHelper.instance.readAllMemoCards().then((l) => l.length);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Clear All Data?"),
        content: Text("This will permanently delete $count items. This action cannot be undone."),
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
             try { final file = File(card.imageUrl); if (await file.exists()) await file.delete(); } catch (_) {}
         }
      }
      await DatabaseHelper.instance.clear();
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data cleared")));
          setState(() {}); 
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

