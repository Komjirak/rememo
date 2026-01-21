import 'package:flutter/material.dart';
import 'dart:io';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/models/folder.dart';
import 'package:stribe/theme/app_theme.dart';

enum FilterOption { all, recent, favorites, folder }

class LibraryListView extends StatefulWidget {
  final List<MemoCard> cards;
  final List<Folder> folders;
  final Function(MemoCard) onSelect;
  final Function(MemoCard)? onDelete;
  final Function(MemoCard, String)? onTitleEdit;
  final VoidCallback? onSearch;

  const LibraryListView({
    super.key,
    required this.cards,
    this.folders = const [],
    required this.onSelect,
    this.onDelete,
    this.onTitleEdit,
    this.onSearch,
  });

  @override
  State<LibraryListView> createState() => _LibraryListViewState();
}

class _LibraryListViewState extends State<LibraryListView> {
  FilterOption _currentFilter = FilterOption.all;
  String? _selectedFolderId;

  List<MemoCard> get _filteredCards {
    List<MemoCard> result;

    switch (_currentFilter) {
      case FilterOption.all:
        result = widget.cards;
        break;
      case FilterOption.recent:
        result = widget.cards.take(5).toList();
        break;
      case FilterOption.favorites:
        result = widget.cards.where((c) => c.isFavorite).toList();
        break;
      case FilterOption.folder:
        if (_selectedFolderId != null) {
          result = widget.cards.where((c) => c.folderId == _selectedFolderId).toList();
        } else {
          result = widget.cards;
        }
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        _buildFilterChips(),

        // Card list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
            itemCount: _filteredCards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              return _buildCard(_filteredCards[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // 기본 필터 칩들
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip("All Memories", FilterOption.all),
                  const SizedBox(width: 8),
                  _buildChip("Recent", FilterOption.recent),
                  const SizedBox(width: 8),
                  _buildChip("Favorites", FilterOption.favorites),
                ],
              ),
            ),
          ),
          // 폴더 드롭다운
          if (widget.folders.isNotEmpty) ...[
            const SizedBox(width: 12),
            _buildFolderDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildFolderDropdown() {
    final isSelected = _currentFilter == FilterOption.folder;
    final selectedFolder = isSelected && _selectedFolderId != null
        ? widget.folders.firstWhere(
            (f) => f.id == _selectedFolderId,
            orElse: () => widget.folders.first,
          )
        : null;

    return PopupMenuButton<String?>(
      onSelected: (folderId) {
        setState(() {
          if (folderId == null) {
            _currentFilter = FilterOption.all;
            _selectedFolderId = null;
          } else {
            _currentFilter = FilterOption.folder;
            _selectedFolderId = folderId;
          }
        });
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withAlpha(20)),
      ),
      color: AppTheme.cardDark,
      itemBuilder: (context) => [
        // 전체 보기 옵션
        PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 18,
                color: !isSelected ? AppTheme.accentTeal : AppTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                '전체 보기',
                style: TextStyle(
                  color: !isSelected ? AppTheme.accentTeal : AppTheme.textPrimary,
                  fontWeight: !isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (!isSelected) ...[
                const Spacer(),
                Icon(Icons.check, size: 18, color: AppTheme.accentTeal),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        // 폴더 목록
        ...widget.folders.map((folder) {
          final folderColor = Color(int.parse(folder.color.replaceFirst('#', '0xFF')));
          final isFolderSelected = _selectedFolderId == folder.id;
          return PopupMenuItem<String?>(
            value: folder.id,
            child: Row(
              children: [
                Icon(
                  Icons.folder,
                  size: 18,
                  color: folderColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        folder.name,
                        style: TextStyle(
                          color: isFolderSelected ? folderColor : AppTheme.textPrimary,
                          fontWeight: isFolderSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${folder.itemCount}개',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFolderSelected)
                  Icon(Icons.check, size: 18, color: folderColor),
              ],
            ),
          );
        }),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (selectedFolder != null
                  ? Color(int.parse(selectedFolder.color.replaceFirst('#', '0xFF'))).withAlpha(51)
                  : Colors.white.withAlpha(26))
              : Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (selectedFolder != null
                    ? Color(int.parse(selectedFolder.color.replaceFirst('#', '0xFF'))).withAlpha(128)
                    : Colors.white.withAlpha(26))
                : Colors.white.withAlpha(13),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 14,
              color: isSelected && selectedFolder != null
                  ? Color(int.parse(selectedFolder.color.replaceFirst('#', '0xFF')))
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              isSelected && selectedFolder != null ? selectedFolder.name : '폴더',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected && selectedFolder != null
                    ? Color(int.parse(selectedFolder.color.replaceFirst('#', '0xFF')))
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isSelected && selectedFolder != null
                  ? Color(int.parse(selectedFolder.color.replaceFirst('#', '0xFF')))
                  : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, FilterOption option) {
    final isSelected = _currentFilter == option;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withAlpha(26) // 10%
              : Colors.white.withAlpha(13), // 5%
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withAlpha(26)
                : Colors.white.withAlpha(13),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(MemoCard card) {
    return Dismissible(
      key: Key(card.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // 삭제 확인 다이얼로그 표시
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.white.withAlpha(20),
                ),
              ),
              title: const Text(
                '메모 삭제',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                '이 메모를 삭제하시겠습니까?\n삭제된 메모는 복구할 수 없습니다.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
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
            );
          },
        ) ?? false;
      },
      onDismissed: (direction) {
        widget.onDelete?.call(card);
        
        // 스낵바로 피드백 제공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${card.title} 삭제됨'),
            backgroundColor: AppTheme.cardDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(51), // 20%
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.red.withAlpha(77), // 30%
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => widget.onSelect(card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withAlpha(20), // ~8%
            ),
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937), // gray-800
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(13),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildThumbnail(card.imageUrl, sourceUrl: card.sourceUrl),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        _buildCategoryBadge(card.category),
                        const SizedBox(height: 8),

                        // Title (editable)
                        GestureDetector(
                          onTap: () => _showTitleEditDialog(card),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  card.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Description
                        Text(
                          _getCleanSummary(card.summary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          card.captureDate,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
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

  Widget _buildThumbnail(String url, {String? sourceUrl}) {
    // 이미지 URL이 비어있는 경우
    if (url.isEmpty) {
      return _buildPlaceholder(hasUrl: sourceUrl != null && sourceUrl.isNotEmpty);
    }

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        opacity: const AlwaysStoppedAnimation(0.8),
        errorBuilder: (_, __, ___) => _buildPlaceholder(hasUrl: sourceUrl != null && sourceUrl.isNotEmpty),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          opacity: const AlwaysStoppedAnimation(0.8),
          errorBuilder: (_, __, ___) => _buildPlaceholder(hasUrl: sourceUrl != null && sourceUrl.isNotEmpty),
        );
      }
      return _buildPlaceholder(hasUrl: sourceUrl != null && sourceUrl.isNotEmpty);
    }
  }

  Widget _buildPlaceholder({bool hasUrl = false}) {
    return Container(
      color: const Color(0xFF1F2937),
      child: Center(
        child: hasUrl
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.link,
                  color: AppTheme.accentTeal,
                  size: 24,
                ),
              )
            : Icon(
                Icons.image,
                color: AppTheme.textDisabled,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final color = _getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(13), // 5%
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withAlpha(26), // 10%
        ),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.withAlpha(204), // 80%
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'design':
        return AppTheme.accentTeal;
      case 'tech':
        return const Color(0xFF60A5FA); // blue-400
      case 'inspiration':
        return const Color(0xFFC084FC); // purple-400
      case 'food':
        return const Color(0xFF4ADE80); // green-400
      case 'shopping':
        return const Color(0xFFFB923C); // orange-400
      case 'work':
        return const Color(0xFFF472B6); // pink-400
      default:
        return AppTheme.accentTeal;
    }
  }

  String _getCleanSummary(String summary) {
    // Remove bullet points for cleaner display
    return summary
        .replaceAll('• ', '')
        .replaceAll('\n\n', ' ')
        .replaceAll('\n', ' ')
        .trim();
  }

  void _showTitleEditDialog(MemoCard card) {
    final controller = TextEditingController(text: card.title);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withAlpha(20),
            ),
          ),
          title: const Text(
            '제목 수정',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: '새로운 제목을 입력하세요',
              hintStyle: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white.withAlpha(13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withAlpha(26),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withAlpha(26),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.accentTeal.withAlpha(128),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                widget.onTitleEdit?.call(card, value.trim());
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '취소',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  widget.onTitleEdit?.call(card, newTitle);
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.accentTeal.withAlpha(26),
              ),
              child: Text(
                '저장',
                style: TextStyle(
                  color: AppTheme.accentTeal,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
