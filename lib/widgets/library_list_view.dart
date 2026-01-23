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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
            itemCount: _filteredCards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
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
            Container(width: 1, height: 20, color: Theme.of(context).dividerColor),
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
    
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              ? primaryColor.withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor.withOpacity(0.3)
                : Theme.of(context).dividerColor,
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
                color: isSelected ? primaryColor : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isSelected ? primaryColor : Theme.of(context).iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<MediaType> _buildTypePopupItem(String text, MediaType type, {IconData? icon}) {
      final isSelected = _mediaType == type;
      final primaryColor = Theme.of(context).primaryColor;
      
      return PopupMenuItem<MediaType>(
          value: type,
          child: Row(
            children: [
               if (icon != null) ...[
                 Icon(icon, size: 18, color: isSelected ? primaryColor : Theme.of(context).iconTheme.color),
                 const SizedBox(width: 12),
               ],
               Expanded(
                 child: Text(
                   text,
                   style: TextStyle(
                     color: isSelected ? primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                     fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                   ),
                 ),
               ),
               if (isSelected) Icon(Icons.check, size: 18, color: primaryColor),
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
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                color: !isSelected ? primaryColor : Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 12),
              Text(
                '전체 보기',
                style: TextStyle(
                  color: !isSelected ? primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: !isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (!isSelected) ...[
                const Spacer(),
                Icon(Icons.check, size: 18, color: primaryColor),
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
                          color: isFolderSelected ? folderColor : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: isFolderSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${folder.itemCount}개',
                        style: TextStyle(
                          color: Theme.of(context).disabledColor,
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
                  ? Color(int.parse(selectedFolder.color.replaceFirst('#', '0xFF'))).withOpacity(0.1)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.05))
              : (isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (selectedFolder != null
                    ? Color(int.parse(selectedFolder.color.replaceFirst('#', '0xFF'))).withOpacity(0.3)
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
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 6),
            Text(
              isSelected && selectedFolder != null ? selectedFolder.name : '폴더',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected && selectedFolder != null
                    ? Color(int.parse(selectedFolder.color.replaceFirst('#', '0xFF')))
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isSelected && selectedFolder != null
                  ? Color(int.parse(selectedFolder.color.replaceFirst('#', '0xFF')))
                  : Theme.of(context).iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, FilterOption option) {
    final isSelected = _currentFilter == option;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return GestureDetector(
      onTap: () => setState(() {
        _currentFilter = option;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : Colors.white)
                : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(MemoCard card) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    if (card.isProcessing) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(card.imageUrl, sourceUrl: card.sourceUrl, isProcessing: true),
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
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
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primaryColor),
                      ),
                      Text(
                        "Analyzing...",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).disabledColor,
                      height: 1.2,
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
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              title: Text(
                'Delete Memory',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this memory?',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).disabledColor)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                  ),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ?? false;
      },
      onDismissed: (direction) {
        widget.onDelete?.call(card);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${card.title} deleted'),
            backgroundColor: Theme.of(context).cardColor,
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
      ),
      child: GestureDetector(
        onTap: () => widget.onSelect(card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF262626) : Theme.of(context).dividerColor,
            ),
            boxShadow: isDark ? null : [
               BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
               )
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 96,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
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
                        _buildCategoryBadge(card),
                        const SizedBox(height: 8),
                        Text(
                          card.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleMedium?.color,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCleanSummary(card.summary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Metadata Row
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          card.captureDate,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        if (card.isFavorite) ...[
                           const SizedBox(width: 8),
                           Icon(Icons.star, size: 12, color: Colors.amber),
                        ],
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
    if (url.isNotEmpty) {
        if (url.startsWith('http')) {
        return Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            opacity: const AlwaysStoppedAnimation(0.9),
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
            opacity: const AlwaysStoppedAnimation(0.9),
            errorBuilder: (_, __, ___) => _buildPlaceholder(hasUrl: sourceUrl != null && sourceUrl.isNotEmpty),
            );
        }
        }
    }
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
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.link,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              )
            : Icon(
                Icons.image,
                color: Theme.of(context).disabledColor,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildCategoryBadge(MemoCard card) {
    // If exact category is known and valid, use it.
    // Otherwise rely on manual overrides or tags.
    String label = card.category.toUpperCase();
    if (label == 'INBOX' || label.isEmpty) {
         if (card.sourceUrl != null && card.sourceUrl!.isNotEmpty) {
             try {
                final uri = Uri.parse(card.sourceUrl!.startsWith('http') ? card.sourceUrl! : 'https://${card.sourceUrl!}');
                label = uri.host.replaceFirst('www.', '').split('.').first.toUpperCase();
             } catch (_) { label = 'WEB'; }
         } else if (card.tags.contains('Screenshot')) {
             label = 'SCREENSHOT';
         } else {
             label = 'NOTE';
         }
    }

    final color = _getCategoryColor(label);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('design') || lower.contains('ui') || lower.contains('ux')) return const Color(0xFF2DD4BF); // Teal
    if (lower.contains('tech') || lower.contains('code') || lower.contains('dev')) return const Color(0xFF60A5FA); // Blue
    if (lower.contains('food') || lower.contains('cook')) return const Color(0xFF34D399); // Green
    if (lower.contains('shop') || lower.contains('buy')) return const Color(0xFFFB923C); // Orange
    if (lower.contains('work') || lower.contains('job')) return const Color(0xFFF472B6); // Pink
    return const Color(0xFF2DD4BF); // Default Teal
  }

  String _getCleanSummary(String summary) {
    return summary
        .replaceAll('• ', '')
        .replaceAll('\n\n', ' ')
        .replaceAll('\n', ' ')
        .trim();
  }
}
