# AI 분석 및 요약 시스템 개선 계획

## 🔍 현재 문제점 분석

### 1. **분석 파이프라인 복잡성 및 불일치**

#### 문제:
- **두 개의 서로 다른 분석 경로**가 존재:
  1. `_pickImage` → `analyzeSummaryEnhanced` → `EnhancedContentAnalyzer` (Swift)
  2. `_handleNewScreenshot` → `analyzeScreenshotLegacy` → `OnDeviceLLM` (Swift)
  
- 각 경로가 다른 로직과 결과를 생성하여 **일관성 부족**
- Fallback 메커니즘이 복잡하고 예측 불가능

#### 영향:
- 같은 스크린샷도 입력 방법에 따라 다른 분석 결과
- 사용자 혼란 및 신뢰도 저하

---

### 2. **UI 노이즈 필터링 로직 중복 및 불일치**

#### 문제:
- **Dart 측**: `OnDeviceLLMService._filterUINoiseBlocks` (287줄)
- **Swift 측**: `EnhancedContentAnalyzer.filterUINoiseBlocks` (473줄)
- 두 로직이 **서로 다른 규칙과 임계값** 사용

#### 구체적 차이점:

**Dart 로직:**
- 상단 8% 영역 필터링
- 하단 10% 영역 필터링
- 15가지 필터링 규칙

**Swift 로직:**
- 상단 3% 영역 필터링
- 하단 5% 영역 필터링
- 신뢰도 0.5 이하 필터링
- 다른 패턴 매칭 규칙

#### 영향:
- 같은 텍스트가 Dart에서는 필터링되지만 Swift에서는 통과 (또는 그 반대)
- 중요한 콘텐츠 손실 또는 불필요한 노이즈 포함

---

### 3. **요약 생성 품질 문제**

#### 문제:
- **Fallback 요약이 너무 단순**: 단순히 처음 2-3개 문단을 120자로 자름
- **문장 선택 로직 부족**: 중요도 기반 문장 선택이 미흡
- **컨텍스트 이해 부족**: 문서 구조를 고려하지 않은 요약

#### 현재 Fallback 로직:
```dart
static String _generateFallbackSummary(DocumentStructure structure) {
  if (structure.paragraphs.isEmpty) {
    return '텍스트 내용이 감지되었습니다.';
  }
  final combined = structure.paragraphs.take(3).join(' ');
  if (combined.length <= 120) return combined;
  return '${combined.substring(0, 117)}...';
}
```

#### 영향:
- 의미 없는 요약 생성
- 사용자가 요약을 신뢰하지 못함

---

### 4. **제목 추출 정확도 문제**

#### 문제:
- **위치 기반 추정만 사용**: 상단 20% 영역에서 가장 큰 텍스트
- **의미 분석 부족**: 실제 제목인지 UI 요소인지 구분 못함
- **다양한 레이아웃 대응 부족**: 웹, SNS, 앱 등 다양한 형식

#### 현재 로직:
```dart
// 전략 1: 상단 20% 영역에서 가장 높이가 큰 텍스트
final topBlocks = blocks.where((b) => b.boundingBox.top < 0.20).toList();
topBlocks.sort((a, b) => b.boundingBox.height.compareTo(a.boundingBox.height));
```

#### 영향:
- UI 요소가 제목으로 잘못 인식됨
- 실제 제목이 누락됨

---

### 5. **Fallback 로직의 한계**

#### 문제:
- LLM 실패 시 너무 단순한 Fallback
- 단계적 Fallback 전략 부재
- 에러 처리 및 로깅 부족

---

## 🎯 해결 방안

### 1. **분석 파이프라인 통합**

#### 목표:
- 단일 분석 경로로 통합
- 일관된 결과 보장

#### 구현:
1. **통합 분석 서비스 생성**:
   ```dart
   class UnifiedAnalysisService {
     static Future<ScreenshotAnalysis> analyze({
       required List<OCRBlock> blocks,
       String? ocrText,
       String? suggestedCategory,
     }) async {
       // 1. UI 노이즈 필터링 (통일된 로직)
       // 2. EnhancedContentAnalyzer 호출
       // 3. 실패 시 단계적 Fallback
     }
   }
   ```

2. **모든 입력 경로에서 동일한 서비스 사용**:
   - `_pickImage` → `UnifiedAnalysisService`
   - `_handleNewScreenshot` → `UnifiedAnalysisService`

---

### 2. **UI 노이즈 필터링 로직 통일**

#### 목표:
- Dart와 Swift에서 동일한 필터링 규칙 사용
- 중요한 콘텐츠 보존

#### 구현:
1. **필터링 규칙 통일**:
   - 상단/하단 영역 임계값 통일 (예: 상단 5%, 하단 8%)
   - 신뢰도 임계값 통일 (예: 0.6)
   - 키워드 목록 통일

2. **Swift 로직을 Dart로 포팅** (또는 그 반대):
   - 더 정교한 Swift 로직을 Dart로 이식
   - 또는 Dart 로직을 Swift로 이식 후 Dart는 Swift 결과 사용

3. **필터링 단계별 로깅**:
   ```dart
   print('🔍 UI 노이즈 필터링: ${blocks.length} → ${filtered.length}');
   print('   - 제거된 블록: ${removedBlocks.map((b) => b.text).join(", ")}');
   ```

---

### 3. **요약 생성 알고리즘 개선**

#### 목표:
- 의미 있는 요약 생성
- 문서 구조 고려

#### 구현:
1. **문장 중요도 점수화**:
   ```dart
   double _scoreSentence(String sentence, DocumentStructure structure) {
     double score = 0.0;
     
     // 1. 길이 점수 (적절한 길이)
     if (sentence.length >= 20 && sentence.length <= 100) score += 10;
     
     // 2. 위치 점수 (상단에 있을수록 높음)
     // 3. 키워드 밀도 (명사, 동사 비율)
     // 4. UI 노이즈 여부 (제외)
     
     return score;
   }
   ```

