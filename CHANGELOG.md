## [Unreleased]

### Performance (로컬 분석 파이프라인)
- **Level 2("온디바이스 LLM") 무의미한 IPC 왕복 제거**: Dart가 native `analyzeSummary` 채널에 `title/paragraphs/keyPoints` 형태로 호출했지만 native 핸들러는 `textBlocks/imageSize`를 요구해 항상 `INVALID_ARGS`로 실패하고 있었음(실제 "Gemma 2B" 모델도 프로젝트에 존재하지 않음). 성공할 수 없는 MethodChannel 왕복을 없애고 규칙 기반 폴백으로 바로 진입하도록 변경.
- **Vision 분석 이미지 다운스케일 누락 수정**: `recognizeTextWithEnhancedAnalysis`(PaddleOCRHelper.swift)가 원본 최대 해상도 이미지에 OCR+레이아웃+세일리언시 3개 Vision 요청을 그대로 실행하고 있었음. 다른 OCR 경로처럼 2048px로 축소 후 처리하도록 통일해 스크린샷마다 분석 시간을 단축.
- **온디바이스 분석 체인에 타임아웃 추가**: Apple Foundation Models(Level 1) 응답에 12초 타임아웃(Swift), MethodChannel 호출에 15초 타임아웃(Dart) 추가. 기존엔 타임아웃이 전혀 없어 온디바이스 LLM 응답이 지연되면 항상 빠르게 성공하도록 설계된 Level 2~4로 넘어가지 못하고 "분석 중..." 상태로 멈출 수 있었음.
- **UI 노이즈 필터링 정규식/키워드 사전 컴파일**: `ondevice_llm_service.dart`의 노이즈 필터링 헬퍼들이 OCR 블록(스크린샷 1장당 수십~수백 개)마다 정규식과 키워드 리스트를 매번 새로 생성하고 있었음. 전부 static final로 한 번만 컴파일해 재사용하도록 리팩터링(동작 동일, 불필요한 할당만 제거). 키워드 목록도 List→Set으로 바꿔 조회를 O(n)에서 O(1)로 개선.

### Fixed (중복 저장 · 핵심 포인트)
- **URL 공유 + 스크린샷 중복 저장 수정**: 같은 기사를 스크린샷으로 캡처하고 동시에 URL로 공유하면(또는 반대 순서), OS 스크린샷 감지와 Share Extension이 서로의 존재를 모른 채 각각 카드를 만들어 동일 콘텐츠가 2장으로 저장되던 문제 수정. 저장 직전 최근 3분 이내 카드 중 제목이 사실상 같은 것이 있으면 건너뛰도록 양방향 검사 추가(`_isDuplicateOfRecentCapture`).
- **"핵심 포인트"에 UI 라벨이 섞이는 버그 수정**: Level 1(Apple Intelligence/EnhancedContentAnalyzer) 분석 결과를 Flutter로 전달하는 과정에서 네이티브가 반환하는 문장형 `insights` 필드가 중간에 누락되어, 검색용 짧은 키워드(`tags`)가 "핵심 포인트"로 잘못 재사용되고 있었음(예: "네이버앱", "앱", "사용법"). 네이티브 `insights` 필드를 제대로 전달하도록 수정하고, 모든 분석 레벨(0~4)에 짧은 UI 라벨을 걸러내는 안전망(`TextHeuristics.filterInsights`) 추가.

### Chore (죽은 코드 정리)
- **미사용 화면/모델 9개 삭제**: `settings_view`, `archive_view`, `note_detail_screen`, `thread_view`, `edit_card_screen`, `shelves_view`, `navigation_bar`, `memo_model`(+`.freezed.dart`/`.g.dart`) — 구 "Folio" 브랜드 시절 UI로, 현재 앱 어디에서도 import되지 않음을 전수 확인 후 제거 (약 3,600줄).
- **미사용 의존성 5개 제거**: `memo_model.dart`가 유일한 사용처였던 `freezed`, `freezed_annotation`, `json_annotation`, `json_serializable`, `build_runner`를 pubspec에서 삭제. codegen 스텝 자체가 불필요해짐.

### Security (경미한 하드닝)
- **Keychain 접근성 명시**: OpenAI API 키 저장 시 iOS `first_unlock_this_device`를 명시해 iCloud 키체인을 통해 다른 기기로 동기화되지 않도록 함(기존엔 기본값 사용).
- **URL 스킴 검증 추가**: `fetchURLMetadata`(AppDelegate.swift)가 http/https 스킴만 허용하도록 변경 — WKWebView가 `file://` 등 로컬 스킴을 로드할 가능성을 사전 차단(방어적 조치, 기존 호출 경로는 이미 http(s) 정규식으로 필터링되어 있었음).
- 전체 보안 점검 결과: SQL 인젝션·평문 HTTP·TLS 검증 우회·분석 SDK 데이터 유출·OCR/개인메모 원문 로깅 등 주요 항목은 모두 문제없음을 확인.

