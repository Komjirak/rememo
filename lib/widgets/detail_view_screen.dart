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
  final List<Folder>? folders;
  final VoidCallback? onDelete;
  final Function(String)? onOpenLink;
  final Function(MemoCard)? onUpdate;

  const DetailViewScreen({
    super.key,
    required this.card,
    this.folders,
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

  Future<void> _showFolderPicker() async {
    // Initial fetch
    var folders = await DatabaseHelper.instance.readAllFolders();
    String? tempSelectedFolderId = _card.folderId; // Track selection locally

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Important for glass effect
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetColor = isDark 
                ? const Color(0xFF101922).withOpacity(0.85) 
                : Colors.white.withOpacity(0.95);
            final borderColor = isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05);

            return ClipRRect(
               borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
               child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                 child: Container(
                    decoration: BoxDecoration(
                      color: sheetColor,
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 4),
                            width: 48,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Move to Folder",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Divider(height: 1, color: borderColor),
                        
                        // Content List
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              children: [
                                // Create New Folder Item
                                InkWell(
                                  onTap: () async {
                                     final newFolder = await _showCreateFolderDialog();
                                     if (newFolder != null) {
                                         folders = await DatabaseHelper.instance.readAllFolders();
                                         setModalState(() {
                                            tempSelectedFolderId = newFolder.id; // Auto select new folder
                                         });
                                     }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44, height: 44,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryDark.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppTheme.primaryDark.withOpacity(0.2)),
                                          ),
                                          child: const Icon(Icons.add_circle, color: AppTheme.primaryDark),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            "Create New Folder",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: isDark ? Colors.grey : Colors.grey.shade400),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(color: borderColor),
                                ),
                                
                                // Radio List: No Folder
                                _buildFolderRadioItem(
                                  id: null,
                                  name: "None", // Or "Root" / "No Folder"
                                  icon: Icons.folder_off_outlined,
                                  color: Colors.grey,
                                  isSelected: tempSelectedFolderId == null,
                                  isDark: isDark,
                                  onTap: () => setModalState(() => tempSelectedFolderId = null),
                                ),
                                
                                const SizedBox(height: 8),

                                // Radio List: Folders
                                ...folders.map((folder) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildFolderRadioItem(
                                    id: folder.id, 
                                    name: folder.name, 
                                    icon: Icons.folder, // Or specific icon 
                                    color: _hexToColor(folder.color),
                                    isSelected: tempSelectedFolderId == folder.id,
                                    isDark: isDark,
                                    onTap: () => setModalState(() => tempSelectedFolderId = folder.id),
                                  ),
                                )),
                                
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        
                        // Sticky Footer: Move Here Button
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40), // PB-10 in html, plus safe area
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: borderColor)),
                            color: isDark 
                                ? const Color(0xFF101922).withOpacity(0.4) 
                                : Colors.white.withOpacity(0.6),
                          ),
                          child: ClipRRect( // Backdrop blur for footer itself if needed, usually container color handles it
                             child: SizedBox(
                               width: double.infinity,
                               height: 56,
                               child: ElevatedButton(
                                 onPressed: () async {
                                    // Perform Move
                                    await DatabaseHelper.instance.moveMemoCardToFolder(_card.id, tempSelectedFolderId);
                                    
                                    // Update Local State
                                    if (mounted) {
                                       setState(() {
                                         _card = _card.copyWith(folderId: tempSelectedFolderId);
                                       });
                                       widget.onUpdate?.call(_card);
                                       Navigator.pop(context);
                                       
                                       // Show Toast
                                       final folderName = tempSelectedFolderId == null 
                                            ? "Removed from folder" 
                                            : "Moved to ${folders.firstWhere((f) => f.id == tempSelectedFolderId).name}";
                                       
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         SnackBar(
                                           content: Text(folderName),
                                           behavior: SnackBarBehavior.floating,
                                            backgroundColor: Theme.of(context).cardColor,
                                         )
                                       );
                                    }
                                 },
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: AppTheme.primaryDark,
                                   foregroundColor: Colors.white,
                                   elevation: 8,
                                   shadowColor: AppTheme.primaryDark.withOpacity(0.4),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                   textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                 ),
                                 child: const Text("Move Here"),
                               ),
                             ),
                          ),
                        ),
                      ],
                    ),
                 ),
               ),
            );
          },
        );
      },
    );
  }

  Widget _buildFolderRadioItem({
      required String? id, 
      required String name, 
      required IconData icon, 
      required Color color, 
      required bool isSelected, 
      required bool isDark,
      required VoidCallback onTap,
  }) {
      final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05); 
      
      return GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isSelected ? AppTheme.primaryDark : borderColor, 
                      width: isSelected ? 2 : 1
                  ),
              ),
              child: Row(
                  children: [
                       // Content Left (Radio Right logic)
                       Icon(icon, color: isSelected ? AppTheme.primaryDark : (isDark ? Colors.grey : Colors.grey.shade400)),
                       const SizedBox(width: 12),
                       Expanded(
                           child: Text(
                               name,
                               style: TextStyle(
                                   fontSize: 16,
                                   fontWeight: FontWeight.w500,
                                   color: isDark ? Colors.white : Colors.black,
                               ),
                           ),
                       ),
                       // Radio
                       Container(
                           width: 20, height: 20,
                           decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               border: Border.all(
                                   color: isSelected ? AppTheme.primaryDark : (isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300),
                                   width: 2,
                               ),
                               color: isSelected ? AppTheme.primaryDark : Colors.transparent,
                           ),
                           child: isSelected 
                               ? const Icon(Icons.circle, size: 8, color: Colors.white) 
                               : null,
                       ),
                  ],
              ),
          ),
      );
  }


  Future<Folder?> _showCreateFolderDialog() async {
    final nameController = TextEditingController();
    String selectedColor = '#14B8A6'; 

    final colors = [
      '#14B8A6', '#60A5FA', '#C084FC', '#4ADE80', 
      '#FB923C', '#F472B6', '#FACC15', '#EF4444', 
    ];

    return showDialog<Folder>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('New Folder', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Folder Name',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      filled: true,
                      fillColor: Theme.of(context).dividerColor.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
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
                            border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 3) : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                    if (mounted) Navigator.pop(ctx, folder);
                  },
                  child: const Text('Create'),
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
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Memory', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color)),
        content: Text(
          'Are you sure you want to delete this memory? This action cannot be undone.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon'), behavior: SnackBarBehavior.floating),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.folder_outlined, color: Theme.of(context).iconTheme.color),
              title: Text('Move to Folder', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.pop(ctx);
                _showFolderPicker();
              },
            ),
            ListTile(
              leading: Icon(Icons.share_outlined, color: Theme.of(context).iconTheme.color),
              title: Text('Share', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.pop(ctx);
                _shareCard();
              },
            ),
            Divider(color: Theme.of(context).dividerColor),
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

  // Helper Methods
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          Column(
            children: [
               _buildHeader(),
               Expanded(
                 child: SingleChildScrollView(
                   padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const SizedBox(height: 24),
                       const SizedBox(height: 24),
                       _buildTitleSection(),
                       const SizedBox(height: 8), // Adjusted spacing
                       _buildMetadataSection(),
                       const SizedBox(height: 16),
                       _buildTagsSection(),
                       const SizedBox(height: 24),
                       _buildImageSection(), // Image moved here
                       const SizedBox(height: 24),
                       _buildAISummarySection(),
                       const SizedBox(height: 24),
                       _buildPersonalNoteSection(),
                       const SizedBox(height: 24),
                       _buildOriginalMessageSection(),
                       const SizedBox(height: 48),
                     ],
                   ),
                 ),
               ),
            ],
          ),
          
          Positioned(
            bottom: 32, // bottom-8 equivalent roughly
            left: 0,
            right: 0,
            child: Center(
              child: _buildFloatingBottomMenu(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 16,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: isDark 
                ? AppTheme.backgroundDark.withOpacity(0.8) 
                : Colors.white.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
              )
            )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left, 
                  size: 28,
                  color: isDark ? AppTheme.textLowDark : AppTheme.textHighLight
                ),
                onPressed: () => Navigator.pop(context),
              ),
              
               Row(
                 children: [
                   Icon(Icons.memory, color: AppTheme.primaryDark, size: 20),
                   const SizedBox(width: 6),
                   Text(
                     "REMEMO INSIGHT",
                     style: TextStyle(
                       color: isDark ? AppTheme.textHighDark.withOpacity(0.8) : AppTheme.textHighLight.withOpacity(0.8),
                       fontSize: 12,
                       fontWeight: FontWeight.w600,
                       letterSpacing: 0.5,
                     ),
                   ),
                 ],
               ),
               
               IconButton(
                 icon: Icon(
                   Icons.more_horiz, 
                   size: 24,
                   color: isDark ? AppTheme.textLowDark : AppTheme.textHighLight
                 ),
                 onPressed: _showMoreOptions,
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showTitleEditDialog(),
      child: Text(
        _card.title,
        style: TextStyle(
          fontSize: 30, // 3xl
          fontWeight: FontWeight.bold,
          height: 1.2,
          letterSpacing: -0.5,
          color: isDark ? AppTheme.textHighDark : AppTheme.textHighLight,
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          Icons.calendar_today, 
          size: 16, 
          color: isDark ? AppTheme.textLowDark : AppTheme.textLowLight
        ),
        const SizedBox(width: 6),
        Text(
          _card.captureDate,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.textLowDark : AppTheme.textLowLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Merge Manual Tags and maybe visual cue for "AI Analysis"
    final tags = [..._card.tags, 'AI Analysis']; // Always show AI Analysis as per design mock
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final isAiTag = tag == 'AI Analysis';
        if (!isDark) {
           if (isAiTag) {
             return _buildPill(
               label: tag, 
               bgColor: AppTheme.primaryLight.withOpacity(0.1), 
               textColor: AppTheme.primaryLight
             );
           }
           return _buildPill(
             label: tag, 
             bgColor: const Color(0xFFF3F4F6), 
             textColor: AppTheme.textHighLight
           );
        } else {
           if (tag == 'Design' || tag == 'AI Analysis') { 
              return _buildPill(
                label: tag, 
                bgColor: AppTheme.primaryDark.withOpacity(0.1), 
                textColor: AppTheme.primaryDark,
                borderColor: AppTheme.primaryDark.withOpacity(0.2)
              );
           }
           return _buildPill(
              label: tag, 
              bgColor: Colors.white.withOpacity(0.05), 
              textColor: Colors.grey.shade300,
              borderColor: Colors.white.withOpacity(0.1)
           );
        }
      }).toList(),
    );
  }
  
  Widget _buildPill({required String label, required Color bgColor, required Color textColor, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        if (_card.sourceUrl != null && _card.sourceUrl!.isNotEmpty) {
           widget.onOpenLink?.call(_card.sourceUrl!);
        } else {
           _expandImage();
        }
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent
          ),
          color: isDark ? AppTheme.cardDark : Colors.grey.shade100,
          boxShadow: isDark 
            ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)]
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildImage(_card.imageUrl),
            
            // Link Indicator
            if (_card.sourceUrl != null && _card.sourceUrl!.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 40, 
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISummarySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Icon(
               Icons.auto_awesome, 
               size: 20, 
               color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight
             ),
             const SizedBox(width: 8),
             Text(
               "AI SUMMARY",
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 letterSpacing: 1.5, 
                 color: isDark ? Colors.grey : AppTheme.primaryLight,
               ),
             ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark 
                ? AppTheme.cardDark.withOpacity(0.5) 
                : AppTheme.softTealLight,
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.05) 
                  : AppTheme.primaryLight.withOpacity(0.1)
            ),
          ),
          child: Text(
            _card.summary.isEmpty 
                ? "AI is analyzing this content..." 
                : _card.summary,
            style: TextStyle(
              fontSize: 15,
              height: 1.6, 
              fontWeight: isDark ? FontWeight.w300 : FontWeight.normal,
              color: isDark ? Colors.grey.shade300 : AppTheme.textHighLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalNoteSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Icon(
               Icons.edit_note, 
               size: 24, 
               color: isDark ? Colors.grey : AppTheme.textLowLight
             ),
             const SizedBox(width: 8),
             Text(
               "PERSONAL NOTE",
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 letterSpacing: 1.5,
                 color: Colors.grey,
               ),
             ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? AppTheme.cardDark.withOpacity(0.5) 
                : const Color(0xFFF9FAFB), 
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200
            ),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: null,
            minLines: 4,
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : AppTheme.textHighLight.withOpacity(0.8),
              fontSize: 15,
              height: 1.6,
              fontStyle: isDark ? FontStyle.normal : FontStyle.italic,
            ),
            decoration: InputDecoration(
              hintText: "Add your thoughts...",
              hintStyle: TextStyle(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalMessageSection() {
    final text = _card.ocrText ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourceUrl = _card.sourceUrl;
    final domain = sourceUrl != null ? _extractDomain(sourceUrl) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Icon(
               Icons.description_outlined, 
               size: 20, 
               color: isDark ? Colors.grey : Colors.grey.shade400
             ),
             const SizedBox(width: 8),
             Text(
               "ORIGINAL MESSAGE",
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 letterSpacing: 1.0,
                 color: isDark ? Colors.grey : Colors.grey.shade500,
               ),
             ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
            )
          ),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.6,
                    fontFamily: Platform.isIOS ? 'Courier' : 'monospace',
                  ),
                ),
                if (sourceUrl != null && sourceUrl.isNotEmpty) ...[
                     const SizedBox(height: 16),
                     GestureDetector(
                         onTap: () => widget.onOpenLink?.call(sourceUrl),
                         child: Text(
                             "Source: $domain",
                             style: const TextStyle(
                                 fontSize: 13,
                                 color: Colors.blue,
                                 decoration: TextDecoration.underline,
                             ),
                         ),
                     ),
                ]
             ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingBottomMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(100), 
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.black.withOpacity(0.4) 
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _showFolderPicker,
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_open,
                      color: isDark ? Colors.grey.shade200 : AppTheme.textHighLight.withOpacity(0.8),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Move Folder",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade200 : AppTheme.textHighLight.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                width: 1,
                height: 24,
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
              
              GestureDetector(
                onTap: _showDeleteDialog,
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent, 
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Delete",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.redAccent.shade100 : Colors.red,
                      ),
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

  void _showTitleEditDialog() {
    final controller = TextEditingController(text: _card.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Edit Title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                    final updated = _card.copyWith(title: newTitle);
                    await DatabaseHelper.instance.update(updated);
                   setState(() => _card = updated);
                    widget.onUpdate?.call(updated);
                }
                if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _expandImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageView(imageUrl: _card.imageUrl),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey, child: const Icon(Icons.broken_image)),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      }
      return Container(color: Colors.grey, child: const Icon(Icons.broken_image));
    }
  }
}

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
              child: _buildImage(imageUrl),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
      return const Icon(Icons.broken_image, color: Colors.white);
    }
  }
}
