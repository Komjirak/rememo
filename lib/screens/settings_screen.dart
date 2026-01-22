import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stribe/services/theme_service.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/widgets/folder_management_view.dart';
import 'package:stribe/services/database_helper.dart';
import 'package:stribe/models/memo_card.dart';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: ListView(
        children: [
          _buildSectionHeader("Appearance"),
          ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: const Text("Theme Mode"),
            trailing: DropdownButton<ThemeMode>(
              value: themeService.themeMode,
              underline: const SizedBox(),
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  themeService.setTheme(newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text("System"),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text("Light"),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text("Dark"),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader("Management"),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text("Folder Management"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FolderManagementWrapper(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Clear Cache", style: TextStyle(color: Colors.red)),
            subtitle: FutureBuilder<int>(
              future: _getMemoCount(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text("Calculating usage...");
                return Text("Currently storing ${snapshot.data} memos");
              },
            ),
            onTap: _showClearCacheDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Future<int> _getMemoCount() async {
    final cards = await DatabaseHelper.instance.readAllMemoCards();
    return cards.length;
  }

  Future<void> _showClearCacheDialog() async {
    final count = await _getMemoCount();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Data?"),
        content: Text("This will permanently delete all $count memos and their images. This action cannot be undone."),
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
            child: const Text("Delete All"),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      // 1. Delete all images
      final cards = await DatabaseHelper.instance.readAllMemoCards();
      for (var card in cards) {
         if (card.imageUrl.isNotEmpty && !card.imageUrl.startsWith('http')) {
             try {
                 final file = File(card.imageUrl);
                 if (await file.exists()) {
                     await file.delete();
                 }
             } catch (e) {
                 print("Error deleting file: $e");
             }
         }
      }

      // 2. Clear Database
      await DatabaseHelper.instance.clear();
      
      if (mounted) {
          setState(() {}); // Refresh UI
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("All data cleared successfully")),
          );
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error clearing data: $e")),
          );
      }
    }
  }
}

// Wrapper to handle recursive folder selection requirement if any, 
// though FolderManagementView seems designed to be pushed.
// Inspecting FolderManagementView usage in home_screen:
// FolderManagementView(onFolderSelected: _selectFolder)
// Since we are in Settings, selecting a folder might not "select" it for the home screen immediately unless we pass a callback or use shared state.
// However, "Folder Management" usually implies creating/renaming/deleting folders.
// If the user selects a folder here, what happens? 
// The prompt says "(2) folder management : current home screen 'folder management' menu also move to under settings."
// So likely just managing folders. 

class FolderManagementWrapper extends StatelessWidget {
  const FolderManagementWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // We pass a dummy callback because the original widget might require it.
    // Let's check FolderManagementView signature.
    // It requires `required this.onFolderSelected`.
    return FolderManagementView(
      onFolderSelected: (folder) {
        // If we want to support selecting a folder from settings to set as "Home context", we could.
        // But likely this is just for management (CRUD).
        // Clicking a folder in simple "management" view might just do nothing or close.
        // Let's pop if selected.
        // Actually, looking at home_screen, it pushes it.
      },
    );
  }
}
