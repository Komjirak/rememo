import 'package:flutter/material.dart';
import 'package:stribe/models/folder.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/widgets/folder_dialog.dart';
import 'package:stribe/services/database_helper.dart';

class FolderManagementView extends StatefulWidget {
  final Function(Folder?)? onFolderSelected;

  const FolderManagementView({
    super.key,
    this.onFolderSelected,
  });

  @override
  State<FolderManagementView> createState() => _FolderManagementViewState();
}

class _FolderManagementViewState extends State<FolderManagementView> {
  List<Folder> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    final folders = await DatabaseHelper.instance.readAllFolders();
    setState(() {
      _folders = folders;
      _isLoading = false;
    });
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _createFolder() async {
    await showDialog(
      context: context,
      builder: (context) => FolderDialog(
        onSave: (name, color) async {
          final folder = Folder(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            color: color,
            createdDate: DateTime.now(),
          );
          await DatabaseHelper.instance.createFolder(folder);
          _loadFolders();
        },
      ),
    );
  }

  Future<void> _editFolder(Folder folder) async {
    await showDialog(
      context: context,
      builder: (context) => FolderDialog(
        folder: folder,
        onSave: (name, color) async {
          final updatedFolder = folder.copyWith(name: name, color: color);
          await DatabaseHelper.instance.updateFolder(updatedFolder);
          _loadFolders();
        },
      ),
    );
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
        title: Text(
          '폴더 삭제',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '${folder.name} 폴더를 삭제하시겠습니까?\n폴더 안의 메모는 유지되며, 폴더가 지정되지 않은 상태로 변경됩니다.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withAlpha(26),
            ),
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteFolder(folder.id);
      _loadFolders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${folder.name} 삭제됨'),
            backgroundColor: Theme.of(context).cardColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '폴더 관리',
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).iconTheme.color),
            onPressed: _createFolder,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : _folders.isEmpty
              ? _buildEmptyState()
              : _buildFolderList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            '폴더가 없습니다',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 새 폴더를 만드세요',
            style: TextStyle(
              color: Theme.of(context).disabledColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderList() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _folders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return _buildFolderCard(folder);
      },
    );
  }

  Widget _buildFolderCard(Folder folder) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _hexToColor(folder.color).withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.folder,
            color: _hexToColor(folder.color),
            size: 28,
          ),
        ),
        title: Text(
          folder.name,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${folder.itemCount}개 항목',
          style: TextStyle(
            color: Theme.of(context).disabledColor,
            fontSize: 13,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: Theme.of(context).iconTheme.color,
                size: 20,
              ),
              onPressed: () => _editFolder(folder),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _deleteFolder(folder),
            ),
          ],
        ),
        onTap: () {
          widget.onFolderSelected?.call(folder);
          Navigator.pop(context);
        },
      ),
    );
  }
}
