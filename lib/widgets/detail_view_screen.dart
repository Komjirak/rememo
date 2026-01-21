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
  final VoidCallback? onDelete;
  final Function(String)? onOpenLink;
  final Function(MemoCard)? onUpdate;

  const DetailViewScreen({
    super.key,
    required this.card,
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
            child: Column(
              children: [
                // Header with blur effect
                _buildBlurHeader(),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Image section
                      _buildImageSection(),
                      const SizedBox(height: 32),

                      // Title and metadata
                      _buildTitleSection(),
                      const SizedBox(height: 32),

                      // AI Summary
                      _buildAISummarySection(),
                      const SizedBox(height: 24),

                      // Original Message (full OCR text)
                      _buildOriginalMessageSection(),
                      const SizedBox(height: 24),

                      // Tags
                      _buildTagsSection(),
                      const SizedBox(height: 24),

                      // Personal Note
                      _buildPersonalNoteSection(),
                      const SizedBox(height: 32),

                      // Return to Original button
                      _buildReturnToOriginalSection(),
                      const SizedBox(height: 24),

                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ],
                          ),
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
              // Back button
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              // Title with sparkle icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppTheme.accentTeal,
                    ),
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

              // More button
              IconButton(
                icon: const Icon(Icons.more_horiz, size: 24, color: AppTheme.textSecondary),
                onPressed: _showMoreOptions,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _expandImage,
      child: Container(
                      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.dividerColor),
                        boxShadow: [
                          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
                          ),
                        ],
                      ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
              // Image
              AspectRatio(
                aspectRatio: 3 / 4,
                child: _buildImage(_card.imageUrl),
              ),

              // Gradient overlay
              Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // "Tap to expand" indicator
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.fullscreen,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tap to expand',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite() async {
    final updatedCard = _card.copyWith(isFavorite: !_card.isFavorite);
    await DatabaseHelper.instance.update(updatedCard);
    setState(() {
      _card = updatedCard;
    });
    widget.onUpdate?.call(updatedCard);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedCard.isFavorite ? '즐겨찾기에 추가됨' : '즐겨찾기에서 제거됨',
          ),
          backgroundColor: AppTheme.cardDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with favorite star
        Row(
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
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _toggleFavorite,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _card.isFavorite
                      ? Colors.amber.withAlpha(26)
                      : Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _card.isFavorite
                        ? Colors.amber.withAlpha(77)
                        : Colors.white.withAlpha(26),
                  ),
                ),
                child: Icon(
                  _card.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 24,
                  color: _card.isFavorite ? Colors.amber : AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date and URL
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            // Date
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  _card.captureDate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                ),
              ],
            ),

            // URL (if available)
            if (_card.sourceUrl != null)
              GestureDetector(
                onTap: () => widget.onOpenLink?.call(_card.sourceUrl!),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public, size: 14, color: AppTheme.accentTeal),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _extractDomain(_card.sourceUrl!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.accentTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAISummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
        children: [
          Container(
              padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppTheme.accentTeal,
              ),
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Text(
            _card.summary,
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

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.label_outline, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              'AUTOMATED TAGS',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted,
            letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _card.tags.asMap().entries.map((entry) {
            final index = entry.key;
            final tag = entry.value;
            return _buildTag(tag, isFirst: index == 0);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOriginalMessageSection() {
    // 원본 텍스트가 없으면 노출하지 않음
    final original = _card.ocrText;
    if (original == null || original.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                original,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: original));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Original message copied'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentTeal,
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text(
                    'Copy all',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String tag, {bool isFirst = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isFirst ? AppTheme.accentTeal.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isFirst ? AppTheme.accentTeal.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        tag.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isFirst ? AppTheme.accentTeal : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

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
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 4,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.6,
                      fontWeight: FontWeight.w300,
                    ),
                decoration: InputDecoration(
                  hintText: 'Add your thoughts or why you saved this...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted.withOpacity(0.5),
                      ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Text(
                _isNoteModified ? 'SAVING...' : 'AUTO-SAVED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// PRD 7. 원본 복귀 UX 정책
  /// - source_url 있음: 1탭으로 URL 열기
  /// - URL 없음: 스크린샷 열기
  /// - 둘 다 있음: URL 우선, 스크린샷 보조
  /// - 둘 다 없음: OCR 키워드 기반 검색 링크
  Widget _buildReturnToOriginalSection() {
    final hasUrl = _card.sourceUrl != null && _card.sourceUrl!.isNotEmpty;
    final hasImage = _card.imageUrl.isNotEmpty && !_card.imageUrl.startsWith('http');
    final hasOcrText = _card.ocrText != null && _card.ocrText!.isNotEmpty;

    // 둘 다 없는 경우: 검색 링크 제공
    if (!hasUrl && !hasImage) {
      if (!hasOcrText) return const SizedBox.shrink();

      return _buildSearchFallbackButton();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              'RETURN TO ORIGINAL',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // URL 버튼 (있는 경우 - 우선 표시)
        if (hasUrl)
          GestureDetector(
            onTap: () => widget.onOpenLink?.call(_card.sourceUrl!),
            child: Container(
              width: double.infinity,
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
                    child: const Icon(
                      Icons.open_in_new,
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
                          '원본 페이지 열기',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _extractDomain(_card.sourceUrl!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.accentTeal,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.accentTeal,
                  ),
                ],
              ),
            ),
          ),

        // 스크린샷이 있고 URL도 있는 경우 (보조 옵션)
        if (hasUrl && hasImage) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _expandImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.image_outlined,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '스크린샷 보기',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.fullscreen,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],

        // URL 없고 스크린샷만 있는 경우 (메인 옵션)
        if (!hasUrl && hasImage)
          GestureDetector(
            onTap: _expandImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '원본 스크린샷 보기',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '탭하여 전체 화면으로 보기',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.fullscreen,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// OCR 텍스트 기반 검색 링크 (URL도 이미지도 없는 경우)
  Widget _buildSearchFallbackButton() {
    final searchQuery = _extractSearchKeywords(_card.ocrText ?? '');
    final searchUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              'FIND RELATED CONTENT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => widget.onOpenLink?.call(searchUrl),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.travel_explore,
                    color: Colors.blue.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '키워드로 검색하기',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"$searchQuery"',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  color: Colors.blue.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// OCR 텍스트에서 검색 키워드 추출
  String _extractSearchKeywords(String text) {
    // 줄 단위로 나누고 의미있는 텍스트 추출
    final lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 3 && l.length < 50)
        .where((l) => !RegExp(r'^\d{1,2}:\d{2}$').hasMatch(l)) // 시간 제외
        .where((l) => !RegExp(r'^\d+%$').hasMatch(l)) // 배터리 % 제외
        .where((l) => !l.contains('http')) // URL 제외
        .toList();

    if (lines.isEmpty) return _card.title;

    // 첫 번째 의미있는 줄 사용 (최대 50자)
    final firstLine = lines.first;
    return firstLine.length > 50 ? firstLine.substring(0, 50) : firstLine;
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Move to Folder',
                icon: Icons.folder_outlined,
                onTap: _showFolderPicker,
                isPrimary: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                label: 'Share',
                icon: Icons.share_outlined,
                onTap: _shareCard,
                isPrimary: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: 'Delete',
          icon: Icons.delete_outline,
          onTap: _showDeleteDialog,
          isPrimary: false,
          isDanger: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.accentTeal : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isDanger
                ? Colors.red.withOpacity(0.3)
                : isPrimary
                    ? AppTheme.accentTeal
                    : Colors.white.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDanger
                  ? Colors.red.shade400
                  : isPrimary
                      ? AppTheme.backgroundDark
                      : AppTheme.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isDanger
                        ? Colors.red.shade400
                        : isPrimary
                            ? AppTheme.backgroundDark
                            : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('https')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppTheme.cardDark,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: AppTheme.accentTeal,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.cardDark,
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: AppTheme.textMuted),
          ),
        ),
      );
    } else {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.cardDark,
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: AppTheme.textMuted),
          ),
        ),
      );
    }
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }
}

// Full screen image viewer
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
              child: imageUrl.startsWith('https')
                  ? Image.network(imageUrl, fit: BoxFit.contain)
                  : Image.file(File(imageUrl), fit: BoxFit.contain),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
