import 'package:flutter/material.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/theme/app_theme.dart';

class ArchiveView extends StatefulWidget {
  final List<MemoCard> cards;
  final Function(MemoCard) onSelect;

  const ArchiveView({
    super.key,
    required this.cards,
    required this.onSelect,
  });

  @override
  State<ArchiveView> createState() => _ArchiveViewState();
}

enum SortOption { newest, oldest, alphabetical }

class _ArchiveViewState extends State<ArchiveView> {
  String _searchTerm = '';
  String? _selectedCategory;
  SortOption _sortOption = SortOption.newest;

  List<String> get _categories {
    return widget.cards.map((c) => c.category).toSet().toList()..sort();
  }

  List<MemoCard> get _filteredCards {
    var cards = widget.cards.toList();

    // Filter by category
    if (_selectedCategory != null) {
      cards = cards.where((c) => c.category == _selectedCategory).toList();
    }

    // Filter by search term
    if (_searchTerm.isNotEmpty) {
      final term = _searchTerm.toLowerCase();
      cards = cards.where((c) =>
        c.title.toLowerCase().contains(term) ||
        c.summary.toLowerCase().contains(term) ||
        c.category.toLowerCase().contains(term) ||
        c.tags.any((t) => t.toLowerCase().contains(term)) ||
        (c.ocrText?.toLowerCase().contains(term) ?? false)
      ).toList();
    }

    // Sort
    switch (_sortOption) {
      case SortOption.newest:
        // Already sorted by newest from DB
        break;
      case SortOption.oldest:
        cards = cards.reversed.toList();
        break;
      case SortOption.alphabetical:
        cards.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _buildTableHeader(),
              if (_filteredCards.isEmpty)
                _buildEmptyState()
              else
                ..._filteredCards.map(_buildRow),

              _buildMetrics(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: "All",
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ..._categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: cat,
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Sort options
          Row(
            children: [
              Text(
                "SORT BY:",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 12),
              _buildSortChip("Newest", SortOption.newest),
              const SizedBox(width: 8),
              _buildSortChip("Oldest", SortOption.oldest),
              const SizedBox(width: 8),
              _buildSortChip("A-Z", SortOption.alphabetical),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ink : AppTheme.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.ink : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.cream : AppTheme.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, SortOption option) {
    final isSelected = _sortOption == option;
    return GestureDetector(
      onTap: () => setState(() => _sortOption = option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.ink : AppTheme.ink.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: TextField(
        onChanged: (value) => setState(() => _searchTerm = value),
        decoration: InputDecoration(
          hintText: "Search the archives...",
          hintStyle: TextStyle(
            color: AppTheme.ink.withOpacity(0.4),
            fontStyle: FontStyle.italic,
          ),
          prefixIcon: Icon(Icons.search, color: AppTheme.ink.withOpacity(0.3)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accent),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: AppTheme.cream.withOpacity(0.5),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderCell("VOLUME TITLE")),
          Expanded(flex: 2, child: _buildHeaderCell("FORMAT")),
          Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: _buildHeaderCell("TAGS"))),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: AppTheme.ink.withOpacity(0.4),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildRow(MemoCard card) {
    return GestureDetector(
      onTap: () => widget.onSelect(card),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
          color: Colors.white24,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: TextStyle(
                      fontFamily: AppTheme.lightTheme.textTheme.displaySmall?.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.captureDate,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink.withOpacity(0.4),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 16, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  Text(
                    "MEMO",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    "${card.tags.length}",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    final totalTags = _filteredCards.fold(0, (sum, c) => sum + c.tags.length);
    
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      color: AppTheme.cream.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "REGISTRY METRICS",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.ink.withOpacity(0.4),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard("${_filteredCards.length}", "VISIBLE VOLUMES", AppTheme.ink),
              const SizedBox(width: 16),
              _buildMetricCard("$totalTags", "NETWORK NODES", AppTheme.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.lightTheme.textTheme.displayLarge?.fontFamily,
                fontSize: 28,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppTheme.ink.withOpacity(0.4),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Text(
          "No matching volumes found in registry.",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: AppTheme.ink.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}
