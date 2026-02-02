# 제목·AI Summary 해석 능력 개선 방향

스크린샷·URL 공통으로 제목 및 AI Summary 품질이 만족스럽지 않다는 피드백을 반영해, 코드 분석 결과와 개선 방향을 정리한 문서입니다.

---

## 1. 현재 파이프라인 요약

### 1.1 스크린샷 경로

```
이미지/스크린샷 → OCR(네이티브) → ocrBlocks + ocrText
  → UnifiedAnalysisService.analyze(blocks, ocrText, suggestedCategory)
    → Level 1: OnDeviceLLMService.analyzeSummaryEnhanced → EnhancedContentAnalyzer (Swift)
    → Level 2: OnDeviceLLMService.analyzeScreenshotLegacy → OnDeviceLLM (Gemma 2B)
    → Level 3: DocumentParserService.parseDocument
    → Level 4: _generateMinimalAnalysis (통합 서비스 내부)
  → ScreenshotAnalysis(title, summary, keyInsights)
```

- **제목**: Level별로 `_estimateTitle`(OnDeviceLLM), `_extractTitleGeneric`(DocumentParser), 상단 블록·첫 줄(Level 4) 등 서로 다른 규칙 사용.
- **요약**: Level 1·2는 네이티브/LLM, Level 3·4는 `_extractBodyText`·문단 조합·`_generateFallbackSummary` 등 규칙 기반.

### 1.2 URL 경로

```
공유 URL → Share Extension / share_service
  → fetchURLMetadata(url) → title, description, imageUrl, text(본문)
  → (본문 있으면) _generateAISummary(currentTitle, currentText)
      → _llmChannel.invokeMethod('analyzeSummary', { textBlocks, imageSize })
      → ContentAnalyzerAdapter → EnhancedContentAnalyzer / FoundationModels
  → SharedItem(suggestedTitle, summary, ocrText=currentText, …)
  → _createCardFromSharedItem()
      → finalOcrText = item.ocrText ?? item.text
      → (finalOcrText 있으면) _analyzeScreenshotOnDevice(finalOcrText)  // 줄 단위 가짜 블록
      → finalTitle: 비었거나 "Web Link"일 때만 analysis.title 사용
      → finalSummary: analysis.summary가 기존보다 길 때만 병합
```

- **제목**: 주로 메타데이터 title / suggestedTitle 사용. AI 분석 결과의 title은 **현재 사용하지 않음**.
- **요약**: 메타 description + (본문 있으면) AI 요약. 이후 _createCardFromSharedItem에서 스크린샷 분석 결과가 더 길 때만 summary를 덮어씀.

---

## 2. 스크린샷 제목·요약의 문제와 개선 방향

### 2.1 제목 추출

| 문제 | 원인 | 개선 방향 |
|------|------|-----------|
| 상단 UI가 제목으로 선택됨 | `_estimateTitle`이 “상단 + 큰 폰트”에 과도 의존. 앱 상단 바·탭 라벨 등이 상단 20~30%에 위치 | 상단 N% 안 블록에 “앱/브랜드·네비·시간·퍼센트” 등 **제외 패턴** 강화. 도메인(웹/SNS/쇼핑)별로 “진짜 제목” 후보만 남기는 휴리스틱 추가 |
| 실제 제목이 하단에 있는 경우 놓침 | “상단 20~30%” 고정 규칙 | “상단 우선”이지만, **도메인·레이아웃 추정** 후 “헤더 영역”을 유동적으로 넓히거나, 2~3개 후보를 뽑아 길이·의미 점수로 재순위화 |
| 텍스트만 있을 때(줄 단위 가짜 블록) 제목이 형편없음 | 모든 줄에 height=0.03 등으로 동일. `_extractTitleGeneric`이 “큰 폰트” 정렬해도 구분 불가 | **텍스트 전용 모드**: “첫 줄 / 짧은 헤더 패턴 / 긴 문단 제외” 등 **문단·줄 기반** 제목 후보 규칙을 DocumentParser·Unified 쪽에 별도 분기로 추가 |
| 도메인별 제목 규칙 부족 | DocumentParser는 shopping/map/sns 등에만 특화, 웹 기사·일반 문서는 generic에 맡김 | 웹 기사: “첫 번째 긴 줄 제외, 그 다음 중 짧은 줄” 등 **도메인별 제목 후보 규칙** 명시. 쇼핑/맵/SNS는 기존처럼 유지·보강 |

