import 'package:flutter/material.dart';
import 'dart:io';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/models/folder.dart';
import 'package:stribe/theme/app_theme.dart';

enum FilterOption { all, recent, favorites, folder }
enum MediaType { all, link, screenshot, photo }

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
  MediaType _mediaType = MediaType.all;
  String? _selectedFolderId;

  List<MemoCard> get _filteredCards {
    List<MemoCard> result = widget.cards;

    // 1. Basic Filters
    switch (_currentFilter) {
      case FilterOption.all:
        break;
      case FilterOption.recent:
        result = result.take(5).toList();
        break;
      case FilterOption.favorites:
        result = result.where((c) => c.isFavorite).toList();
        break;
      case FilterOption.folder:
        if (_selectedFolderId != null) {
          result = result.where((c) => c.folderId == _selectedFolderId).toList();
        }
        break;
    }

    // 2. Media Type Filter
    switch (_mediaType) {
      case MediaType.all:
        break;
      case MediaType.link:
        result = result.where((c) => c.sourceUrl != null && c.sourceUrl!.isNotEmpty).toList();
        break;
      case MediaType.screenshot:
        // Filter by 'Screenshot' tag or 'Imported' tag as proxy
        result = result.where((c) => 
            (c.sourceUrl == null || c.sourceUrl!.isEmpty) && 
            (c.tags.contains('Screenshot') || c.tags.contains('Imported'))
        ).toList();
        break;
      case MediaType.photo:
         // Everything else (Directly taken or just images without link/screenshot tag)
         result = result.where((c) => 
            (c.sourceUrl == null || c.sourceUrl!.isEmpty) && 
            (!c.tags.contains('Screenshot') && !c.tags.contains('Imported'))
         ).toList();
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip("ALL", FilterOption.all),
            const SizedBox(width: 8),
            _buildChip("Favorites", FilterOption.favorites),
            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: Colors.white.withAlpha(26)),
            const SizedBox(width: 12),
            _buildFolderDropdown(),
             const SizedBox(width: 8),
            _buildTypeDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final isSelected = _mediaType != MediaType.all;
    String label = 'Type';
    if (_mediaType == MediaType.link) label = 'Link';
    if (_mediaType == MediaType.screenshot) label = 'Screenshot';
    if (_mediaType == MediaType.photo) label = 'Photo';

    return PopupMenuButton<MediaType>(
      onSelected: (type) {
        setState(() {
           _mediaType = type;
        });
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      color: Theme.of(context).cardColor,
      itemBuilder: (context) => [
         _buildTypePopupItem('All Types', MediaType.all),
         const PopupMenuDivider(),
         _buildTypePopupItem('Link', MediaType.link, icon: Icons.link),
         _buildTypePopupItem('Screenshot', MediaType.screenshot, icon: Icons.smartphone),
         _buildTypePopupItem('Photo', MediaType.photo, icon: Icons.image),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentTeal.withAlpha(51)
              : Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentTeal.withAlpha(128)
                : Colors.white.withAlpha(13),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.accentTeal : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isSelected ? AppTheme.accentTeal : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<MediaType> _buildTypePopupItem(String text, MediaType type, {IconData? icon}) {
      final isSelected = _mediaType == type;
      return PopupMenuItem<MediaType>(
          value: type,
          child: Row(
            children: [
               if (icon != null) ...[
                 Icon(icon, size: 18, color: isSelected ? AppTheme.accentTeal : AppTheme.textSecondary),
                 const SizedBox(width: 12),
               ],
               Expanded(
                 child: Text(
                   text,
                   style: TextStyle(
                     color: isSelected ? AppTheme.accentTeal : AppTheme.textPrimary,
                     fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                   ),
                 ),
               ),
               if (isSelected) Icon(Icons.check, size: 18, color: AppTheme.accentTeal),
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
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      color: Theme.of(context).cardColor,
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
                  : Theme.of(context).colorScheme.onSurface.withAlpha(26))
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (selectedFolder != null
                    ? Color(int.parse(selectedFolder.color.replaceFirst('#', '0xFF'))).withAlpha(128)
                    : Theme.of(context).dividerColor)
                : Theme.of(context).dividerColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() {
        _currentFilter = option;
        // Reset Media Filter if switching to Favorites (optional, but keeps it simple)
        // _mediaType = MediaType.all; 
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? AppTheme.bgWhite10 : AppTheme.bgWhite5)
              : (isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? (isSelected ? AppTheme.borderWhite10 : AppTheme.dividerColor)
                : (isSelected
                    ? Colors.transparent
                    : Theme.of(context).dividerColor),
          ),
          boxShadow: isDark || isSelected
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isDark
                ? (isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                : (isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaTypeChip(String label, MediaType type) {
    final isSelected = _mediaType == type;
    return GestureDetector(
      onTap: () => setState(() => _mediaType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentTeal.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentTeal.withOpacity(0.5)
                : Colors.white.withAlpha(13),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.accentTeal : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(MemoCard card) {
    // If the card is processing, do not allow swipe-to-delete
    if (card.isProcessing) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.accentTeal.withOpacity(0.3), // Highlight slightly
          ),
        ),
        child: Row(
          children: [
            // Thumbnail with Loader
            Container(
              width: 80,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentTeal.withOpacity(0.2),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(card.imageUrl, sourceUrl: card.sourceUrl, isProcessing: true),
                  Container(
                    color: Colors.black45, // Dim overlay
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentTeal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.accentTeal),
                      ),
                      const Text(
                        "Analyzing...",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentTeal,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.title.isEmpty ? "Processing..." : card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDisabled, // Dim text
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "AI is analyzing content to generate insights...",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.borderColor
                  : Theme.of(context).dividerColor,
            ),
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? null
                : [
                    AppTheme.shadowSoft,
                  ],
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 96,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1F2937) // gray-800
                      : Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.dividerColor // white/5
                        : Theme.of(context).dividerColor,
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
                        // Source/Category badge
                        _buildCategoryBadge(card),
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
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(context).textTheme.bodyMedium?.color,
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

  Widget _buildThumbnail(String url, {String? sourceUrl, bool isProcessing = false}) {
    // If we have a URL, try to load it (whether local or network)
    if (url.isNotEmpty) {
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
        }
    }
    
    // If no URL or file loading failed, show placeholder based on type
    return _buildPlaceholder(hasUrl: sourceUrl != null && sourceUrl.isNotEmpty);
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

  Widget _buildCategoryBadge(MemoCard card) {
    String sourceLabel = 'MANUAL';
    if (card.sourceUrl != null && card.sourceUrl!.isNotEmpty) {
       try {
         final uri = Uri.parse(card.sourceUrl!.startsWith('http') ? card.sourceUrl! : 'https://${card.sourceUrl!}');
         sourceLabel = uri.host.replaceFirst('www.', '').toUpperCase();
       } catch (e) {
         sourceLabel = 'WEB';
       }
    } else if (card.tags.contains('Screenshot')) {
        sourceLabel = 'SCREENSHOT';
    } else if (card.tags.contains('Imported')) {
        sourceLabel = 'IMPORTED';
    } 

    final color = _getCategoryColor(card.category);
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
        sourceLabel,
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