### Localization (스토어 등록 대비 다국어 점검)
- **하드코딩 문자열 제거**: `home_screen`, `settings_screen`, `folder_dialog`, `folder_management_view`, `library_list_view`에 남아있던 한국어 하드코딩 UI 문자열(스낵바, 다이얼로그, 시트 서브타이틀 등) 43개를 `AppLocalizations` 키로 전환. ko/en/ja ARB 129개 키 완전 동기화 확인(누락 0건).
- **iOS 네이티브 권한 문구 지역화**: `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription`/`NSPhotoLibraryAddUsageDescription`/`NSAppleIntelligenceUsageDescription`이 영어/한국어 혼용이었던 문제 수정. `en.lproj`/`ko.lproj`/`ja.lproj`의 `InfoPlist.strings`로 분리해 기기 언어에 맞는 시스템 권한 다이얼로그가 표시되도록 Xcode 프로젝트에 등록(`knownRegions`에 ko/ja 추가).

### Performance (이미지)
- **그리드/리스트 썸네일 디코드 크기 제한**: `library_list_view`(80×96), `shelves_view`(160 폭), 상세화면 히어로 이미지에 `cacheWidth`/`cacheHeight` 적용. 기존에는 원본 스크린샷 전체 해상도를 썸네일 크기로 그대로 디코드해 수천 장 스크롤 시 메모리 압박과 프레임 드랍이 발생하던 문제 완화.
- **저장 이미지 다운스케일**: iOS 스크린샷 캡처 시 `PHImageManagerMaximumSize`(기기 최대 해상도)를 리사이즈 없이 JPEG 0.8 압축만 해서 저장하던 로직을 수정. 저장/표시용 사본은 최대 1600px로 다운스케일하되, OCR 분석에는 원본 최대 해상도 이미지를 그대로 사용해 인식 정확도는 유지.

### Reviewed (Android 이식 가능성 검토)
- 스크린샷 자동 감지용 `MainActivity.kt` 스캐폴드는 존재하나 MethodChannel 이름이 iOS(`com.rememo.komjirak/vision`)와 불일치(`com.komjirak.stribe/vision`)하여 현재 비활성 상태. OCR(`analyzeImageWithBoxes`)·온디바이스 LLM(`llm` 채널)·Share Extension(URL 공유) 이식은 전무. Paddle-Lite Android 라이브러리도 아직 없음. 상세는 대화 내 리포트 참고 — 코드 변경 없음(검토만 수행).
- **분석 결과 품질 게이트 강화**: 시간·배터리·"로그인" 등 UI 노이즈성 제목, 15자 미만 요약, 제목을 반복하기만 하는 요약을 저품질로 판정해 다음 분석 레벨로 fallback하도록 개선 (`TextHeuristics.isLowQualityTitle` + `UnifiedAnalysisService._isUsableTitleSummary`).
- **Level 4 폴백 요약 개선**: "앞 문단 150자 자르기" 대신 문장 중요도(위치·길이·정보 밀도·완결성) 점수 기반 추출 요약 도입 (`TextHeuristics.summarizeByImportance`). 제목 후보도 UI 노이즈를 건너뛰고 선택.
- **OpenAI 프롬프트 개선**: 환각 방지 규칙(ACCURACY RULES) 명시, 요약이 제목을 반복하거나 메타 서술("이 스크린샷은~")로 시작하지 않도록 지침 추가, 예시 요약을 정보 밀도 높은 형태로 교체.

### UI (상세화면 간소화)
- **핵심 포인트 표시**: 저장만 되고 표시되지 않던 `keyInsights`를 AI 요약 카드 안에 불릿 리스트로 통합 표시.
- **원본 텍스트 접기**: OCR 원본을 기본 6줄 미리보기로 접고 "전체 보기/접기" 토글 제공. 복사 버튼 추가.
- **출처 도메인을 메타데이터 행으로 이동**: 날짜 옆에 클릭 가능한 도메인 표시, 원본 텍스트 하단의 중복 출처 링크 제거.
- **빈 개인 메모 간소화**: 빈 상태의 큰 카드 대신 컴팩트한 "메모 추가" 버튼으로 대체.
- **가짜 "AI 분석" 태그 pill 제거**: 실제 태그만 표시하고, 태그가 없으면 섹션 자체를 숨김.
- **번역 관련 하드코딩 한국어 문자열 현지화** (ko/en/ja) 및 중복 여백·데드 코드(`_shareCard`) 정리.

### Fixed
- **데이터 손상 버그**: `tags`/`keyInsights`를 쉼표 join으로 저장해 쉼표가 포함된 인사이트 문장("런치 세트 15,000원" 등)이 조각나던 문제 수정. JSON 배열로 저장하도록 변경하고 DB v9 마이그레이션 추가 (레거시 형식 호환 읽기 지원).
- **설정 화면 저장 용량 계산 오류**: 존재하지 않는 `rememo.db` 대신 실제 DB 파일(`folio.db`) 크기를 집계하도록 수정.
- **중복 AI 분석 제거**: 사진 촬영/공유 항목 처리 시 같은 콘텐츠를 두 번 분석(이중 API 호출)하던 경로 수정.

