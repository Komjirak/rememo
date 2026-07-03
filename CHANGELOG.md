## [Unreleased]

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
