import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/services/database_helper.dart';

/// DatabaseHelper 통합 테스트 (sqflite_common_ffi 사용, 데스크톱에서 실행)
///
/// 검증 대상:
/// 1. v8(쉼표 join) → v9(JSON) 마이그레이션 시 쉼표 포함 keyInsights가 깨지지 않는지
/// 2. 쉼표/특수문자가 포함된 리스트 필드의 round-trip
/// 3. FTS 전문 검색 동작
void main() {
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper.instance.close();
    dbPath = p.join(await getDatabasesPath(), 'folio.db');
    await deleteDatabase(dbPath);
  });

  /// v8 스키마(쉼표 join 저장) DB를 만들어 레거시 상태를 재현
  Future<void> createLegacyV8Database() async {
    final db = await openDatabase(dbPath, version: 8,
        onCreate: (db, version) async {
      await db.execute('''
CREATE TABLE memo_cards (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  category TEXT NOT NULL,
  sourceType TEXT NOT NULL,
  contentType TEXT NOT NULL,
  tags TEXT NOT NULL,
  keyInsights TEXT,
  captureDate TEXT NOT NULL,
  sourceUrl TEXT,
  imageUrl TEXT NOT NULL,
  ocrText TEXT,
  personalNote TEXT,
  folderId TEXT,
  isFavorite INTEGER DEFAULT 0,
  wasTranslated INTEGER DEFAULT 0,
  originalTitle TEXT,
  originalSummary TEXT
)
''');
      await db.execute('''
CREATE TABLE folders (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  createdDate TEXT NOT NULL
)
''');
    });

    // 레거시 방식(쉼표 join)으로 저장된 카드 — keyInsights에 쉼표 포함
    await db.insert('memo_cards', {
      'id': 'legacy-1',
      'title': '강남 맛집',
      'summary': '이탈리안 레스토랑 후기',
      'category': 'Food',
      'sourceType': 'screenshot',
      'contentType': 'restaurant',
      'tags': '맛집,이탈리안,강남',
      'keyInsights': '런치 세트 15,000원 (11:30-14:00),주차 가능',
      'captureDate': '2026-07-01 12:00',
      'imageUrl': '/tmp/test.jpg',
    });
    await db.close();
  }

  test('v8 → v9 마이그레이션: 태그는 보존, 쉼표 포함 insight는 레거시 한계 내에서 복원', () async {
    await createLegacyV8Database();

    final helper = DatabaseHelper.instance;
    final cards = await helper.readAllMemoCards();

    expect(cards.length, 1);
    final card = cards.first;
    // 쉼표 없는 tags는 완벽히 복원되어야 함
    expect(card.tags, ['맛집', '이탈리안', '강남']);
    // 레거시 데이터의 keyInsights는 쉼표 기준으로 이미 손상된 상태로 저장돼 있었음
    // (마이그레이션은 JSON으로 감싸 이후의 추가 손상을 방지)
    expect(card.keyInsights, isNotEmpty);
  });

  test('신규 저장: 쉼표 포함 keyInsights가 그대로 round-trip 된다', () async {
    final helper = DatabaseHelper.instance;

    final card = MemoCard(
      id: 'new-1',
      title: '나이키 할인',
      summary: '에어맥스 30% 할인 정보',
      category: 'Shopping',
      tags: ['할인', '나이키', 'C++, Dart'], // 태그에 쉼표가 있어도 보존
      keyInsights: ['런치 세트 15,000원 (11:30-14:00)', '할인 마감 2월 28일'],
      captureDate: '2026-07-02 10:00',
      imageUrl: '/tmp/test2.jpg',
    );

    await helper.create(card);
    final loaded = (await helper.readAllMemoCards())
        .firstWhere((c) => c.id == 'new-1');

    expect(loaded.keyInsights, ['런치 세트 15,000원 (11:30-14:00)', '할인 마감 2월 28일']);
    expect(loaded.tags, ['할인', '나이키', 'C++, Dart']);
  });

  test('전문 검색: title/ocrText/tags에서 검색어를 찾는다', () async {
    final helper = DatabaseHelper.instance;

    await helper.create(MemoCard(
      id: 's-1',
      title: 'Flutter 상태관리 비교',
      summary: 'Riverpod과 Bloc 비교 글',
      category: 'Tech',
      tags: ['Flutter', 'Riverpod'],
      captureDate: '2026-07-01 09:00',
      imageUrl: '',
      ocrText: 'Riverpod은 컴파일 타임 안전성을 제공한다',
    ));
    await helper.create(MemoCard(
      id: 's-2',
      title: '토마토 파스타 레시피',
      summary: '조리 시간 20분',
      category: 'Food',
      tags: ['레시피'],
      captureDate: '2026-07-02 09:00',
      imageUrl: '',
      ocrText: '재료: 마늘, 올리브유, 토마토소스',
    ));

    final byTitle = await helper.searchMemoCards('Flutter');
    expect(byTitle.map((c) => c.id), contains('s-1'));
    expect(byTitle.map((c) => c.id), isNot(contains('s-2')));

    final byOcr = await helper.searchMemoCards('올리브유');
    expect(byOcr.map((c) => c.id), contains('s-2'));

    final byTag = await helper.searchMemoCards('Riverpod');
    expect(byTag.map((c) => c.id), contains('s-1'));
  });

  test('업데이트 후 검색 인덱스도 갱신된다', () async {
    final helper = DatabaseHelper.instance;

    final card = MemoCard(
      id: 'u-1',
      title: '원래 제목',
      summary: '요약',
      category: 'Inbox',
      tags: [],
      captureDate: '2026-07-01 09:00',
      imageUrl: '',
    );
    await helper.create(card);
    await helper.update(card.copyWith(title: '수정된 유니크제목'));

    final results = await helper.searchMemoCards('유니크제목');
    expect(results.map((c) => c.id), contains('u-1'));

    await helper.delete('u-1');
    final afterDelete = await helper.searchMemoCards('유니크제목');
    expect(afterDelete.map((c) => c.id), isNot(contains('u-1')));
  });

  test('폴더 카운트가 단일 쿼리 집계로 정확하다', () async {
    final helper = DatabaseHelper.instance;
    final db = await helper.database;
    await db.insert('folders', {
      'id': 'f-1',
      'name': '디자인',
      'color': '#FF0000',
      'createdDate': '2026-07-01',
    });

    await helper.create(MemoCard(
      id: 'fc-1',
      title: 'a',
      summary: 'b',
      category: 'Design',
      tags: [],
      captureDate: '2026-07-01 09:00',
      imageUrl: '',
      folderId: 'f-1',
    ));
    await helper.create(MemoCard(
      id: 'fc-2',
      title: 'c',
      summary: 'd',
      category: 'Design',
      tags: [],
      captureDate: '2026-07-01 09:10',
      imageUrl: '',
      folderId: 'f-1',
    ));

    final folders = await helper.readAllFolders();
    expect(folders.first.itemCount, 2);
  });
}
