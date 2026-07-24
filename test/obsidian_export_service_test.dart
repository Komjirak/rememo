import 'package:flutter_test/flutter_test.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/services/obsidian_export_service.dart';

void main() {
  MemoCard baseCard({
    String id = 'abc123',
    String title = '강남역 이탈리안 맛집 후기',
    String summary = '파스타와 피자가 맛있다는 평이 많고, 런치 세트가 15,000원으로 가성비가 좋습니다.',
    String category = 'Food',
    List<String> tags = const ['맛집', '이탈리안'],
    List<String> keyInsights = const ['런치 세트 15,000원 (11:30-14:00)'],
    String? sourceUrl,
    String? personalNote,
    String? ocrText,
    bool isFavorite = false,
  }) {
    return MemoCard(
      id: id,
      title: title,
      summary: summary,
      category: category,
      tags: tags,
      keyInsights: keyInsights,
      captureDate: '2026-07-24 10:30',
      imageUrl: '',
      sourceUrl: sourceUrl,
      personalNote: personalNote,
      ocrText: ocrText,
      isFavorite: isFavorite,
    );
  }

  group('ObsidianExportService.sanitizeSegment', () {
    test('파일 시스템 금지 문자를 공백으로 치환한다', () {
      expect(ObsidianExportService.sanitizeSegment('a/b:c*d?e'), 'a b c d e');
    });

    test('빈 문자열은 Untitled로 대체된다', () {
      expect(ObsidianExportService.sanitizeSegment('   '), 'Untitled');
    });

    test('길이 제한을 넘으면 자른다', () {
      final long = 'a' * 100;
      final result = ObsidianExportService.sanitizeSegment(long, maxLength: 10);
      expect(result.length, 10);
    });

    test('연속 공백을 하나로 합친다', () {
      expect(ObsidianExportService.sanitizeSegment('a   b'), 'a b');
    });
  });

  group('ObsidianExportService.buildMarkdown', () {
    test('YAML 프론트매터에 제목/카테고리/태그가 포함된다', () {
      final md = ObsidianExportService.buildMarkdown(baseCard(), null);
      expect(md, contains('title: "강남역 이탈리안 맛집 후기"'));
      expect(md, contains('category: Food'));
      expect(md, contains('"맛집"'));
      expect(md, contains('"이탈리안"'));
    });

    test('본문에 요약과 핵심 포인트가 포함된다', () {
      final md = ObsidianExportService.buildMarkdown(baseCard(), null);
      expect(md, contains('## AI 요약'));
      expect(md, contains('런치 세트가 15,000원'));
      expect(md, contains('## 핵심 포인트'));
      expect(md, contains('- 런치 세트 15,000원 (11:30-14:00)'));
    });

    test('첨부 이미지가 있으면 Obsidian 임베드 구문을 넣는다', () {
      final md = ObsidianExportService.buildMarkdown(
        baseCard(),
        'attachments/foo.jpg',
      );
      expect(md, contains('![[attachments/foo.jpg]]'));
    });

    test('개인 메모/출처/원본 텍스트가 없으면 해당 섹션을 생략한다', () {
      final md = ObsidianExportService.buildMarkdown(baseCard(), null);
      expect(md, isNot(contains('## 개인 메모')));
      expect(md, isNot(contains('## 출처')));
      expect(md, isNot(contains('## 원본 텍스트')));
    });

    test('개인 메모/출처/원본 텍스트가 있으면 포함한다', () {
      final md = ObsidianExportService.buildMarkdown(
        baseCard(
          sourceUrl: 'https://example.com/article',
          personalNote: '다음에 꼭 가보기',
          ocrText: '원본 OCR 텍스트',
        ),
        null,
      );
      expect(md, contains('## 개인 메모'));
      expect(md, contains('다음에 꼭 가보기'));
      expect(md, contains('## 출처'));
      expect(md, contains('https://example.com/article'));
      expect(md, contains('## 원본 텍스트'));
      expect(md, contains('원본 OCR 텍스트'));
    });

    test('제목에 큰따옴표가 있어도 YAML이 깨지지 않도록 이스케이프한다', () {
      final md = ObsidianExportService.buildMarkdown(
        baseCard(title: '이것은 "인용"이 있는 제목'),
        null,
      );
      expect(md, contains(r'title: "이것은 \"인용\"이 있는 제목"'));
    });
  });
}
