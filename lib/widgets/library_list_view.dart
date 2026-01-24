import 'package:flutter/material.dart';
import 'dart:io';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/models/folder.dart';
import 'package:stribe/theme/app_theme.dart';

class LibraryListView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // 필터링은 home_screen에서 처리됨 - 여기서는 단순 표시만
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
      itemCount: cards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _LibraryCardItem(
          card: cards[index],
          onSelect: onSelect,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _LibraryCardItem extends StatelessWidget {
  final MemoCard card;
  final Function(MemoCard) onSelect;
  final Function(MemoCard)? onDelete;

  const _LibraryCardItem({
    required this.card,
    required this.onSelect,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                  _buildThumbnail(context, card.imageUrl, sourceUrl: card.sourceUrl, isProcessing: true),
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
          builder: (BuildContext ctx) {
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
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).disabledColor)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
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
        onDelete?.call(card);
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
        onTap: () => onSelect(card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.transparent : Theme.of(context).dividerColor,
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
                    color: isDark ? Colors.transparent : Theme.of(context).dividerColor,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildThumbnail(context, card.imageUrl, sourceUrl: card.sourceUrl),
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
                        _buildBadges(context, card),
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
                           const Icon(Icons.star, size: 12, color: Colors.amber),
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

  // 출처 타입 + 대표 태그 배지 (개선된 버전)
  Widget _buildBadges(BuildContext context, MemoCard card) {
    return Row(
      children: [
        // 1. 출처 타입 배지
        _buildSourceTypeBadge(context, card.sourceType),
        const SizedBox(width: 6),
        // 2. 대표 태그 배지 (tags[0] 또는 category)
        _buildMainTagBadge(context, card),
      ],
    );
  }

  Widget _buildSourceTypeBadge(BuildContext context, String sourceType) {
    IconData icon;
    String label;
    Color color;

    switch (sourceType) {
      case 'url':
        icon = Icons.link;
        label = 'URL';
        color = const Color(0xFF60A5FA); // Blue
        break;
      case 'photo':
        icon = Icons.camera_alt;
        label = '사진';
        color = const Color(0xFF34D399); // Green
        break;
      case 'screenshot':
      default:
        icon = Icons.smartphone;
        label = '스크린샷';
        color = const Color(0xFF8B5CF6); // Purple
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTagBadge(BuildContext context, MemoCard card) {
    // 우선순위: 태그 첫번째 > 카테고리 (Inbox 제외)
    String label = '';

    if (card.tags.isNotEmpty) {
      // URL 관련 태그나 시스템 태그 제외
      final validTags = card.tags.where((t) =>
          !['Screenshot', 'Imported', 'Photo', 'Shared', 'Web'].contains(t) &&
          !t.contains('.com') &&
          !t.contains('.io') &&
          t.length <= 15
      ).toList();

      if (validTags.isNotEmpty) {
        label = validTags.first;
      }
    }

    // 태그가 없으면 카테고리 사용 (Inbox 제외)
    if (label.isEmpty && card.category.isNotEmpty && card.category != 'Inbox') {
      label = card.category;
    }

    if (label.isEmpty) return const SizedBox.shrink();

    final color = _getTagColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }

  Color _getTagColor(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('design') || lower.contains('ui') || lower.contains('ux') || lower.contains('디자인')) {
      return const Color(0xFF2DD4BF); // Teal
    }
    if (lower.contains('tech') || lower.contains('code') || lower.contains('dev') || lower.contains('개발') || lower.contains('기술')) {
      return const Color(0xFF60A5FA); // Blue
    }
    if (lower.contains('food') || lower.contains('cook') || lower.contains('음식') || lower.contains('요리')) {
      return const Color(0xFF34D399); // Green
    }
    if (lower.contains('shop') || lower.contains('buy') || lower.contains('쇼핑') || lower.contains('구매')) {
      return const Color(0xFFFB923C); // Orange
    }
    if (lower.contains('work') || lower.contains('job') || lower.contains('업무') || lower.contains('회의')) {
      return const Color(0xFFF472B6); // Pink
    }
    if (lower.contains('news') || lower.contains('뉴스') || lower.contains('기사')) {
      return const Color(0xFFEF4444); // Red
    }
    return const Color(0xFF9CA3AF); // Gray (default)
  }

  Widget _buildThumbnail(BuildContext context, String url, {String? sourceUrl, bool isProcessing = false}) {
    if (url.isNotEmpty) {
        if (url.startsWith('http')) {
        return Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            opacity: const AlwaysStoppedAnimation(0.9),
            errorBuilder: (_, __, ___) => _buildPlaceholder(context, hasUrl: sourceUrl != null && sourceUrl.isNotEmpty),
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
            errorBuilder: (_, __, ___) => _buildPlaceholder(context, hasUrl: sourceUrl != null && sourceUrl.isNotEmpty),
            );
        }
        }
    }
    return _buildPlaceholder(context, hasUrl: sourceUrl != null && sourceUrl.isNotEmpty);
  }

  Widget _buildPlaceholder(BuildContext context, {bool hasUrl = false}) {
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

  String _getCleanSummary(String summary) {
    return summary
        .replaceAll('• ', '')
        .replaceAll('\n\n', ' ')
        .replaceAll('\n', ' ')
        .trim();
  }
}