### 2.2 요약 생성

| 문제 | 원인 | 개선 방향 |
|------|------|-----------|
| 단순 “앞부분 자르기”에 가까운 경우 | Level 3·4에서 “상위 2~3 문단”·“처음 150자” 위주 사용 | `_generateFallbackSummary`처럼 **문장 단위 점수**를 Level 4·DocumentParser 쪽에도 적용. “위치 가중치 + 길이 + 키워드 밀도” 등으로 중요 문장만 선택해 요약 |
| 키워드·의미 반영 부족 | 키워드/엔티티 추출이 체계적으로 쓰이지 않음 | “가격·날짜·이름·숫자” 등 **간단 키워드 패턴**을 요약 문장 선택 시 보너스 점수로 반영. 도메인별(쇼핑=가격·상품명, 뉴스=도입문 등) **요약 템플릿** 선택 |
| 도메인 무시한 일괄 처리 | generic 도메인에서만 `_extractBodyText(limit: 150)` 수준 | 쇼핑/맵/SNS는 유지하고, **generic·웹 기사**에 “도입부 문장 우선 + 2문장 이내” 같은 규칙을 도메인별로 분리 |

### 2.3 스크린샷 파이프라인 정리

- **제목**:  
  - “상단·큰 글씨” 외에 **제외 패턴·도메인 규칙·텍스트 전용 모드**를 명확히 추가.  
  - 가능하면 Level 2·3·4가 **동일한 후보 생성/스코어링 인터페이스**를 공유해, 품질 비교·통합이 쉽게 할 것.
- **요약**:  
  - Level 3·4에서도 **문장 단위 점수 + 도메인별 템플릿** 사용.  
  - 스크린샷이든 URL이든 “긴 텍스트만 있을 때” 공통으로 쓸 **텍스트 전용 요약 로직** 하나 두고 재사용.

---

## 3. URL 제목·AI Summary의 문제와 개선 방향

### 3.1 제목

| 문제 | 원인 | 개선 방향 |
|------|------|-----------|
| AI가 만든 제목을 전혀 안 씀 | `_generateAISummary`는 네이티브에 title을 넘기지만, **반환값의 title은 사용하지 않음**. suggestedTitle = 메타 title만 사용 | **메타 제목이 비었거나 약할 때** `aiResult['title']`(또는 `suggestedTitle`)을 사용하도록 share_service·_createCardFromSharedItem 쪽 분기 추가. “약함” 조건: 길이 &lt; 3, 또는 보안/에러 페이지 등으로 판단된 경우 |
| 메타데이터 품질에 전적으로 의존 | fetchURLMetadata 결과가 나쁘면 제목 개선 여지가 없음 | 메타 title이 부족할 때, **본문 텍스트를 UnifiedAnalysisService에 넣어** 스크린샷과 동일한 4단계 파이프라인으로 제목 후보를 만들고, “메타 우선, 없으면 분석 제목”으로 병합 |

### 3.2 AI Summary

| 문제 | 원인 | 개선 방향 |
|------|------|-----------|
| URL 본문이 “평면” 블록으로만 전달됨 | `_generateAISummary`가 paragraph 단위로 `top: 0.5` 같은 **동일 Y**로 블록 생성. 구조 정보 없음 | **제목 후보 = 첫 1~2 문단**, **본문 = 나머지**처럼 역할을 나눠서 textBlocks를 구성. 예: 첫 문단 top=0.1, 나머지 top=0.2, 0.3, … 로 넘겨 “위에서부터 문서 구조”를 네이티브에 힌트로 제공 |
| 스크린샷 분석과 이중 구조 | URL은 share_service에서 AI 요약 후, 앱에서는 _analyzeScreenshotOnDevice(ocrText)로 **한 번 더** 분석. 결과 병합 규칙이 “summary가 더 길면 덮어쓰기” 수준 | **선택 1**: URL도 “메타 + 본문”을 **UnifiedAnalysisService 한 번만** 호출하도록 하고, 메타 title/description은 “우선 사용하되 비었을 때만 분석값”으로 통일. **선택 2**: 지금처럼 이중 호출이면, “제목은 메타 우선, AI 제목은 보강용”, “요약은 메타 요약 + AI 요약 중 더 구체적인 쪽” 등 **병합 규칙을 명시**해서 구현 |
| 메타 description이 곧 요약으로 고정됨 | description이 짧거나 비어 있으면 currentSummary가 빈 상태로 AI만 의존. AI 실패 시 보강 로직이 약함 | 메타 description이 비어 있거나 지나치게 짧을 때 **본문 앞부분 N자**를 임시 요약으로 두고, AI 결과가 오면 교체. 혹은 **UnifiedAnalysisService에 URL 본문을 넣어** Level 3·4 요약을 공통 fallback으로 사용 |

