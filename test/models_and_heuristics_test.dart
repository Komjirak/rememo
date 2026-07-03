import 'package:flutter_test/flutter_test.dart';
import 'package:stribe/models/memo_card.dart';
import 'package:stribe/utils/text_heuristics.dart';

void main() {
  group('MemoCard 리스트 필드 파싱', () {
    MemoCard baseCard(dynamic tags, dynamic insights) {
      return MemoCard.fromJson({
        'id': '1',
        'title': 't',
        'summary': 's',
        'category': 'Inbox',
        'tags': tags,
        'keyInsights': insights,
        'captureDate': '2026-07-01 09:00',
        'imageUrl': '',
      });
    }

    test('JSON 배열 문자열을 파싱한다', () {
      final card = baseCard('["a","b, c"]', '["런치 15,000원","마감 2/28"]');
      expect(card.tags, ['a', 'b, c']);
      expect(card.keyInsights, ['런치 15,000원', '마감 2/28']);
    });

    test('레거시 쉼표 문자열도 읽을 수 있다', () {
      final card = baseCard('a,b,c', 'x,y');
      expect(card.tags, ['a', 'b', 'c']);
      expect(card.keyInsights, ['x', 'y']);
    });

    test('List가 직접 오면 그대로 사용한다', () {
      final card = baseCard(['a'], ['b']);
      expect(card.tags, ['a']);
      expect(card.keyInsights, ['b']);
    });

    test('null/빈 문자열은 빈 리스트', () {
      final card = baseCard(null, '');
      expect(card.tags, isEmpty);
      expect(card.keyInsights, isEmpty);
    });
  });

  group('TextHeuristics', () {
    test('카테고리 추정 — 한국어 키워드', () {
      expect(TextHeuristics.detectCategory('오늘 회의 일정 공유합니다'), 'Work');
      expect(TextHeuristics.detectCategory('강남역 맛집 후기'), 'Food');
      expect(TextHeuristics.detectCategory('전혀 관련 없는 텍스트'), 'Inbox');
    });

    test('카테고리 정규화 — 자유 형식 입력', () {
      expect(TextHeuristics.normalizeCategory('food'), 'Food');
      expect(TextHeuristics.normalizeCategory('테크/개발'), 'Tech');
      expect(TextHeuristics.normalizeCategory('unknown-thing'), 'Inbox');
    });

    test('태그 추출 — 매칭 없으면 기본 태그', () {
      expect(TextHeuristics.extractTags('디자인 시스템 문서'), contains('Design'));
      expect(TextHeuristics.extractTags('zzz'), ['Imported']);
    });
  });
}
