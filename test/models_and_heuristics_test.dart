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

    test('저품질 제목 판정 — UI 노이즈 패턴', () {
      expect(TextHeuristics.isLowQualityTitle('9:41'), isTrue);
      expect(TextHeuristics.isLowQualityTitle('100%'), isTrue);
      expect(TextHeuristics.isLowQualityTitle('로그인'), isTrue);
      expect(TextHeuristics.isLowQualityTitle('Search'), isTrue);
      expect(TextHeuristics.isLowQualityTitle('ab'), isTrue); // 너무 짧음
      expect(TextHeuristics.isLowQualityTitle('Screenshot'), isTrue);
      expect(TextHeuristics.isLowQualityTitle('강남역 이탈리안 맛집 후기'), isFalse);
      expect(TextHeuristics.isLowQualityTitle('Flutter 상태관리 비교'), isFalse);
    });

    test('중요도 요약 — 정보 밀도 높은 문장을 앞부분 대신 선택한다', () {
      const text = '메뉴\n'
          '로그인\n'
          '강남역 이탈리안 레스토랑 라쿠치나에 다녀왔습니다.\n'
          '런치 세트가 15,000원으로 가성비가 좋았습니다.\n'
          '좋아요\n'
          '댓글 달기';
      final summary = TextHeuristics.summarizeByImportance(text);
      expect(summary, contains('15,000원'));
      expect(summary, isNot(contains('로그인')));
      expect(summary, isNot(contains('댓글 달기')));
    });

    test('중요도 요약 — 원문 순서를 유지하고 길이를 제한한다', () {
      final longText = List.generate(
        20,
        (i) => '이것은 ${i + 1}번째 문단으로 충분히 길고 의미가 있는 문장입니다.',
      ).join('\n');
      final summary = TextHeuristics.summarizeByImportance(longText, maxLength: 150);
      expect(summary.length, lessThanOrEqualTo(190));
      expect(summary, isNotEmpty);
    });

    test('중요도 요약 — 빈 입력은 빈 문자열', () {
      expect(TextHeuristics.summarizeByImportance(''), isEmpty);
      expect(TextHeuristics.summarizeByImportance('   \n  '), isEmpty);
    });

    test('핵심 포인트 필터 — 짧은 앱 이름/UI 라벨 제거', () {
      final filtered = TextHeuristics.filterInsights(
        ['네이버앱', '앱', '사용법', '런치 세트 15,000원 (11:30-14:00)', '할인 마감 2월 28일'],
      );
      expect(filtered, ['런치 세트 15,000원 (11:30-14:00)', '할인 마감 2월 28일']);
    });

    test('핵심 포인트 필터 — 빈 리스트는 그대로 빈 리스트', () {
      expect(TextHeuristics.filterInsights([]), isEmpty);
    });
  });
}