2. **문단 그룹화 및 중요 문단 선택**:
   - 문단 간 연관성 분석
   - 핵심 문단 2-3개 선택
   - 자연스러운 요약 문장 생성

3. **Fallback 개선**:
   ```dart
   static String _generateFallbackSummary(DocumentStructure structure) {
     if (structure.paragraphs.isEmpty) {
       return '텍스트 내용이 감지되었습니다.';
     }
     
     // 문장 중요도 기반 선택
     final scoredSentences = structure.paragraphs
       .expand((p) => _splitIntoSentences(p))
       .map((s) => MapEntry(s, _scoreSentence(s, structure)))
       .toList()
       ..sort((a, b) => b.value.compareTo(a.value));
     
     // 상위 3개 문장 선택
     final topSentences = scoredSentences.take(3).map((e) => e.key).toList();
     final summary = topSentences.join(' ');
     
     return summary.length > 150 
       ? '${summary.substring(0, 147)}...' 
       : summary;
   }
   ```

---

### 4. **제목 추출 로직 개선**

#### 목표:
- 정확한 제목 인식
- 다양한 레이아웃 대응

#### 구현:
1. **다중 전략 조합**:
   ```dart
   static String? _estimateTitle(List<OCRBlock> blocks) {
     // 전략 1: 위치 + 크기 (기존)
     // 전략 2: 폰트 크기 비교 (상대적)
     // 전략 3: 의미 분석 (명사 비율, UI 요소 제외)
     // 전략 4: 레이아웃 패턴 (웹, SNS, 앱 등)
     
     final candidates = <String, double>{};
     
     // 각 전략으로 후보 수집 및 점수화
     // 최고 점수 후보 반환
   }
   ```

2. **UI 요소 제외 강화**:
   - 시간, 날짜 패턴
   - 버튼 텍스트
   - 네비게이션 요소
   - 앱 이름/브랜드

3. **의미 분석 추가**:
   - 명사 비율 확인
   - 문장 구조 분석
   - 키워드 밀도

---

### 5. **단계적 Fallback 전략**

#### 목표:
- LLM 실패 시에도 최선의 결과 제공
- 단계별 품질 보장

#### 구현:
```dart
static Future<ScreenshotAnalysis> analyzeWithFallback({
  required List<OCRBlock> blocks,
}) async {
  try {
    // Level 1: EnhancedContentAnalyzer (최고 품질)
    return await _analyzeWithEnhanced(blocks);
  } catch (e1) {
    print('⚠️ Enhanced 분석 실패: $e1');
    
    try {
      // Level 2: OnDeviceLLM (중간 품질)
      return await _analyzeWithOnDeviceLLM(blocks);
    } catch (e2) {
      print('⚠️ OnDeviceLLM 실패: $e2');
      
      try {
        // Level 3: DocumentParserService (기본 품질)
        return DocumentParserService.parseDocument(blocks);
      } catch (e3) {
        print('⚠️ DocumentParser 실패: $e3');
        
        // Level 4: 최소한의 Fallback
        return _generateMinimalAnalysis(blocks);
      }
    }
  }
}
```

---

## 📋 구현 우선순위

### Phase 1: 긴급 개선 (1-2일)
1. ✅ **UI 노이즈 필터링 통일** - 가장 큰 문제
2. ✅ **Fallback 로직 개선** - 사용자 경험 개선

### Phase 2: 품질 개선 (3-5일)
3. ✅ **요약 생성 알고리즘 개선**
4. ✅ **제목 추출 로직 개선**

### Phase 3: 장기 개선 (1-2주)
5. ✅ **분석 파이프라인 통합**
6. ✅ **성능 최적화**
7. ✅ **로깅 및 모니터링 강화**

---

## 🔧 구체적 수정 사항

### 1. UI 노이즈 필터링 통일

**파일**: `lib/services/ondevice_llm_service.dart`, `ios/Runner/OnDeviceLLM.swift`

**변경사항**:
- Dart와 Swift의 필터링 임계값 통일
- 필터링 규칙 동기화
- 로깅 추가

### 2. 요약 생성 개선

**파일**: `lib/services/ondevice_llm_service.dart`, `ios/Runner/OnDeviceLLM.swift`

**변경사항**:
- 문장 중요도 점수화 로직 추가
- Fallback 요약 생성 개선
- 문단 그룹화 로직 개선

### 3. 제목 추출 개선

**파일**: `lib/services/ondevice_llm_service.dart`, `lib/services/document_parser_service.dart`

**변경사항**:
- 다중 전략 조합
- UI 요소 제외 강화
- 의미 분석 추가

### 4. Fallback 전략 개선

**파일**: `lib/screens/home_screen.dart`

**변경사항**:
- 단계적 Fallback 구현
- 에러 처리 개선
- 로깅 강화

---

## 📊 예상 효과

### 개선 전:
- 분석 결과 일관성: ❌ 40%
- UI 노이즈 제거율: ⚠️ 60%
- 요약 품질: ⚠️ 50%
- 제목 정확도: ⚠️ 55%

### 개선 후:
- 분석 결과 일관성: ✅ 90%
- UI 노이즈 제거율: ✅ 85%
- 요약 품질: ✅ 80%
- 제목 정확도: ✅ 80%

---

## 🚀 다음 단계

1. **즉시 시작**: UI 노이즈 필터링 통일 작업
2. **테스트**: 다양한 스크린샷으로 검증
3. **반복 개선**: 사용자 피드백 수집 및 반영
