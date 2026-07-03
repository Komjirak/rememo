import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/models/folder.dart';
import 'package:stribe/utils/app_logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// FTS5 사용 가능 여부 (기기 SQLite 버전에 따라 다름)
  bool _ftsAvailable = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    // 주의: DB 파일명 변경 시 기존 사용자 데이터가 유실되므로 'folio.db' 유지
    _database = await _initDB('folio.db');
    return _database!;
  }

  /// DB 연결 해제 (주로 테스트에서 상태 초기화용)
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _ftsAvailable = false;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 9, // v9: 리스트 필드 JSON 인코딩 전환 + 인덱스 추가
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
    await _ensureFtsTable(db);
    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const listType = 'TEXT NOT NULL'; // JSON 배열 문자열로 저장
    const intType = 'INTEGER DEFAULT 0';

    await db.execute('''
CREATE TABLE memo_cards (
  id $idType,
  title $textType,
  summary $textType,
  category $textType,
  sourceType $textType,
  contentType $textType,
  tags $listType,
  keyInsights $textNullable,
  captureDate $textType,
  sourceUrl $textNullable,
  imageUrl $textType,
  ocrText $textNullable,
  personalNote $textNullable,
  folderId $textNullable,
  isFavorite $intType,
  wasTranslated $intType,
  originalTitle $textNullable,
  originalSummary $textNullable
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
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memo_folderId ON memo_cards(folderId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memo_captureDate ON memo_cards(captureDate)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memo_sourceType ON memo_cards(sourceType)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memo_category ON memo_cards(category)');
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
    if (oldVersion < 6) {
      // Add sourceType column to memo_cards with default value 'screenshot'
      await db.execute('ALTER TABLE memo_cards ADD COLUMN sourceType TEXT NOT NULL DEFAULT "screenshot"');
    }
    if (oldVersion < 7) {
      // Add translation related columns
      await db.execute('ALTER TABLE memo_cards ADD COLUMN wasTranslated INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE memo_cards ADD COLUMN originalTitle TEXT');
      await db.execute('ALTER TABLE memo_cards ADD COLUMN originalSummary TEXT');
    }
    if (oldVersion < 8) {
      // Add contentType column to memo_cards with default value 'general'
      await db.execute('ALTER TABLE memo_cards ADD COLUMN contentType TEXT NOT NULL DEFAULT "general"');
    }
    if (oldVersion < 9) {
      // v9: 쉼표 join 방식으로 저장된 tags/keyInsights를 JSON 배열로 재인코딩.
      // 쉼표가 포함된 keyInsights 문장이 조각나는 버그 수정.
      await _migrateListColumnsToJson(db);
      await _createIndexes(db);
    }
  }

  /// 쉼표 구분 문자열 → JSON 배열 문자열 마이그레이션 (v9)
  Future<void> _migrateListColumnsToJson(Database db) async {
    final rows = await db.query('memo_cards', columns: ['id', 'tags', 'keyInsights']);
    final batch = db.batch();
    for (final row in rows) {
      batch.update(
        'memo_cards',
        {
          'tags': jsonEncode(_decodeLegacyList(row['tags'])),
          'keyInsights': jsonEncode(_decodeLegacyList(row['keyInsights'])),
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    await batch.commit(noResult: true);
    logInfo('v9 마이그레이션 완료: ${rows.length}개 카드 리스트 필드 JSON 전환', name: 'DB');
  }

  // ============================================
  // 리스트 직렬화 (JSON 저장, 레거시 쉼표 형식 호환 읽기)
  // ============================================

  static String encodeList(List<dynamic>? list) =>
      jsonEncode(list?.map((e) => e.toString()).toList() ?? const []);

  /// 저장된 문자열을 리스트로 복원.
  /// JSON 배열이 아니면 레거시(쉼표 구분) 형식으로 간주한다.
  static List<String> _decodeLegacyList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    final str = value as String;
    if (str.isEmpty) return [];
    if (str.startsWith('[')) {
      try {
        return List<String>.from(jsonDecode(str) as List);
      } catch (_) {
        // JSON처럼 보이지만 파싱 실패 → 레거시로 처리
      }
    }
    return str.split(',').where((e) => e.trim().isNotEmpty).toList();
  }

  Map<String, dynamic> _rowToCardJson(Map<String, dynamic> row) {
    final mutableJson = Map<String, dynamic>.from(row);
    mutableJson['tags'] = _decodeLegacyList(mutableJson['tags']);
    mutableJson['keyInsights'] = _decodeLegacyList(mutableJson['keyInsights']);
    return mutableJson;
  }

  Map<String, dynamic> _cardToRow(MemoCard card) {
    final map = card.toJson();
    map['tags'] = encodeList(map['tags'] as List?);
    map['keyInsights'] = encodeList(map['keyInsights'] as List?);
    return map;
  }

  // ============================================
  // FTS5 전문 검색
  // ============================================

  Future<void> _ensureFtsTable(Database db) async {
    try {
      await db.execute('''
CREATE VIRTUAL TABLE IF NOT EXISTS memo_fts USING fts5(
  cardId UNINDEXED,
  title,
  summary,
  ocrText,
  tags,
  personalNote,
  tokenize='unicode61'
)
''');
      _ftsAvailable = true;

      // 인덱스가 비어있고 원본 데이터가 있으면 재구축 (최초 도입/재설치 대비)
      final ftsCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM memo_fts')) ??
          0;
      final cardCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM memo_cards')) ??
          0;
      if (ftsCount == 0 && cardCount > 0) {
        await _rebuildFtsIndex(db);
      }
    } catch (e) {
      // FTS5 미지원 기기: LIKE 기반 검색으로 폴백
      _ftsAvailable = false;
      logWarn('FTS5 사용 불가, LIKE 검색으로 폴백: $e', name: 'DB');
    }
  }

  Future<void> _rebuildFtsIndex(Database db) async {
    final rows = await db.query('memo_cards');
    final batch = db.batch();
    for (final row in rows) {
      batch.insert('memo_fts', _ftsRowFrom(_rowToCardJson(row)));
    }
    await batch.commit(noResult: true);
    logInfo('FTS 인덱스 재구축: ${rows.length}개 카드', name: 'DB');
  }

  Map<String, dynamic> _ftsRowFrom(Map<String, dynamic> cardJson) {
    return {
      'cardId': cardJson['id'],
      'title': cardJson['title'] ?? '',
      'summary': cardJson['summary'] ?? '',
      'ocrText': cardJson['ocrText'] ?? '',
      'tags': (cardJson['tags'] as List?)?.join(' ') ?? '',
      'personalNote': cardJson['personalNote'] ?? '',
    };
  }

  Future<void> _ftsInsert(Database db, MemoCard card) async {
    if (!_ftsAvailable) return;
    try {
      await db.insert('memo_fts', _ftsRowFrom({
        ...card.toJson(),
        'tags': card.tags,
      }));
    } catch (e) {
      logWarn('FTS insert 실패: $e', name: 'DB');
    }
  }

  Future<void> _ftsDelete(Database db, String cardId) async {
    if (!_ftsAvailable) return;
    try {
      await db.delete('memo_fts', where: 'cardId = ?', whereArgs: [cardId]);
    } catch (e) {
      logWarn('FTS delete 실패: $e', name: 'DB');
    }
  }

  /// 전문 검색: FTS5 우선, 실패 시 LIKE 폴백.
  /// title/summary/ocrText/tags/personalNote를 대상으로 한다.
  Future<List<MemoCard>> searchMemoCards(String query) async {
    final db = await instance.database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return readAllMemoCards();

    if (_ftsAvailable) {
      try {
        // 각 단어를 prefix 매칭으로 검색 (한국어 부분 일치 대응)
        final ftsQuery = trimmed
            .split(RegExp(r'\s+'))
            .map((t) => '"${t.replaceAll('"', '')}"*')
            .join(' ');
        final result = await db.rawQuery('''
SELECT m.* FROM memo_cards m
JOIN memo_fts f ON f.cardId = m.id
WHERE memo_fts MATCH ?
ORDER BY m.captureDate DESC
''', [ftsQuery]);
        if (result.isNotEmpty) {
          return result.map((r) => MemoCard.fromJson(_rowToCardJson(r))).toList();
        }
        // FTS 결과가 없으면 LIKE로 한 번 더 (unicode61 토크나이저가 놓치는 CJK 부분 문자열 보완)
      } catch (e) {
        logWarn('FTS 검색 실패, LIKE 폴백: $e', name: 'DB');
      }
    }

    final like = '%$trimmed%';
    final result = await db.query(
      'memo_cards',
      where:
          'title LIKE ? OR summary LIKE ? OR ocrText LIKE ? OR tags LIKE ? OR personalNote LIKE ?',
      whereArgs: [like, like, like, like, like],
      orderBy: 'captureDate DESC',
    );
    return result.map((r) => MemoCard.fromJson(_rowToCardJson(r))).toList();
  }

  // ============================================
  // MemoCard CRUD
  // ============================================

  Future<MemoCard> create(MemoCard card) async {
    final db = await instance.database;
    await db.insert('memo_cards', _cardToRow(card));
    await _ftsInsert(db, card);
    return card;
  }

  Future<List<MemoCard>> readAllMemoCards() async {
    final db = await instance.database;
    final result = await db.query('memo_cards', orderBy: 'captureDate DESC');
    return result.map((r) => MemoCard.fromJson(_rowToCardJson(r))).toList();
  }

  Future<int> update(MemoCard card) async {
    final db = await instance.database;
    final count = await db.update(
      'memo_cards',
      _cardToRow(card),
      where: 'id = ?',
      whereArgs: [card.id],
    );
    await _ftsDelete(db, card.id);
    await _ftsInsert(db, card);
    return count;
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    await _ftsDelete(db, id);
    return await db.delete(
      'memo_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clear() async {
    final db = await instance.database;
    await db.delete('memo_cards');
    if (_ftsAvailable) {
      try {
        await db.delete('memo_fts');
      } catch (_) {}
    }
  }

  // ============================================
  // Folder CRUD
  // ============================================

  Future<Folder> createFolder(Folder folder) async {
    final db = await instance.database;
    await db.insert('folders', folder.toJson());
    return folder;
  }

  Future<List<Folder>> readAllFolders() async {
    final db = await instance.database;
    final result = await db.query('folders', orderBy: 'createdDate DESC');

    // 폴더별 카드 수를 단일 쿼리로 집계 (N+1 방지)
    final countRows = await db.rawQuery(
        'SELECT folderId, COUNT(*) as count FROM memo_cards WHERE folderId IS NOT NULL GROUP BY folderId');
    final counts = {
      for (final row in countRows) row['folderId'] as String: row['count'] as int,
    };

    return result.map((json) {
      final folder = Folder.fromJson(json);
      return folder.copyWith(itemCount: counts[folder.id] ?? 0);
    }).toList();
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
    const orderBy = 'captureDate DESC';

    List<Map<String, dynamic>> result;
    if (folderId == null) {
      result = await db.query(
        'memo_cards',
        where: 'folderId IS NULL',
        orderBy: orderBy,
      );
    } else {
      result = await db.query(
        'memo_cards',
        where: 'folderId = ?',
        whereArgs: [folderId],
        orderBy: orderBy,
      );
    }

    return result.map((r) => MemoCard.fromJson(_rowToCardJson(r))).toList();
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
