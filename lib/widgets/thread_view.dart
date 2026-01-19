import 'package:flutter/material.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/theme/app_theme.dart';

class ThreadView extends StatelessWidget {
  final List<MemoCard> cards;
  final Function(MemoCard) onSelect;

  const ThreadView({
    super.key,
    required this.cards,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Content including Header
        CustomScrollView(
          slivers: [
            _buildSliverHeader(context),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Logic to grouping by date would go here. 
                    // For now, we render a simple list pretending to be a timeline.
                    // This creates the "Latest • Today" header for the first item
                    if (index == 0) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                _buildDateHeader(context, "Latest • Today"),
                                _buildTimelineItem(context, cards[index % cards.length], isLast: false),
                            ],
                        );
                    }
                    if (index == 2) { // Mock "Yesterday" break
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                _buildDateHeader(context, "Yesterday • Oct 23"),
                                _buildTimelineItem(context, cards[index % cards.length], isLast: false),
                            ],
                        );
                    }
                    return _buildTimelineItem(context, cards[index % cards.length], isLast: index == cards.length + 2); // +2 for mock logic
                  },
                  childCount: cards.isEmpty ? 0 : cards.length, // Just using cards count for demo
                ),
              ),
            ),
          ],
        ),

        // Timeline Scrubber (Right Side)
        Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child:   Center(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                         const Text("•", style: TextStyle(color: AppTheme.ink, fontSize: 24, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 12),
                         _buildScrubberItem("NOW"),
                         _buildScrubberItem("OCT"),
                         _buildScrubberItem("SEP"),
                         _buildScrubberItem("AUG"),
                         _buildScrubberItem("OLD", opacity: 0.5),
                    ],
                ),
            ),
        ),
      ],
    );
  }

  Widget _buildScrubberItem(String text, {double opacity = 1.0}) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
              text,
              style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF968b80).withOpacity(opacity), // bronze-muted
              ),
          ),
      );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFfaf9f6).withOpacity(0.95), // paper color
      pinned: true,
      elevation: 0,
      toolbarHeight: 140, // Increased height for search + chips
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Title Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5c5248), // primary
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.folder_open, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text("Folio", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1a1a1a))),
                      ],
                    ),
                    Row(
                      children: [
                        _buildCircleBtn(Icons.calendar_today, const Color(0xFF5d5a56)),
                        const SizedBox(width: 12),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: const Color(0xFFf2eee8),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.border)
                          ),
                          child: const Icon(Icons.person, color: Colors.grey),
                        )
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: const Color(0xFFA8A49D), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text("Search your folio...", 
                            style: TextStyle(color: const Color(0xFFA8A49D), fontSize: 16))
                      ),
                      Icon(Icons.tune, color: const Color(0xFFA8A49D), size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Chips
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: [
                            _buildChip("Timeline", isActive: true),
                            _buildChip("Collections"),
                            _buildChip("Shared"),
                            _buildChip("Starred"),
                        ],
                    ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildChip(String label, {bool isActive = false}) {
      return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: isActive ? const Color(0xFF5c5248) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isActive ? null : Border.all(color: AppTheme.border),
          ),
          child: Text(
              label,
              style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF5d5a56),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
          ),
      );
  }

  Widget _buildCircleBtn(IconData icon, Color color) {
      return Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent, // Hover effect simulation skipped
              // border: Border.all(color: AppTheme.border), // Optional
          ),
          child: Icon(icon, color: color, size: 24),
      );
  }

  Widget _buildDateHeader(BuildContext context, String text) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
              children: [
                  Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: const Color(0xFF5c5248),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                          border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.history_edu, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                      text,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Color(0xFF968b80), // bronze-muted
                      ).copyWith(fontFeatures: [const FontFeature.enable('smcp')]), // Small caps attempt
                  ),

              ],
          ),
      );
  }

  Widget _buildTimelineItem(BuildContext context, MemoCard card, {bool isLast = false}) {
      return IntrinsicHeight(
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  // Timeline Line Column
                  SizedBox(
                      width: 56, // Aligns with header circle center (20 pad + 18 center)
                      child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                              // Vertical Line
                              if (!isLast)
                              Positioned(
                                  top: 0, bottom: 0,
                                  child: Container(width: 2, color: const Color(0xFF3d3834).withOpacity(0.1)),
                              ),
                              // Dot
                              Container(
                                  margin: const EdgeInsets.only(top: 24),
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF5c5248),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.paper, width: 3),
                                  ),
                              ),
                          ],
                      ),
                  ),
                  
                  // Content Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48, bottom: 16, top: 4), // Right padding for scrubber
                      child: GestureDetector(
                        onTap: () => onSelect(card),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                            boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                )
                            ]
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                          Icon(card.category == "Archive" ? Icons.article : Icons.sticky_note_2, 
                                              color: const Color(0xFF5c5248), size: 18),
                                          Text("9:41 AM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF5c5248).withOpacity(0.5))),
                                      ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(card.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1a1a1a), height: 1.3)),
                                  const SizedBox(height: 4),
                                  Text(card.summary, 
                                      maxLines: 2, 
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF7a746e), height: 1.5)
                                  ),
                                  const SizedBox(height: 12),
                                  if (card.tags.isNotEmpty)
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF5c5248).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                          card.tags.first.toUpperCase(),
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5c5248)),
                                      ),
                                  )
                              ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
          ),
      );
  }
}
