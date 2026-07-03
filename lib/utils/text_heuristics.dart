/// 텍스트 기반 카테고리/태그 추정 휴리스틱.
/// home_screen과 share_service에 중복돼 있던 로직을 한 곳으로 통합.
/// AI 분석(Level 0~1)이 실패했을 때의 fallback으로만 사용한다.
class TextHeuristics {
  TextHeuristics._();

  static const List<String> validCategories = [
    'Design', 'Tech', 'Food', 'Shopping', 'Work',
    'Inspiration', 'Web', 'Personal', 'Inbox',
  ];

  /// 키워드 → 카테고리 매핑 (검사 순서 유지)
  static const Map<String, List<String>> _categoryKeywords = {
    'Food': [
      'food', 'recipe', 'cooking', 'restaurant', 'menu',
      '음식', '요리', '레시피', '맛집', '식당', '메뉴',
    ],
    'Shopping': [
      'buy', 'shopping', 'purchase', 'price', 'sale', 'discount', 'payment',
      '쇼핑', '구매', '할인', '결제', '세일', '가격',
    ],
    'Work': [
      'meeting', 'office', 'project', 'deadline', 'schedule',
      '업무', '회의', '작업', '프로젝트', '일정', '마감',
    ],
    'Design': [
      'design', ' ui ', ' ux ', 'figma', 'typography',
      '디자인', '타이포', '폰트',
    ],
    'Tech': [
      'code', 'programming', 'development', 'developer', 'api', 'flutter',
      '코드', '개발', '프로그래밍',
    ],
    'Inspiration': [
      'inspiration', 'idea', 'creative',
      '영감', '아이디어',
    ],
  };

  /// 태그 후보 키워드 → 태그 매핑
  static const Map<String, String> _tagKeywords = {
    'design': 'Design', 'ui': 'Design', 'ux': 'Design', '디자인': 'Design',
    'code': 'Tech', 'programming': 'Tech', 'tech': 'Tech',
    'development': 'Tech', '개발': 'Tech', '코드': 'Tech', '프로그래밍': 'Tech',
    'food': 'Food', 'recipe': 'Food', 'cooking': 'Food', 'restaurant': 'Food',
    '음식': 'Food', '요리': 'Food', '레시피': 'Food', '맛집': 'Food', '식당': 'Food',
    'work': 'Work', 'meeting': 'Work', 'office': 'Work', 'project': 'Work',
    '회의': 'Work', '업무': 'Work', '작업': 'Work', '프로젝트': 'Work',
    'buy': 'Shopping', 'shopping': 'Shopping', 'purchase': 'Shopping',
    '쇼핑': 'Shopping', '구매': 'Shopping', '할인': 'Shopping',
    'inspiration': 'Inspiration', 'idea': 'Inspiration', 'creative': 'Inspiration',
    '영감': 'Inspiration', '아이디어': 'Inspiration',
  };

  /// 텍스트에서 카테고리 추정 (매칭 실패 시 'Inbox')
  static String detectCategory(String text) {
    if (text.isEmpty) return 'Inbox';
    final lower = ' ${text.toLowerCase()} ';
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword.toLowerCase())) return entry.key;
      }
    }
    if (lower.contains('http') || lower.contains('.com') || lower.contains('www')) {
      return 'Web';
    }
    return 'Inbox';
  }

  /// 카테고리 문자열 정규화 (AI 응답의 자유 형식 카테고리를 표준 카테고리로)
  static String normalizeCategory(String category) {
    for (final valid in validCategories) {
      if (category.toLowerCase() == valid.toLowerCase()) return valid;
    }
    final lower = category.toLowerCase();
    if (lower.contains('design') || lower.contains('디자인')) return 'Design';
    if (lower.contains('tech') || lower.contains('개발') || lower.contains('코드')) return 'Tech';
    if (lower.contains('food') || lower.contains('음식') || lower.contains('맛집')) return 'Food';
    if (lower.contains('shop') || lower.contains('쇼핑') || lower.contains('구매')) return 'Shopping';
    if (lower.contains('work') || lower.contains('업무') || lower.contains('회의')) return 'Work';
    if (lower.contains('inspir') || lower.contains('영감')) return 'Inspiration';
    if (lower.contains('web') || lower.contains('웹')) return 'Web';
    if (lower.contains('personal') || lower.contains('개인')) return 'Personal';
    return 'Inbox';
  }

  /// 텍스트에서 태그 추출 (최대 [max]개)
  static List<String> extractTags(String text, {int max = 3}) {
    final tags = <String>[];
    final lower = text.toLowerCase();
    for (final entry in _tagKeywords.entries) {
      if (lower.contains(entry.key.toLowerCase()) && !tags.contains(entry.value)) {
        tags.add(entry.value);
        if (tags.length >= max) break;
      }
    }
    if (tags.isEmpty) tags.add('Imported');
    return tags;
  }
}
