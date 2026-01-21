
class MemoCard {
  final String id;
  final String title;
  final String summary;
  final String category;
  final List<String> tags;
  final String captureDate;
  final String? sourceUrl;
  final String imageUrl;
  final String? ocrText;
  final String? personalNote;
  final String? folderId;
  final bool isFavorite;
  final bool isProcessing; // New field

  MemoCard({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.tags,
    required this.captureDate,
    this.sourceUrl,
    required this.imageUrl,
    this.ocrText,
    this.personalNote,
    this.folderId,
    this.isFavorite = false,
    this.isProcessing = false, // Default false
  });

  // Factory constructor for creating a new MemoCard from a map (JSON)
  factory MemoCard.fromJson(Map<String, dynamic> json) {
    return MemoCard(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] ?? []),
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
      'tags': tags,
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
    List<String>? tags,
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
      tags: tags ?? this.tags,
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
}
