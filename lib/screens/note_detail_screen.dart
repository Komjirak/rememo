// lib/screens/note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/memo_model.dart';

class NoteDetailScreen extends StatelessWidget {
  final MemoModel memo;

  const NoteDetailScreen({
    Key? key,
    required this.memo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Done', style: TextStyle(color: Colors.white)),
        ),
        title: Text('Note', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            
            // Source Screenshot
            _buildSourceScreenshotSection(),
            
            SizedBox(height: 16),
            
            // Title & OCR Only
            _buildTitleSection(),
            
            SizedBox(height: 16),
            
            // About This Screenshot
            if (memo.explanation != null)
              _buildAboutSection(),
            
            SizedBox(height: 16),
            
            // Key Insights (PRO)
            if (memo.insights.isNotEmpty)
              _buildInsightsSection(),
            
            SizedBox(height: 16),
            
            // Actions (Copy, Share, Redo)
            _buildActionsSection(),
            
            SizedBox(height: 16),
            
            // Language Selection (PRO)
            _buildLanguageSection(),
            
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceScreenshotSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.image, color: Colors.white70),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Source Screenshot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap to view full image',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                Text(
                  _formatDateTime(memo.createdAt),
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.fullscreen, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memo.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.text_fields, size: 16, color: Colors.white60),
              SizedBox(width: 4),
              Text(
                'OCR Only',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(color: Colors.white38),
              ),
              SizedBox(width: 8),
              Text(
                _formatDate(memo.createdAt),
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E3A5F),  // 파란색 배경
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'About This Screenshot',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            memo.explanation!,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Key Insights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${memo.insights.length}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...memo.insights.map((insight) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Copy',
              Icons.copy,
              Colors.blue,
              () {
                Clipboard.setData(ClipboardData(text: memo.text));
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Share',
              Icons.share,
              Colors.green,
              () {},
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Redo',
              Icons.refresh,
              Color(0xFF8B4513),
              () {},
              isPro: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isPro = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          if (isPro) ...[
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PRO',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: Colors.white70, size: 20),
              SizedBox(width: 12),
              Text(
                '출력 언어',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '자동',
                style: TextStyle(color: Colors.white60, fontSize: 15),
              ),
              Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}년 ${dt.month}월 ${dt.day}일 오후 ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}년 ${dt.month}월 ${dt.day}일';
  }
}
