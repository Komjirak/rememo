import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/models/folder.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('folio.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // Incremented version for keyInsights feature
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const listType = 'TEXT NOT NULL'; // Stored as comma-separated string or JSON
    const intType = 'INTEGER DEFAULT 0';

    await db.execute('''
CREATE TABLE memo_cards (
  id $idType,
  title $textType,
  summary $textType,
  category $textType,
  tags $listType,
  keyInsights $textNullable, 
  captureDate $textType,
  sourceUrl $textNullable,
  imageUrl $textType,
  ocrText $textNullable,
  personalNote $textNullable,
  folderId $textNullable,
  isFavorite $intType
)
''');

    await db.execute('''
CREATE TABLE folders (
  id $idType,
  name $textType,
  color $textType,
  createdDate $textType
)
''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add personalNote column to existing tables
      await db.execute('ALTER TABLE memo_cards ADD COLUMN personalNote TEXT');
    }
    if (oldVersion < 3) {
      // Add folderId column to memo_cards
      await db.execute('ALTER TABLE memo_cards ADD COLUMN folderId TEXT');

      // Create folders table
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      await db.execute('''
CREATE TABLE folders (
  id $idType,
  name $textType,
  color $textType,
  createdDate $textType
)
''');
    }
    if (oldVersion < 4) {
      // Add isFavorite column to memo_cards
      await db.execute('ALTER TABLE memo_cards ADD COLUMN isFavorite INTEGER DEFAULT 0');
    }
    if (oldVersion < 5) {
      // Add keyInsights column to memo_cards
      await db.execute('ALTER TABLE memo_cards ADD COLUMN keyInsights TEXT');
    }
  }

  Future<MemoCard> create(MemoCard card) async {
    final db = await instance.database;
    final map = card.toJson();
    // Convert List<String> to JSON string for storage
    map['tags'] = (map['tags'] as List).join(',');
    map['keyInsights'] = (map['keyInsights'] as List? ?? []).join(',');
    
    await db.insert('memo_cards', map);
    return card;
  }

  Future<List<MemoCard>> readAllMemoCards() async {
    final db = await instance.database;
    final orderBy = 'captureDate DESC';
    final result = await db.query('memo_cards', orderBy: orderBy);

    return result.map((json) {
      // Create flexible mutable map
      final mutableJson = Map<String, dynamic>.from(json);
      // Convert stored string back to List
      if (mutableJson['tags'] is String) {
        final tagsStr = mutableJson['tags'] as String;
        mutableJson['tags'] = tagsStr.isEmpty ? [] : tagsStr.split(',');
      }
      if (mutableJson['keyInsights'] is String) {
        final insightsStr = mutableJson['keyInsights'] as String;
        mutableJson['keyInsights'] = insightsStr.isEmpty ? [] : insightsStr.split(',');
      }
      return MemoCard.fromJson(mutableJson);
    }).toList();
  }

  Future<int> update(MemoCard card) async {
    final db = await instance.database;
    final map = card.toJson();
    // Convert List<String> to comma-separated string for storage
    map['tags'] = (map['tags'] as List).join(',');
    map['keyInsights'] = (map['keyInsights'] as List? ?? []).join(',');

    return await db.update(
      'memo_cards',
      map,
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete(
      'memo_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clear() async {
     final db = await instance.database;
     await db.delete('memo_cards');
  }

  // Folder CRUD operations
  
  Future<Folder> createFolder(Folder folder) async {
    final db = await instance.database;
    await db.insert('folders', folder.toJson());
    return folder;
  }

  Future<List<Folder>> readAllFolders() async {
    final db = await instance.database;
    final result = await db.query('folders', orderBy: 'createdDate DESC');
    
    // Count items in each folder
    final folders = <Folder>[];
    for (var json in result) {
      final folder = Folder.fromJson(json);
      final countResult = await db.query(
        'memo_cards',
        columns: ['COUNT(*) as count'],
        where: 'folderId = ?',
        whereArgs: [folder.id],
      );
      final count = countResult.first['count'] as int? ?? 0;
      folders.add(folder.copyWith(itemCount: count));
    }
    
    return folders;
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await instance.database;
    return await db.update(
      'folders',
      folder.toJson(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(String id) async {
    final db = await instance.database;
    
    // Remove folderId from memo_cards that belong to this folder
    await db.update(
      'memo_cards',
      {'folderId': null},
      where: 'folderId = ?',
      whereArgs: [id],
    );
    
    // Delete the folder
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MemoCard>> readMemoCardsByFolder(String? folderId) async {
    final db = await instance.database;
    final orderBy = 'captureDate DESC';
    
    List<Map<String, dynamic>> result;
    if (folderId == null) {
      // Get cards without folder
      result = await db.query(
        'memo_cards',
        where: 'folderId IS NULL',
        orderBy: orderBy,
      );
    } else {
      // Get cards in specific folder
      result = await db.query(
        'memo_cards',
        where: 'folderId = ?',
        whereArgs: [folderId],
        orderBy: orderBy,
      );
    }

    return result.map((json) {
      final mutableJson = Map<String, dynamic>.from(json);
      if (mutableJson['tags'] is String) {
        final tagsStr = mutableJson['tags'] as String;
        mutableJson['tags'] = tagsStr.isEmpty ? [] : tagsStr.split(',');
      }
      if (mutableJson['keyInsights'] is String) {
        final insightsStr = mutableJson['keyInsights'] as String;
        mutableJson['keyInsights'] = insightsStr.isEmpty ? [] : insightsStr.split(',');
      }
      return MemoCard.fromJson(mutableJson);
    }).toList();
  }

  Future<int> moveMemoCardToFolder(String cardId, String? folderId) async {
    final db = await instance.database;
    return await db.update(
      'memo_cards',
      {'folderId': folderId},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}
