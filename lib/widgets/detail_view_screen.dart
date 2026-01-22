import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/models/folder.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:stribe/services/database_helper.dart';
import 'dart:io';
import 'dart:ui';

class DetailViewScreen extends StatefulWidget {
  final MemoCard card;
  final List<Folder>? folders;
  final VoidCallback? onDelete;
  final Function(String)? onOpenLink;
  final Function(MemoCard)? onUpdate;

  const DetailViewScreen({
    super.key,
    required this.card,
    this.folders,
    this.onDelete,
    this.onOpenLink,
    this.onUpdate,
  });

  @override
  State<DetailViewScreen> createState() => _DetailViewScreenState();
}

class _DetailViewScreenState extends State<DetailViewScreen> {
  late MemoCard _card;
  late TextEditingController _noteController;
  late TextEditingController _urlController;
  bool _isNoteModified = false;
  bool _isUrlModified = false;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _noteController = TextEditingController(text: _card.personalNote ?? '');
    _urlController = TextEditingController(text: _card.sourceUrl ?? '');
    _noteController.addListener(_onNoteChanged);
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _urlController.removeListener(_onUrlChanged);
    _noteController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    if (!_isUrlModified) {
      setState(() {
        _isUrlModified = true;
      });
    }
  }

  void _onNoteChanged() {
    if (!_isNoteModified) {
      setState(() {
        _isNoteModified = true;
      });
    }
    // Auto-save after 1 second of no typing
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _noteController.text != _card.personalNote) {
        _saveNote();
      }
    });
  }

  void _saveNote() {
    final updatedCard = _card.copyWith(personalNote: _noteController.text);
    setState(() {
      _card = updatedCard;
      _isNoteModified = false;
    });
    widget.onUpdate?.call(updatedCard);
  }

  void _expandImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageView(imageUrl: _card.imageUrl),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _showFolderPicker() async {
    var folders = await DatabaseHelper.instance.readAllFolders();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '폴더로 이동',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // 새 폴더 만들기 버튼
                      TextButton.icon(
                        onPressed: () async {
                          final newFolder = await _showCreateFolderDialog();
                          if (newFolder != null) {
                            // 폴더 목록 새로고침
                            folders = await DatabaseHelper.instance.readAllFolders();
                            setModalState(() {});
                          }
                        },
                        icon: Icon(
                          Icons.create_new_folder_outlined,
                          size: 18,
                          color: AppTheme.accentTeal,
                        ),
                        label: Text(
                          '새 폴더',
                          style: TextStyle(
                            color: AppTheme.accentTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // No folder option
                          ListTile(
                            leading: Icon(
                              Icons.folder_off_outlined,
                              color: AppTheme.textSecondary,
                            ),
                            title: Text(
                              '폴더 없음',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () async {
                              await DatabaseHelper.instance.moveMemoCardToFolder(_card.id, null);
                              _card = _card.copyWith(folderId: null);
                              widget.onUpdate?.call(_card);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('폴더에서 제거됨'),
                                    backgroundColor: AppTheme.cardDark,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),

                          const Divider(color: AppTheme.dividerColor),

                          // Folders list
                          ...folders.map((folder) => ListTile(
                            leading: Icon(
                              Icons.folder,
                              color: _hexToColor(folder.color),
        ),
        title: Text(
                              folder.name,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${folder.itemCount}개 항목',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                fontSize: 12,
              ),
                            ),
                            trailing: _card.folderId == folder.id
                                ? Icon(Icons.check_circle, color: AppTheme.accentTeal)
                                : null,
                            onTap: () async {
                              await DatabaseHelper.instance.moveMemoCardToFolder(_card.id, folder.id);
                              _card = _card.copyWith(folderId: folder.id);
                              widget.onUpdate?.call(_card);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${folder.name}로 이동됨'),
                                    backgroundColor: AppTheme.cardDark,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Folder?> _showCreateFolderDialog() async {
    final nameController = TextEditingController();
    String selectedColor = '#14B8A6'; // Default teal

    final colors = [
      '#14B8A6', // teal
      '#60A5FA', // blue
      '#C084FC', // purple
      '#4ADE80', // green
      '#FB923C', // orange
      '#F472B6', // pink
      '#FACC15', // yellow
      '#EF4444', // red
    ];

    return showDialog<Folder>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withAlpha(20)),
              ),
              title: const Text(
                '새 폴더 만들기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '폴더 이름',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: Colors.white.withAlpha(13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '폴더 색상',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: colors.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _hexToColor(color),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
        ),
        actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final folder = Folder(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      color: selectedColor,
                      createdDate: DateTime.now(),
                    );

                    await DatabaseHelper.instance.createFolder(folder);
                    if (mounted) {
                      Navigator.pop(ctx, folder);
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.accentTeal.withAlpha(26),
                  ),
                  child: Text(
                    '만들기',
                    style: TextStyle(
                      color: AppTheme.accentTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog() {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Memory',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
              ),
        ),
        content: Text(
          'Are you sure you want to delete this memory? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
              widget.onDelete?.call();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              }

  void _shareCard() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Navigate to edit screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: AppTheme.textSecondary),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Archive functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppTheme.textSecondary),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                _shareCard();
              },
            ),
            const Divider(color: AppTheme.borderColor),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteDialog();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120), // Space for floating bar
            child: Column(
              children: [
                // Header with blur effect (Back button & More options)
                _buildBlurHeader(),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Title (Editable)
                      _buildTitleSection(),
                      const SizedBox(height: 16),

                      // 2. Time & Link Info
                      _buildMetadataSection(),
                      const SizedBox(height: 24),

                      // 3. Auto Tags & Add Tag
                      _buildTagsSection(),
                      const SizedBox(height: 24),

                      // 4. Return to Original (Moved up)
                      _buildReturnToOriginalSection(),
                      const SizedBox(height: 32),

                      // 5. AI Summary (with Copy)
                      _buildAISummarySection(),
                      const SizedBox(height: 24),

                      // 6. Personal Note
                      _buildPersonalNoteSection(),
                      const SizedBox(height: 32),

                      // 7. Original Message
                      _buildOriginalMessageSection(),
                      
                      const SizedBox(height: 24),
                      // Image section (Optional, put at bottom or keep at top? 
                      // User didn't specify Image position in the numbered list, but usually it's top or part of content.
                      // User list: 1) Title 2) Time... 
                      // "List exposure order... 1) Title 2) Time..." 
                      // Usually Image is visually dominant. I'll put it at the very top under header, or 
                      // integrated. But strictly following the list might mean Image is less important?
                      // "Detail screen exposure order 1) Title 2) Time & Link 3) Auto Tags 4) Original Page Open 5) AI Summary 6) Personal Note 7) Original Message"
                      // It doesn't mention the Image itself!
                      // But "Original Page Open" -> might imply the content.
                      // If I hide the image, it's bad.
                      // I will place the Image at the very top (above Title), as visual context is usually implied before Title in such apps, OR
                      // maybe the user considers "Title" as the first strict Text element.
                      // I'll keep Image at top for better UX, then Title.
                      // Wait, current layout has Image first.
                      // If I put Image first, then Title, it matches standard.
                      // I will keep Image at Top.
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Action Bar (Bottom)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildFloatingActionBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 16,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark.withOpacity(0.8),
            border: const Border(
              bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.accentTeal),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MEMORY INSIGHT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          letterSpacing: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, size: 24, color: AppTheme.textSecondary),
                onPressed: _showMoreOptions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Title Section (Editable)
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image at top (Context)
        _buildImageSection(),
        const SizedBox(height: 24),
        
        GestureDetector(
          onTap: () => _showTitleEditDialog(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _card.title,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Metadata Section (Time & Link)
  Widget _buildMetadataSection() {
    return Row(
      children: [
        Icon(Icons.schedule, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text(
          _card.captureDate,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
        ),
        if (_card.sourceUrl != null && _card.sourceUrl!.isNotEmpty) ...[
          const SizedBox(width: 16),
          Container(width: 1, height: 12, color: AppTheme.dividerColor),
          const SizedBox(width: 16),
          Icon(Icons.link, size: 14, color: AppTheme.accentTeal),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onOpenLink?.call(_card.sourceUrl!),
              child: Text(
                _extractDomain(_card.sourceUrl!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.accentTeal,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.accentTeal.withOpacity(0.5),
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 3. Tags Section (Auto Tags & Add)
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.label_outline, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'TAGS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _showAddTagDialog,
              child: Row(
                children: [
                  Icon(Icons.add, size: 14, color: AppTheme.accentTeal),
                  const SizedBox(width: 4),
                  Text(
                    'Add Tag',
                    style: TextStyle(
                      color: AppTheme.accentTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._card.tags.map((tag) => _buildTag(tag)),
            if (_card.tags.isEmpty)
              Text(
                'No tags yet',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ],
    );
  }

  // 4. Return to Original
  Widget _buildReturnToOriginalSection() {
    final hasUrl = _card.sourceUrl != null && _card.sourceUrl!.isNotEmpty;
    // ... logic consistent with original ...
    // Reusing the logic from before but ensuring simplified display if needed
    
    // For brevity in valid replacement, I'll paste the full logic
    final hasImage = _card.imageUrl.isNotEmpty && !_card.imageUrl.startsWith('http');
    final hasOcrText = _card.ocrText != null && _card.ocrText!.isNotEmpty;

    if (!hasUrl && !hasImage) {
      if (!hasOcrText) return const SizedBox.shrink();
      return _buildSearchFallbackButton();
    }

    return GestureDetector(
      onTap: () {
        if (hasUrl) {
            widget.onOpenLink?.call(_card.sourceUrl!);
        } else if (hasImage) {
            _expandImage();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentTeal.withOpacity(0.15),
              AppTheme.accentTeal.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accentTeal.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasUrl ? Icons.open_in_new : Icons.image,
                color: AppTheme.accentTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasUrl ? 'Open Original Link' : 'View Original Image',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (hasUrl)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _extractDomain(_card.sourceUrl!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentTeal,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.accentTeal),
          ],
        ),
      ),
    );
  }

  // 5. AI Summary
  Widget _buildAISummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.accentTeal),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI SUMMARY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            // Copy Button
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _card.summary));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Summary copied to clipboard'), duration: Duration(seconds: 1)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.copy, size: 16, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Text(
            _card.summary.isEmpty ? 'No summary available.' : _card.summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                ),
          ),
        ),
      ],
    );
  }

  // 6. Personal Note
  Widget _buildPersonalNoteSection() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note_outlined, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              'PERSONAL NOTE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: TextField(
            controller: _noteController,
             maxLines: null, // Auto expand
             minLines: 3,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                  fontWeight: FontWeight.w300,
                ),
            decoration: InputDecoration(
              hintText: 'Add your thoughts...',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.5),
                  ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }
  
  // 7. Original Message (Cleaned)
  Widget _buildOriginalMessageSection() {
    final original = _card.ocrText;
    if (original == null || original.trim().isEmpty) return const SizedBox.shrink();

    // Clean whitespace
    final cleanedText = original.replaceAll(RegExp(r'[\r\n]{3,}'), '\n\n').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.article_outlined, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'ORIGINAL MESSAGE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
             // Copy Button
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: cleanedText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Original text copied'), duration: Duration(seconds: 1)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.copy, size: 16, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Text(
            cleanedText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                  fontSize: 14,
                ),
          ),
        ),
      ],
    );
  }

  // Floating Action Bar
  Widget _buildFloatingActionBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(0.8),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFloatingActionButton(
                icon: Icons.folder_open,
                label: 'Move',
                onTap: _showFolderPicker,
              ),
              Container(width: 1, height: 24, color: Colors.white.withOpacity(0.1)),
              _buildFloatingActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: _shareCard,
              ),
              Container(width: 1, height: 24, color: Colors.white.withOpacity(0.1)),
              _buildFloatingActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: _showDeleteDialog,
                isDangerous: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isDangerous ? Colors.red.shade400 : AppTheme.textPrimary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDangerous ? Colors.red.shade400 : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  void _showTitleEditDialog() {
    final controller = TextEditingController(text: _card.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Title', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter title',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentTeal)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentTeal, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                    final updated = _card.copyWith(title: newTitle);
                    await DatabaseHelper.instance.update(updated);
                   setState(() => _card = updated);
                    widget.onUpdate?.call(updated);
                }
                if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.accentTeal)),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add Tag', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter tag',
            hintStyle: TextStyle(color: AppTheme.textMuted),
             enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentTeal)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentTeal, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
                final newTag = controller.text.trim();
                if (newTag.isNotEmpty && !_card.tags.contains(newTag)) {
                    final updatedTags = List<String>.from(_card.tags)..add(newTag);
                    final updated = _card.copyWith(tags: updatedTags);
                    await DatabaseHelper.instance.update(updated);
                    setState(() => _card = updated);
                    widget.onUpdate?.call(updated);
                }
                if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: AppTheme.accentTeal)),
          ),
        ],
      ),
    );
  }

  // Reuse existing methods like _buildImageSection, _buildTag, _extractDomain, _buildSearchFallbackButton, _hexToColor, _expandImage, etc.
  // The replace tool will keep methods outside the range I replaced unless I include them.
  // I must be careful about what I replaced. 
  // I replaced 'build' method and added new methods.
  // I need to ensure I didn't delete _buildImageSection, _buildTag, etc if they were inside the range.
  // I am replacing from 504 to 1573. That's the Text of the ENTIRE file from build method downwards.
  // So I MUST include ALL the helper methods I didn't want to change, or implement them again.
  // This is a big replacement. I will include the necessary helper methods in the ReplacementContent.
  
  // Implementation of missing helpers from previous context:
  
  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _expandImage,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 3 / 2, // Slightly wider
                child: _buildImage(_card.imageUrl),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        tag,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSearchFallbackButton() {
     final searchQuery = _extractSearchKeywords(_card.ocrText ?? '');
     return GestureDetector(
        onTap: () => widget.onOpenLink?.call('https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppTheme.accentTeal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search for "$searchQuery"',
                  style: const TextStyle(color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ],
          ),
        ),
     );
  }

  String _extractSearchKeywords(String text) {
      if (text.isEmpty) return _card.title;
      final lines = text.split('\n');
      for (final line in lines) {
        if (line.trim().length > 5) return line.trim();
      }
      return _card.title; 
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, color: AppTheme.accentTeal));
        },
        errorBuilder: (_, __, ___) => Container(color: AppTheme.cardDark, child: const Icon(Icons.broken_image, color: AppTheme.textMuted)),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return Container(color: AppTheme.cardDark, child: const Icon(Icons.broken_image, color: AppTheme.textMuted));
    }
  }

  void _toggleFavorite() async {
    final updatedCard = _card.copyWith(isFavorite: !_card.isFavorite);
    await DatabaseHelper.instance.update(updatedCard);
    setState(() => _card = updatedCard);
    widget.onUpdate?.call(updatedCard);
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }
}

class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildImage(imageUrl),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
             child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
      return const Icon(Icons.broken_image, color: Colors.white);
    }
  }
}
