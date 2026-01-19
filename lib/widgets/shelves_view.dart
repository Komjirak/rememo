import 'package:flutter/material.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class ShelvesView extends StatelessWidget {
  final List<MemoCard> cards;
  final Function(MemoCard) onSelect;

  const ShelvesView({
    super.key,
    required this.cards,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return _buildEmptyState(context);
    }

    final categories = cards.map((c) => c.category).toSet().toList();

    return ListView(
      padding: const EdgeInsets.only(top: 24, bottom: 100), // Bottom padding for FAB
      children: [
        _buildHeader(context),
        const SizedBox(height: 24),
        ...categories.map((cat) => _buildCategorySection(context, cat)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    height: 1.1,
                  ),
              children: [
                const TextSpan(text: "Welcome back,\n"),
                TextSpan(
                  text: "Scholar",
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "LIBRARY SIZE: ${cards.length} VOLUMES",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink.withOpacity(0.4),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, String category) {
    final categoryCards = cards.where((c) => c.category == category).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$category Musings",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Icon(Icons.east, color: AppTheme.ink.withOpacity(0.2)),
            ],
          ),
        ),
        const Divider(height: 16, indent: 24, endIndent: 24),
        SizedBox(
          height: 280, // Height for book + title area
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemCount: categoryCards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 24),
            itemBuilder: (context, index) {
              return _buildBookCard(context, categoryCards[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(BuildContext context, MemoCard card) {
    return GestureDetector(
      onTap: () => onSelect(card),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Image
                      Positioned.fill(
                        child: _buildImage(card.imageUrl),
                      ),
                      
                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.ink.withOpacity(0.1),
                                Colors.transparent,
                                AppTheme.ink.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Spine Effects
                      Positioned(
                        top: 0, bottom: 0, left: 0, width: 4,
                        child: Container(color: Colors.black.withOpacity(0.1)),
                      ),
                      Positioned(
                        top: 0, bottom: 0, left: 4, width: 1,
                        child: Container(color: Colors.white.withOpacity(0.2)),
                      ),

                      // Bottom Label
                      const Positioned(
                        bottom: 12, left: 16,
                        child: Text(
                          "VOLUME",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                            letterSpacing: 3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Metadata
            const SizedBox(height: 16),
            Text(
              card.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.lightTheme.textTheme.displayMedium?.fontFamily,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              "SCRIBED ${card.captureDate.toUpperCase()}",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: AppTheme.ink.withOpacity(0.5),
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
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
      );
    } else {
      // Local file
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image)),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: AppTheme.border),
          const SizedBox(height: 16),
          Text(
            "Your shelves are empty.",
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: AppTheme.ink.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