### Security & Privacy
- **API Key Keychain 이전**: OpenAI API 키를 SharedPreferences(평문)에서 `flutter_secure_storage`(Keychain)로 이전. 기존 키는 최초 실행 시 자동 마이그레이션 후 평문본 삭제.
- **OpenAI 분석 opt-in 전환**: PRD의 프라이버시 원칙에 맞춰 기본값을 비활성화로 변경하고, 설정에 "텍스트/이미지가 OpenAI로 전송됩니다" 고지 추가.

### Enhanced (AI 분석 품질)
- **Vision 이미지 분석**: OpenAI 활성 시 스크린샷/사진을 저해상도로 함께 전송해 OCR이 놓친 시각적 맥락(레이아웃, 이미지, 앱 종류)까지 반영. 설정에서 켜고 끌 수 있음.
- **분석 결과 완전 활용**: AI가 생성한 `category`/`tags`/`contentType`이 파이프라인에서 버려지던 문제 수정 — 이제 URL 저장 시 'Web' 하드코딩 대신 실제 분류가 저장되고, 문장형 keyInsights가 태그로 섞이지 않음.
- **429(rate limit) 처리 개선**: 세션 내 영구 차단 → 지수 백오프 쿨다운(1→2→4…최대 30분)으로 변경. 새 키 저장 시 오류 상태 자동 초기화.
- **모델 목록 갱신**: GPT-5 Mini/Nano 추가 (GPT-5 계열 파라미터 자동 처리).
- **프롬프트 개선**: OCR 재구성 지침, 이미지 참조 지침, 카테고리 선택 규칙 강화.

### Enhanced (검색)
- **SQLite FTS5 전문 검색 도입**: title/summary/ocrText/tags/personalNote 대상 인덱스 기반 검색. 미지원 기기는 LIKE 폴백. 검색창에 300ms 디바운스 적용.

### Architecture
- **Repository 계층 도입**: `MemoRepository`로 데이터 접근을 분리 (UI에서 DatabaseHelper 직접 접근 제거).
- **휴리스틱 통합**: home_screen/share_service에 중복돼 있던 카테고리/태그 추정 로직을 `TextHeuristics`로 일원화.
- **로깅 통일**: `print` 전면 제거 → `app_logger`(developer.log 기반)로 통일. OCR 블록별 반복 로그 제거.

### Performance
- DB 인덱스 추가 (`folderId`, `captureDate`, `sourceType`, `category`).
- 폴더별 카드 수 집계 N+1 쿼리 → 단일 GROUP BY 쿼리로 대체.

### Tests
- DB 마이그레이션/직렬화/FTS 검색/폴더 집계 통합 테스트 및 휴리스틱 단위 테스트 추가 (13개, `sqflite_common_ffi` 기반).

### Chore
- iOS 백업 파일(`*.backup`, `*.v3backup`) 삭제.

### Documentation
- Rewrote `README.md` based on `PRD.md` and recent `CHANGELOG.md` entries.
- Updated product messaging to **Rememo** and aligned feature/roadmap/privacy sections with current implementation.

## [1.0.0+27] - 2026-02-02

### Fixed
- **iOS Build Fix**: Resolved `PhaseScriptExecution` error caused by incorrect sorting logic in `home_screen.dart` (replaced `createdAt` with `captureDate`).
- **CocoaPods Configuration**: Fixed incorrect include paths in `Debug.xcconfig` and `Release.xcconfig` to resolve build warnings and potential linking errors.

## [1.0.0+25] - 2026-01-29

### Enhanced
- **Template-based Content Summaries**: Applied the content-type specific summary templates to screenshots and image captures as well, ensuring consistent quality across all input methods (Share Link, Screenshot, Camera).
- **Refined Content Type Detection**: Improved logic to distinguish between `Place` (Map/Restaurant), `Shopping`, `News`, and `SNS` more accurately using expanded keyword sets.
- **Unified Analysis Logic**: Merged analysis pathways in `OnDeviceLLM` so that enhanced title extraction and summarization benefit all user flows.

## [1.0.0+24] - 2026-01-29

### Enhanced
- **Advanced Content Analysis**: Improved AI analysis for shared URLs and screenshots.
  - **Smart Title Extraction**: Now intelligently extracts the real title from shared links (e.g., News headlines, SNS captions) instead of generic site names or author IDs.
  - **Content Type Detection**: Automatically categorizes content into `Place` (Map/Restaurant), `Shopping`, `News`, `Tech`, and `SNS` for better organization.
  - **Template-based Summaries**: Provides tailored summary formats for each content type (e.g., "Review/Location" for places, "Price/Product" for shopping, "Key Insights" for articles).
- **Improved Link Processing**: Better handling of shortened URLs (e.g., `naver.me`, `maps.app.goo.gl`) by analyzing the rendered screen content.

### Fixed
- Fixed an issue where generic titles (e.g., "Instagram", "Naver Map") were used for shared links.
- Refined UI noise filtering to prevent legitimate content from being removed during analysis.
