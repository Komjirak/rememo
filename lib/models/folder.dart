class Folder {
  final String id;
  final String name;
  final String color;
  final DateTime createdDate;
  final int itemCount;

  Folder({
    required this.id,
    required this.name,
    required this.color,
    required this.createdDate,
    this.itemCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      itemCount: json['itemCount'] as int? ?? 0,
    );
  }

  Folder copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? createdDate,
    int? itemCount,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdDate: createdDate ?? this.createdDate,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Folder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
