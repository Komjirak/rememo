import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stribe/models/folder.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/utils/app_logger.dart';

/// zip/폴더 직접 쓰기 양쪽에서 공유하는 한 개의 내보낼 파일(마크다운 또는 첨부 이미지).
class ObsidianExportFile {
  final String relativePath;
  final List<int> bytes;

  const ObsidianExportFile(this.relativePath, this.bytes);
}

/// 메모 카드들을 Obsidian 호환 마크다운(YAML 프론트매터 + 본문)으로 변환하는 서비스.
/// 서버/계정 없이 완전히 기기 내에서 처리한다. 결과물은 두 가지 방식으로 전달할 수 있다:
/// - zip으로 묶어 OS 공유 시트로 전달(수동 내보내기)
/// - 파일 목록([buildManifest])을 그대로 네이티브 폴더 쓰기 채널에 전달(자동 내보내기)
class ObsidianExportService {
  /// [cards]를 마크다운(+첨부 이미지) 파일 목록으로 변환한다.
  /// 폴더가 지정된 카드는 `폴더명/제목.md`로, 없으면 `Inbox/제목.md`로 배치한다.
  /// 이미지가 있는 카드는 `attachments/`에 원본 이미지를 함께 담고
  /// 마크다운 본문에서 `![[attachments/파일명]]`으로 임베드한다.
  static Future<List<ObsidianExportFile>> buildManifest(
    List<MemoCard> cards, {
    required List<Folder> folders,
  }) async {
    final folderNames = {for (final f in folders) f.id: f.name};
    final files = <ObsidianExportFile>[];
    final usedPaths = <String>{};

    for (final card in cards) {
      final folderName = card.folderId != null
          ? (folderNames[card.folderId] ?? 'Inbox')
          : 'Inbox';
      final safeFolder = sanitizeSegment(folderName);

      String? attachmentRelPath;
      if (!card.imageUrl.startsWith('http')) {
        final imageFile = File(card.imageUrl);
        if (await imageFile.exists()) {
          final ext = card.imageUrl.split('.').last;
          final attachmentName = '${sanitizeSegment(card.title, maxLength: 40)}-${_shortId(card.id)}.$ext';
          attachmentRelPath = 'attachments/$attachmentName';
          final bytes = await imageFile.readAsBytes();
          files.add(ObsidianExportFile(attachmentRelPath, bytes));
        }
      }

      final markdown = buildMarkdown(card, attachmentRelPath);
      final baseName = '${sanitizeSegment(card.title, maxLength: 60)}-${_shortId(card.id)}.md';
      var relPath = '$safeFolder/$baseName';
      // 동일 폴더 내 파일명 충돌 방지 (제목이 같은 카드가 여러 개인 경우)
      var suffix = 2;
      while (usedPaths.contains(relPath)) {
        relPath = '$safeFolder/${baseName.replaceFirst('.md', '')}-$suffix.md';
        suffix++;
      }
      usedPaths.add(relPath);

      files.add(ObsidianExportFile(relPath, utf8.encode(markdown)));
    }

    return files;
  }

  /// [cards]를 마크다운으로 변환해 zip 파일로 만들고 경로를 반환한다.
  static Future<File> exportToZip(
    List<MemoCard> cards, {
    required List<Folder> folders,
  }) async {
    final manifest = await buildManifest(cards, folders: folders);
    final archive = Archive();
    for (final file in manifest) {
      archive.addFile(ArchiveFile(file.relativePath, file.bytes.length, file.bytes));
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw StateError('Failed to create zip archive');
    }
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFile = File('${tempDir.path}/Rememo-Obsidian-Export-$timestamp.zip');
    await zipFile.writeAsBytes(zipBytes);

    logInfo('✅ Obsidian export 완료: ${cards.length}개 카드 → ${zipFile.path}', name: 'ObsidianExport');
    return zipFile;
  }

  static String buildMarkdown(MemoCard card, String? attachmentRelPath) {
    final buffer = StringBuffer();

    // YAML 프론트매터
    buffer.writeln('---');
    buffer.writeln('title: "${_escapeYaml(card.title)}"');
    buffer.writeln('category: ${card.category}');
    buffer.writeln('source_type: ${card.sourceType}');
    if (card.tags.isNotEmpty || card.category.isNotEmpty) {
      final tagSet = <String>{card.category, ...card.tags};
      buffer.writeln('tags: [${tagSet.map((t) => '"${_escapeYaml(t)}"').join(', ')}]');
    }
    if (card.sourceUrl != null && card.sourceUrl!.isNotEmpty) {
      buffer.writeln('source: "${_escapeYaml(card.sourceUrl!)}"');
    }
    buffer.writeln('captured: "${card.captureDate}"');
    buffer.writeln('favorite: ${card.isFavorite}');
    buffer.writeln('---');
    buffer.writeln();

    buffer.writeln('# ${card.title}');
    buffer.writeln();

    if (attachmentRelPath != null) {
      buffer.writeln('![[$attachmentRelPath]]');
      buffer.writeln();
    }

    if (card.summary.isNotEmpty) {
      buffer.writeln('## AI 요약');
      buffer.writeln();
      buffer.writeln(card.summary);
      buffer.writeln();
    }

    if (card.keyInsights.isNotEmpty) {
      buffer.writeln('## 핵심 포인트');
      buffer.writeln();
      for (final insight in card.keyInsights) {
        buffer.writeln('- $insight');
      }
      buffer.writeln();
    }

    if (card.personalNote != null && card.personalNote!.isNotEmpty) {
      buffer.writeln('## 개인 메모');
      buffer.writeln();
      buffer.writeln(card.personalNote);
      buffer.writeln();
    }

    if (card.sourceUrl != null && card.sourceUrl!.isNotEmpty) {
      buffer.writeln('## 출처');
      buffer.writeln();
      buffer.writeln('[${card.sourceUrl}](${card.sourceUrl})');
      buffer.writeln();
    }

    if (card.ocrText != null && card.ocrText!.isNotEmpty) {
      buffer.writeln('## 원본 텍스트');
      buffer.writeln();
      buffer.writeln('```');
      buffer.writeln(card.ocrText);
      buffer.writeln('```');
      buffer.writeln();
    }

    return buffer.toString();
  }

  static String _escapeYaml(String text) =>
      text.replaceAll('\\', r'\\').replaceAll('"', r'\"').replaceAll('\n', ' ');

  /// 파일/폴더명으로 안전하지 않은 문자를 제거하고 길이를 제한한다.
  static String sanitizeSegment(String raw, {int maxLength = 80}) {
    var s = raw.trim();
    if (s.isEmpty) return 'Untitled';
    s = s.replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ').trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    if (s.length > maxLength) s = s.substring(0, maxLength).trim();
    return s.isEmpty ? 'Untitled' : s;
  }

  static String _shortId(String id) =>
      id.length <= 6 ? id : id.substring(id.length - 6);
}