### 3.3 URL 파이프라인 정리

- **제목**:  
  - 메타데이터 title 우선.  
  - 비었거나 “약한” 경우에만 `aiResult['title']` 또는 **UnifiedAnalysisService 결과의 title** 사용.
- **요약**:  
  - 메타 description + AI 요약을 **역할을 나눠** 사용 가능 (예: 메타=한 줄 초록, AI=2~3문장 세부 요약).  
  - AI 입력 시 **첫 문단=제목 후보, 나머지=본문** 구조로 textBlocks를 만들어 전달.  
  - 가능하면 URL도 **UnifiedAnalysisService 한 번** 타서 제목·요약·키인사이트를 만들고, 메타와의 병합만 정책으로 두는 쪽이 일관성 있음.

---

## 4. 공통·인프라 개선

| 항목 | 내용 |
|------|------|
| **도메인 감지 공유** | DocumentParser의 `_identifyDomain`·category 매핑을, URL 처리에서도 “웹 기사 / 쇼핑 / SNS” 등으로 쓰고, 제목·요약 규칙 선택에 반영 |
| **“텍스트 전용” 모드** | Bounding box가 없거나 모두 동일할 때를 감지해, **줄/문단 기반 제목·요약 전용 로직**으로 분기. 스크린샷(텍스트만)·URL 본문·공유 텍스트에 같이 사용 |
| **검증·로깅** | 제목 후보 리스트·선택 사유, 요약에 쓰인 문장 수·출처 Level 등을 **개발 로그로 남겨** 품질 원인 분석이 쉽게 할 것 |
| **UnifiedAnalysisService에 URL 입력 연동** | `analyze(blocks: null, ocrText: urlBodyText, suggestedCategory: 'Web')` 형태로 URL 본문만 넣어도 4단계 Fallback이 돌도록 이미 가능. 여기서 나온 title/summary를 **메타데이터와 병합하는 정책**만 share_service·_createCardFromSharedItem에 넣으면, URL과 스크린샷이 동일한 “해석 능력”을 공유함 |

---

## 5. 우선순위 제안

1. **단기 (가장 효과 큰 것)**  
   - URL에서 **AI 분석 제목 사용**: 메타 title이 비었거나 약할 때 `aiResult['title']` 반영.  
   - URL 본문으로 **UnifiedAnalysisService 1회 호출** 후, 제목·요약을 메타와 병합하는 규칙 적용.  
   - 스크린샷 **텍스트 전용 모드**: 줄 단위 블록일 때 “첫 줄/짧은 줄/긴 문단 제외” 등 제목 후보 규칙 분리.

2. **중기**  
   - 제목 후보에서 **앱·UI 패턴 제외** 강화.  
   - Level 3·4 요약에 **문장 단위 점수 + 도메인별 템플릿** 도입.  
   - _generateAISummary에서 **첫 문단=제목, 나머지=본문** 구조로 textBlocks 구성.

3. **장기**  
   - 도메인 감지·제목/요약 규칙을 **설정·플러그인처럼** 분리해 웹/SNS/쇼핑 등 도메인별로 확장하기 쉽게 구성.

이 순서로 반영하면, “스크린샷·URL 모두에서 제목과 AI Summary 해석”이 눈에 띄게 개선될 여지가 큽니다.
