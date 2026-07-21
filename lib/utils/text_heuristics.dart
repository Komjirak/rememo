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

  /// UI 노이즈로 의심되는 저품질 제목 패턴 (시간·배터리·네비게이션 라벨 등)
  static final List<RegExp> _lowQualityTitlePatterns = [
    RegExp(r'^\d{1,2}:\d{2}(\s*(AM|PM|오전|오후))?$', caseSensitive: false), // 시간
    RegExp(r'^\d{1,3}\s*%$'), // 배터리
    RegExp(r'^[\d\s\.,:%\-+/]+$'), // 숫자·기호만
    RegExp(r'^(로그인|회원가입|검색|메뉴|홈|설정|닫기|취소|확인|공유|더보기|알림|전체|뒤로)$'),
    RegExp(r'^(login|sign\s?up|search|menu|home|settings|close|cancel|ok|share|more|back|next)$',
        caseSensitive: false),
    RegExp(r'^(screenshot|screen capture|new memory|new screenshot|web link|no title|제목 없음|스크린샷)$',
        caseSensitive: false),
  ];

  /// 제목이 화면에 보여주기에 저품질인지 판정.
  /// 분석 레벨 간 fallback 진행 여부를 결정할 때 사용한다.
  static bool isLowQualityTitle(String title) {
    final t = title.trim();
    if (t.length < 4) return true;
    return _lowQualityTitlePatterns.any((p) => p.hasMatch(t));
  }

  /// "핵심 포인트"(keyInsights)에 짧은 앱 이름·UI 라벨이 섞이지 않도록 정제.
  /// 인사이트는 최소한 하나의 사실을 담은 문장/구여야 하므로, 태그성 단어(예: "앱",
  /// "네이버앱", "사용법")보다 훨씬 긴 최소 길이를 요구한다.
  static List<String> filterInsights(List<String> insights) {
    return insights
        .map((i) => i.trim())
        .where((i) => i.length >= 6 && !isLowQualityTitle(i))
        .toList();
  }

  /// 문장 중요도 기반 추출 요약.
  /// "앞부분 자르기" 대신 위치·길이·정보 밀도·완결성을 점수화해
  /// 상위 문장을 원문 순서대로 조합한다. (규칙 기반 fallback 전용)
  static String summarizeByImportance(String text, {int maxLength = 200}) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return '';

    // 줄 → 문장 분리
    final sentences = <({String text, int index})>[];
    var idx = 0;
    for (final line in lines) {
      for (final s in line.split(RegExp(r'(?<=[.!?。！？])\s+'))) {
        final t = s.trim();
        if (t.length >= 8) sentences.add((text: t, index: idx++));
      }
    }
    if (sentences.isEmpty) {
      final joined = lines.join(' ');
      return joined.length <= maxLength ? joined : '${joined.substring(0, maxLength - 3)}...';
    }

    final total = sentences.length;
    double score(({String text, int index}) s) {
      final t = s.text;
      double sc = 0;
      // 적절한 길이 (너무 짧은 조각·너무 긴 벽 회피)
      if (t.length >= 20 && t.length <= 120) {
        sc += 3;
      } else if (t.length > 120) {
        sc += 1;
      }
      // 위치: 앞쪽 우선
      final rel = s.index / total;
      if (rel < 0.33) {
        sc += 2;
      } else if (rel < 0.66) {
        sc += 1;
      }
      // 완결된 문장
      if (RegExp(r'(다|요|[.!?。！？])$').hasMatch(t)) sc += 1.5;
      // 정보 밀도: 숫자·가격·날짜·단위
      if (RegExp(r'\d').hasMatch(t)) sc += 1.0;
      if (RegExp(r'(원|₩|\$|%|월\s*\d|일까지|시\s*\d{0,2}분?)').hasMatch(t)) sc += 0.8;
      // UI 노이즈 감점
      if (isLowQualityTitle(t)) sc -= 3;
      return sc;
    }

    final ranked = [...sentences]..sort((a, b) => score(b).compareTo(score(a)));

    // 상위 문장을 길이 한도 내에서 선택 후, 원문 순서로 재배열
    final selected = <({String text, int index})>[];
    var length = 0;
    for (final s in ranked) {
      if (selected.length >= 3) break;
      if (length + s.text.length > maxLength && selected.isNotEmpty) continue;
      selected.add(s);
      length += s.text.length + 1;
    }
    selected.sort((a, b) => a.index.compareTo(b.index));

    final summary = selected.map((s) => s.text).join(' ').trim();
    if (summary.isEmpty) return '';
    return summary.length <= maxLength + 40
        ? summary
        : '${summary.substring(0, maxLength + 37)}...';
  }
}
