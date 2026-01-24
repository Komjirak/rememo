
class MemoCard {
  final String id;
  final String title;
  final String summary;
  final String category;
  final String sourceType; // 'screenshot', 'url', 'photo'
  final List<String> tags;
  final List<String> keyInsights; // New field
  final String captureDate;
  final String? sourceUrl;
  final String imageUrl;
  final String? ocrText;
  final String? personalNote;
  final String? folderId;
  final bool isFavorite;
  final bool isProcessing; 

  MemoCard({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    this.sourceType = 'screenshot', // Default to screenshot for backward compatibility
    required this.tags,
    this.keyInsights = const [], // Default empty
    required this.captureDate,
    this.sourceUrl,
    required this.imageUrl,
    this.ocrText,
    this.personalNote,
    this.folderId,
    this.isFavorite = false,
    this.isProcessing = false, 
  });

  // Factory constructor for creating a new MemoCard from a map (JSON)
  factory MemoCard.fromJson(Map<String, dynamic> json) {
    return MemoCard(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      category: json['category'] as String,
      sourceType: json['sourceType'] as String? ?? 'screenshot',
      tags: _parseList(json['tags']),
      keyInsights: _parseList(json['keyInsights']),
      captureDate: json['captureDate'] as String,
      sourceUrl: json['sourceUrl'] as String?,
      imageUrl: json['imageUrl'] as String,
      ocrText: json['ocrText'] as String?,
      personalNote: json['personalNote'] as String?,
      folderId: json['folderId'] as String?,
      isFavorite: json['isFavorite'] == 1 || json['isFavorite'] == true,
      isProcessing: false, // Always false from DB
    );
  }

  // Method to convert a MemoCard to a map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'category': category,
      'sourceType': sourceType,
      'tags': tags, // Handled by DB Helper (jsonEncode likely)
      'keyInsights': keyInsights,
      'captureDate': captureDate,
      'sourceUrl': sourceUrl,
      'imageUrl': imageUrl,
      'ocrText': ocrText,
      'personalNote': personalNote,
      'folderId': folderId,
      'isFavorite': isFavorite ? 1 : 0,
       // isProcessing skip
    };
  }

  // CopyWith method for immutable updates
  MemoCard copyWith({
    String? id,
    String? title,
    String? summary,
    String? category,
    String? sourceType,
    List<String>? tags,
    List<String>? keyInsights,
    String? captureDate,
    String? sourceUrl,
    String? imageUrl,
    String? ocrText,
    String? personalNote,
    String? folderId,
    bool? isFavorite,
    bool? isProcessing,
  }) {
    return MemoCard(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      category: category ?? this.category,
      sourceType: sourceType ?? this.sourceType,
      tags: tags ?? this.tags,
      keyInsights: keyInsights ?? this.keyInsights,
      captureDate: captureDate ?? this.captureDate,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      ocrText: ocrText ?? this.ocrText,
      personalNote: personalNote ?? this.personalNote,
      folderId: folderId ?? this.folderId,
      isFavorite: isFavorite ?? this.isFavorite,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
  
  static List<String> _parseList(dynamic val) {
      if (val == null) return [];
      if (val is String) {
          // If stored as comma separated string or json string, handle here if needed.
          // But for now assuming List or null.
          // Actually, if DB helper stores as JSON string, we might need to decode.
          // Let's assume List<dynamic> for now as per `tags` implementation.
          return [];
      }
      return List<String>.from(val ?? []);
  }
}
