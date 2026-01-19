import 'package:flutter/material.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/theme/app_theme.dart';

class EditCardScreen extends StatefulWidget {
  final MemoCard card;
  final List<String> availableCategories;

  const EditCardScreen({
    super.key,
    required this.card,
    this.availableCategories = const ['Inbox', 'Shopping', 'Food', 'Web', 'Work', 'Design', 'Tech', 'Reference'],
  });

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _urlController;
  late TextEditingController _tagController;
  late String _selectedCategory;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
    _summaryController = TextEditingController(text: widget.card.summary);
    _urlController = TextEditingController(text: widget.card.sourceUrl ?? '');
    _tagController = TextEditingController();
    _selectedCategory = widget.card.category;
    _tags = List.from(widget.card.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _urlController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveChanges() {
    final updatedCard = widget.card.copyWith(
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      category: _selectedCategory,
      tags: _tags,
      sourceUrl: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
    );
    Navigator.pop(context, updatedCard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "EDIT CARD",
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 2,
                fontSize: 12,
              ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: Text(
              "SAVE",
              style: TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _buildLabel("Title"),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: _inputDecoration("Enter title"),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Category
            _buildLabel("Category"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.availableCategories.contains(_selectedCategory)
                      ? _selectedCategory
                      : widget.availableCategories.first,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.ink),
                  items: widget.availableCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Summary
            _buildLabel("Summary"),
            const SizedBox(height: 8),
            TextField(
              controller: _summaryController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: _inputDecoration("Enter summary or notes"),
              maxLines: 5,
            ),
            const SizedBox(height: 24),

            // URL
            _buildLabel("Source URL"),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: _inputDecoration("https://..."),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Tags
            _buildLabel("Tags"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: _inputDecoration("Add tag").copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: AppTheme.ink),
                        onPressed: _addTag,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) => _buildTagChip(tag)).toList(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: AppTheme.ink.withOpacity(0.5),
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.ink.withOpacity(0.3)),
      filled: true,
      fillColor: AppTheme.cream,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.ink, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "#$tag",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(
              Icons.close,
              size: 14,
              color: AppTheme.ink.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
