import 'package:stribe/models/folder.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/services/database_helper.dart';

/// 메모/폴더 데이터 접근 계층.
/// UI는 DatabaseHelper를 직접 만지지 않고 이 저장소를 통해서만 접근한다.
/// (추후 상태관리 도입, 원격 동기화, 테스트 대역 주입의 기반)
class MemoRepository {
  MemoRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  static final MemoRepository instance = MemoRepository();

  // ── MemoCard ──────────────────────────────────────────────

  Future<MemoCard> create(MemoCard card) => _db.create(card);

  Future<List<MemoCard>> getAll() => _db.readAllMemoCards();

  Future<List<MemoCard>> getByFolder(String? folderId) =>
      _db.readMemoCardsByFolder(folderId);

  /// 전문 검색 (FTS5, 미지원 시 LIKE 폴백)
  Future<List<MemoCard>> search(String query) => _db.searchMemoCards(query);

  Future<int> update(MemoCard card) => _db.update(card);

  Future<int> delete(String id) => _db.delete(id);

  Future<int> moveToFolder(String cardId, String? folderId) =>
      _db.moveMemoCardToFolder(cardId, folderId);

  // ── Folder ────────────────────────────────────────────────

  Future<Folder> createFolder(Folder folder) => _db.createFolder(folder);

  Future<List<Folder>> getAllFolders() => _db.readAllFolders();

  Future<int> updateFolder(Folder folder) => _db.updateFolder(folder);

  Future<int> deleteFolder(String id) => _db.deleteFolder(id);
}
