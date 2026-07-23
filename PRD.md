# Product Requirements Document (PRD)
# Rememo - AI-Powered Memory Capture & Management

## 1. Executive Summary

### 1.1 Product Vision
**Rememo**는 스크린샷, URL, 사진 등 다양한 형태의 정보를 AI 기술로 자동 분석하여 체계적으로 관리할 수 있는 개인 지식 라이브러리입니다. "기억하고 싶은 모든 순간을 AI가 자동으로 정리해주는" 서비스입니다.

### 1.2 Problem Statement
현재 사용자들이 겪는 문제:
- **분산된 정보 저장**: 스크린샷은 사진첩에, URL은 브라우저 북마크에, 메모는 노트앱에 흩어져 있음
- **맥락 손실**: 나중에 다시 보면 왜 저장했는지, 어떤 내용이었는지 기억하기 어려움
- **수동 정리의 번거로움**: 저장 후 분류/태그 작업이 번거로워 결국 방치됨
- **검색의 한계**: "예전에 봤던 그 내용..."을 찾기 어려움

### 1.3 Solution
스크린샷, URL, 사진 캡처 시 AI가 자동으로:
1. OCR로 텍스트 추출 (한국어, 영어, 일본어, 중국어 간체/번체 지원)
2. 콘텐츠 분석 및 요약·핵심 포인트 생성
3. 카테고리/태그 자동 분류
4. 검색 가능한 형태로 로컬 저장 (기본은 완전 오프라인, 고품질 분석은 opt-in)

---

## 2. Target Users

### 2.1 Primary Persona
**"정보 수집가" 유나 (28세, 프로덕트 디자이너)**
- 매일 인스타그램, 트위터, 뉴스레터에서 영감을 수집
- 스크린샷으로 저장하지만 나중에 찾지 못함
- "나중에 정리해야지"가 쌓여 수천 장의 스크린샷 보유

### 2.2 Secondary Persona
**"리서처" 민수 (32세, 스타트업 PM)**
- 경쟁사 분석, 시장 조사 자료를 자주 수집
- 웹 기사와 스크린샷을 함께 관리하고 싶음
- 빠른 검색과 재발견이 중요

---

## 3. Core Features (Current Implementation)

### 3.1 정보 수집 (Information Capture)

#### 3.1.1 스크린샷 자동 감지
- iOS Photo Library 변경 감지(`PHPhotoLibraryChangeObserver`)를 통한 자동 스크린샷 인식
- 새 스크린샷 감지 시 자동으로 OCR 분석 및 저장, 백그라운드 처리
- 같은 콘텐츠를 스크린샷과 URL 공유로 동시에 캡처한 경우, 최근 저장된 카드와 제목이 겹치면 중복 저장을 건너뜀

#### 3.1.2 Share Extension (URL/웹페이지)
- Safari, Naver 등 모든 앱에서 공유 메뉴를 통한 저장
- URL 메타데이터 자동 추출 (제목, 설명, OG 이미지) — 숨겨진 `WKWebView`로 페이지를 로드해 JS로 메타태그 파싱
- 웹페이지 본문 텍스트 추출 및 AI 요약
- App Group(`group.com.rememo.komjirak`)을 통해 메인 앱과 데이터 공유

#### 3.1.3 카메라 촬영 / 갤러리 선택
- 앱 내에서 직접 사진 촬영하여 저장, 촬영 즉시 OCR 분석 및 AI 처리
- 갤러리에서 기존 사진 선택하여 추가 가능
- 클립보드 URL 붙여넣기로도 저장 가능

### 3.2 AI 분석 파이프라인 (5단계 Fallback)

```
[입력: 스크린샷/URL/사진]
    ↓
[Vision Framework OCR] - 텍스트 + Bounding Box + 레이아웃/세일리언시 인식
    ↓
[UI 노이즈 필터링] - 상태바, 버튼, 네비게이션 등 불필요한 텍스트 제거
    ↓
[UnifiedAnalysisService: 5단계 Fallback]
    Level 0: OpenAI GPT API        (최고 품질, opt-in, 인터넷 필요)
    Level 1: Apple Foundation Models (iOS 26+ 온디바이스 생성형 AI)
             / NaturalLanguage 휴리스틱 (구형 기기 대체)
    Level 2: 규칙 기반 요약 (문장 중요도 점수화)
    Level 3: DocumentParserService (도메인별 템플릿: 쇼핑/맛집/SNS/뉴스 등)
    Level 4: 최소 Fallback (항상 성공, 상단 텍스트 기반)
    ↓
[품질 게이트] - 저품질 제목/요약(UI 라벨, 제목-요약 중복 등) 감지 시 다음 레벨로 진행
    ↓
[자동 번역] (선택) - 온디바이스 ML Kit, OS 언어와 다르면 자동 번역
    ↓
[로컬 DB 저장] - SQLite (FTS5 전문 검색 인덱스 포함)
```

**단계별 특성:**
- Level 0(OpenAI)은 **기본값 비활성화**(opt-in) — 설정에서 API 키를 등록해야 활성화되며, 켜면 캡처 텍스트(및 선택 시 저해상도 이미지)가 OpenAI 서버로 전송됨을 명시적으로 고지
- Level 1은 iOS 26+ Apple Intelligence 지원 기기에서 실제 온디바이스 LLM(`LanguageModelSession`)을 사용하고, 미지원 기기는 `NaturalLanguage` 프레임워크 기반 규칙형 분석으로 자동 대체
- Level 2~4는 순수 규칙 기반으로 항상 빠르게 성공하도록 설계됨(모델 다운로드 불필요)
- 모든 온디바이스 단계에 타임아웃 보호가 있어 응답 지연 시 자동으로 다음 레벨로 넘어감
- OCR·요약 생성은 완전 오프라인/무료로 동작하며, Level 0만 네트워크와 API 비용이 필요

**기술 스택:**
- **Apple Vision Framework**: 텍스트 인식(`VNRecognizeTextRequest`), 레이아웃(`VNDetectRectanglesRequest`), 세일리언시(`VNGenerateAttentionBasedSaliencyImageRequest`) — 다국어(한/영/중간/중번/일) 자동 감지
- **Apple Foundation Models**: iOS 26+ 온디바이스 생성형 AI (`@Generable` 구조화 출력)
- **OpenAI GPT API**: 선택적 고품질 분석 (gpt-4o-mini 기본, gpt-4.1/gpt-5 계열 선택 가능)
- **Google ML Kit**: 언어 감지 및 온디바이스 번역
- **완전 무료 경로 보장**: OpenAI를 켜지 않으면 인터넷 연결 없이 모든 기능 사용 가능

> Paddle-Lite/PaddleOCR 통합은 초기 계획 단계에서 남은 스크립트/리소스만 존재하며, 실제 OCR은 전량 Apple Vision Framework로 처리된다.

### 3.3 메모 카드 데이터 구조

```json
{
  "id": "uuid",
  "title": "AI가 생성한 제목 또는 사용자 제목",
  "summary": "AI 생성 요약",
  "keyInsights": ["핵심 포인트 문장 1", "핵심 포인트 문장 2"],
  "ocrText": "OCR로 추출된 전체 텍스트",
  "personalNote": "사용자 개인 메모",
  "imagePath": "/local/path/to/image.jpg",
  "sourceUrl": "https://...",
  "sourceType": "screenshot | url | photo",
  "contentType": "news | article | blog | restaurant | place | product | education | social | general",
  "category": "Design | Tech | Food | Shopping | Work | Inspiration | Web | Personal | Inbox",
  "tags": ["UI", "모바일", "다크모드"],
  "isFavorite": false,
  "folderId": "folder-uuid",
  "wasTranslated": false,
  "originalTitle": "번역 전 원문 제목",
  "originalSummary": "번역 전 원문 요약",
  "captureDate": "2026-07-21 22:12"
}
```

`tags`/`keyInsights`는 JSON 배열로 저장되며(구버전 쉼표 구분 형식도 하위 호환 읽기 지원), 쉼표가 포함된 문장형 인사이트("런치 세트 15,000원" 등)도 안전하게 보존된다.

### 3.4 관리 기능

#### 3.4.1 폴더 시스템
- 사용자 정의 폴더 생성(이름 + 8가지 색상 중 선택)
- 메모를 폴더별로 정리, 폴더 간 이동
- 폴더별 항목 수 집계(단일 GROUP BY 쿼리)

#### 3.4.2 즐겨찾기
- 중요한 메모를 즐겨찾기로 표시, 홈 화면에서 즐겨찾기 필터링

#### 3.4.3 검색
- **SQLite FTS5 전문 검색** — title/summary/ocrText/tags/personalNote 대상, 인덱스 기반
- FTS5 미지원 기기는 LIKE 검색으로 자동 폴백
- 검색창에 300ms 디바운스 적용

#### 3.4.4 개인 메모
- 각 메모 카드에 개인 메모 추가, AI 요약과 별도로 사용자 생각 기록
- 1초 자동 저장(디바운스)

#### 3.4.5 번역
- 시스템 언어와 다른 언어로 캡처된 콘텐츠는 자동/수동 번역 지원(온디바이스 ML Kit)
- 원문 보기/번역 보기 토글로 원문 보존

### 3.5 UI/UX

#### 3.5.1 홈 화면
- 리스트 뷰 (썸네일 + 제목 + 요약 미리보기)
- 필터: 즐겨찾기 토글, 폴더 드롭다운, 타입 드롭다운(스크린샷/URL/사진)
- 검색 바 (FTS5 기반 실시간 검색)
- 하단 `+` 버튼으로 새 메모 시트(스크린샷 가져오기/사진 촬영/URL 붙여넣기) 진입

#### 3.5.2 상세 화면 (REMEMO INSIGHT)
- 제목 · 메타데이터(날짜, 출처 도메인) · 태그
- 전체 화면 이미지 뷰어(핀치 줌)
- AI 요약 + **핵심 포인트**(불릿 리스트로 요약 카드 안에 통합 표시)
- 원본 텍스트(OCR) — 6줄 미리보기 후 "전체 보기/접기" 토글, 복사 버튼
- 개인 메모 편집 (비어있을 땐 컴팩트한 "메모 추가" 버튼)
- 번역 토글 (원본 보기 / 번역 보기)
- 플로팅 액션 메뉴: 즐겨찾기, 폴더 이동, 삭제

#### 3.5.3 설정 화면
- **화면 설정**: 다크/라이트/시스템 테마
- **관리**: 폴더 관리
- **데이터**: 캐시 삭제, 사용된 저장 공간 표시
- **AI 분석 (OpenAI)**: 활성화 토글, API 키 등록/삭제/테스트, 모델 선택(gpt-4o-mini 외 5종), Vision(이미지 분석) 토글, 프라이버시 고지
- **정보**: 버전 정보(동적 표시), Komjirak Studio 링크, 라이선스

#### 3.5.4 다국어 지원
- 한국어/영어/일본어 3개 언어 완전 지원(UI 문자열, iOS 시스템 권한 다이얼로그 모두 로케일별 분리)

---

## 4. Technical Architecture

### 4.1 System Overview

```
┌───────────────────────────────────────────────────┐
│                iOS App (Flutter)                   │
├───────────────────────────────────────────────────┤
│  Screens:                                          │
│  - HomeScreen (메인 라이브러리 + 캡처 진입점)        │
│  - DetailViewScreen (상세 보기/편집)                 │
│  - SettingsScreen (설정)                            │
├───────────────────────────────────────────────────┤
│  Services:                                          │
│  - UnifiedAnalysisService (5단계 분석 오케스트레이션)│
│  - OpenAIService / OnDeviceLLMService / DocumentParserService
│  - ShareService / NativeService / TranslationService │
│  - MemoRepository → DatabaseHelper (SQLite/FTS5)     │
└─────────────────┬───────────────────────────────────┘
                  │ MethodChannel / EventChannel
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐   ┌────▼────────┐   ┌▼─────────────┐
│ Share │   │ AppDelegate  │   │ ContentAnalyzer│
│ Ext.  │   │ (Vision OCR, │   │ Adapter        │
│(URL)  │   │ Photo 감지)  │   │ (Foundation    │
│       │   │              │   │  Models 라우팅)│
└───┬───┘   └────┬─────────┘   └───┬────────────┘
    │            │                 │
    └────────────┴─────────────────┘
                 │
         ┌───────▼────────┐
         │  SQLite DB v9  │
         │  (Local, FTS5) │
         └────────────────┘
```

### 4.2 iOS Native Integration

**AppDelegate.swift** (`com.rememo.komjirak/*` 채널)
- MethodChannel: `vision`(OCR/스크린샷 조회), `llm`(분석), `share`(공유 항목), event channel `screenshot_detection`
- Photo Library 변경 감지, `WKWebView` 기반 URL 메타데이터 추출
- 스크린샷 저장 시 원본은 OCR/분석용으로만 사용하고, 저장/표시용 사본은 1600px로 다운스케일

**PaddleOCRHelper.swift**
- Vision Framework 기반 텍스트/레이아웃/세일리언시 인식
- Enhanced 분석 경로도 2048px로 다운스케일 후 처리(속도 최적화)

**ContentAnalyzerAdapter.swift**
- 기기 환경에 따라 RealFoundationModelsAnalyzer(iOS 26+) → FoundationModelsAnalyzer(NLP 휴리스틱) → EnhancedContentAnalyzer(규칙 기반) 순으로 자동 라우팅
- Foundation Models 응답에 12초 타임아웃 적용

**ShareViewController.swift** (Share Extension)
- URL/이미지/텍스트/PropertyList 첨부 타입별 처리(`UTType` 검증)
- App Group을 통한 데이터 전달

### 4.3 Tech Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Mobile** | Flutter 3.10+ / Dart 3.10+ | 크로스플랫폼 개발(현재 iOS만 완성) |
| **Local DB** | SQLite (sqflite) + FTS5 | 오프라인 우선, 전문 검색 |
| **OCR** | Apple Vision Framework | 온디바이스, 다국어, 무료 |
| **On-device AI** | Apple Foundation Models (iOS 26+) + NaturalLanguage 휴리스틱 + 규칙 기반 | 완전 무료, 오프라인, 항상 성공하는 폴백 체인 |
| **Cloud AI (opt-in)** | OpenAI GPT API | 최고 품질, 명시적 동의 시에만 사용 |
| **번역** | Google ML Kit (Translation, Language ID) | 온디바이스, 무료 |
| **보안 저장소** | flutter_secure_storage (iOS Keychain, `first_unlock_this_device`) | API 키 등 민감정보 보호 |
| **Storage** | Local File System | 프라이버시 보호 |
| **UI** | Material Design + Custom(Glassmorphism) | 다크모드 중심, Google Fonts |

### 4.4 플랫폼 지원 현황

- **iOS**: 프로덕션 수준(TestFlight 배포 중, iOS 15.5+)
- **Android**: 스크린샷 감지 스캐폴드(`MainActivity.kt`)만 존재하며 **현재 작동하지 않음** — MethodChannel 이름이 iOS와 불일치하고, OCR·온디바이스 분석·Share Extension(Intent 공유)이 전혀 이식되어 있지 않음. 실질적 출시를 위해서는 별도 프로젝트 규모의 작업이 필요.

---

## 5. User Flows

### 5.1 스크린샷 저장 Flow

```
[사용자가 스크린샷 캡처]
    ↓
[Photo Library 변경 감지 (screenshot subtype만 필터링)]
    ↓
[Vision Framework OCR 텍스트/레이아웃 추출]
    ↓
[UnifiedAnalysisService 5단계 분석: 카테고리, 태그, 제목, 요약, 핵심 포인트]
    ↓
[최근 카드와 제목 중복 검사 (URL 공유와 겹치면 스킵)]
    ↓
[SQLite에 자동 저장 + FTS 인덱싱]
    ↓
[홈 화면에 새 카드 표시]
```

### 5.2 URL 저장 Flow (Share Extension)

```
[Safari/앱에서 공유 버튼 탭]
    ↓
[Rememo Share Extension 선택]
    ↓
[URL 메타데이터 추출 (WKWebView + JS 파싱)]
    ↓
[웹페이지 본문 텍스트 추출]
    ↓
[App Group에 저장]
    ↓
[메인 앱 실행 시 자동 가져오기 → UnifiedAnalysisService 분석]
    ↓
[최근 스크린샷 카드와 제목 중복 검사]
    ↓
[홈 화면에 표시]
```

### 5.3 검색 Flow

```
[검색어 입력]
    ↓ (300ms 디바운스)
[SQLite FTS5 MATCH 쿼리 — 실패 시 LIKE 폴백]
    - 제목 / 요약 / OCR 텍스트 / 태그 / 개인 메모
    ↓
[결과 리스트 표시]
```

---

## 6. Design Principles

### 6.1 UX 원칙
1. **Zero Friction**: 스크린샷은 자동 저장, URL은 한 번의 공유로
2. **Privacy First**: 기본값은 완전 로컬 처리, 클라우드 AI는 명시적 opt-in 시에만
3. **Offline First**: OpenAI를 켜지 않으면 인터넷 연결 없이도 모든 기능 사용 가능
4. **Instant Value**: 저장 즉시 AI 분석 결과 제공, 항상 성공하는 폴백 체인으로 빈 결과 방지
5. **Graceful Degradation**: 고품질 분석이 실패/지연되어도 타임아웃 후 빠르게 다음 레벨로 대체

### 6.2 UI 스타일
- **Theme**: 다크모드 기본, 라이트/시스템 테마 지원
- **Typography**: Google Fonts
- **Color**: 뉴트럴 다크 베이스 + 카테고리별 액센트(틸 포인트 컬러)
- **Layout**: 리스트 뷰 + 글래스모피즘 상세 화면

---

## 7. Current Version

**Version**: 1.0.0
**Build**: 36
**Platform**: iOS 15.5+
**Release**: TestFlight (Internal Testing)

### 7.1 Implemented Features
- ✅ 스크린샷 자동 감지 및 저장 (중복 방지 로직 포함)
- ✅ Share Extension (URL/웹페이지)
- ✅ 카메라 촬영 및 갤러리 선택
- ✅ Apple Vision Framework OCR (한/영/중간/중번/일)
- ✅ 5단계 AI 분석 파이프라인 (OpenAI opt-in → Foundation Models → 규칙 기반)
- ✅ 핵심 포인트(keyInsights) 표시
- ✅ 온디바이스 자동 번역
- ✅ 폴더 시스템
- ✅ 즐겨찾기
- ✅ FTS5 전문 검색
- ✅ 개인 메모
- ✅ 다크/라이트/시스템 테마
- ✅ 한국어/영어/일본어 완전 다국어화
- ✅ API 키 Keychain 보안 저장

### 7.2 Known Limitations
- ⚠️ Android는 기능적으로 작동하지 않음 (스캐폴드만 존재)
- ⚠️ 데이터 내보내기/백업 기능 없음
- ⚠️ 그리드 뷰 없음 (리스트 뷰만 지원)

---

## 8. Future Roadmap

### 8.1 단기
- [ ] 태그 편집 기능
- [ ] 고급 검색 필터 (날짜, 카테고리)
- [ ] 데이터 내보내기 (JSON, PDF)
- [ ] 그리드 뷰 옵션

### 8.2 중기
- [ ] Android 지원 (OCR/온디바이스 분석/Share Intent 전체 이식 필요)
- [ ] iCloud 동기화 (선택적)
- [ ] 위젯 지원
- [ ] Shortcuts 통합
- [ ] 관련 아이템 추천

### 8.3 장기
- [ ] macOS 앱
- [ ] 팀 공유 기능
- [ ] Notion/Obsidian 연동
- [ ] 자동 아카이브
- [ ] AI 질의응답

---

## 9. Competitive Landscape

| Product | 강점 | 약점 | Rememo 차별점 |
|---------|------|------|---------------|
| **Apple Notes** | 시스템 통합 | AI 없음, 검색 한계 | AI 자동 분류, OCR |
| **Notion** | 강력한 관리 | 수동 정리 필요 | 자동 분석 |
| **Raindrop.io** | 북마크 관리 | URL만 지원 | 스크린샷 + URL |
| **Pinterest** | 비주얼 수집 | 외부 소스 한정 | 모든 앱 지원 |
| **Evernote** | 노트 기능 | 무거움, 유료 | 가볍고, 기본 기능 무료 |

---

## 10. Privacy & Security

### 10.1 Data Privacy
- **로컬 우선**: 모든 데이터는 기기 내 SQLite에 저장
- **클라우드 AI는 opt-in**: OpenAI 분석은 기본 비활성화. 활성화 시에도 텍스트(+선택 시 저해상도 이미지)만 전송되며, 언제든 끌 수 있음
- **API 키 보안 저장**: iOS Keychain(`first_unlock_this_device` — iCloud 동기화 차단), 로그에 평문 노출되지 않음
- **원문 데이터 비로깅**: OCR 텍스트/개인 메모는 어떤 로그에도 평문 기록되지 않음
- **사용자 제어**: 언제든 데이터 삭제 가능

### 10.2 Permissions
- **Photo Library**: 스크린샷 감지 및 이미지 저장 — 로케일별 권한 설명 문구 제공(en/ko/ja)
- **Camera**: 사진 촬영 (선택적)
- **App Group**: Share Extension 데이터 공유

### 10.3 네트워크 보안
- ATS(App Transport Security) 기본값 유지, 평문 HTTP 예외 없음
- URL 메타데이터 조회 시 http/https 스킴만 허용(로컬 파일 스킴 차단)
- TLS 인증서 검증 우회 코드 없음
- 분석/크래시리포팅 SDK 미탑재 (외부로 나가는 데이터는 opt-in OpenAI 호출뿐)

---

## 11. Appendix

### 11.1 카테고리 기본값
```
- Inbox (기본)
- Work (업무)
- Design (디자인)
- Tech (기술)
- Food (음식)
- Shopping (쇼핑)
- Inspiration (영감)
- Web (웹)
- Personal (개인)
```

### 11.2 콘텐츠 타입
```
news, article, blog, restaurant, place, product, education, social, general
```

### 11.3 참고 자료
- [Apple Vision Framework](https://developer.apple.com/documentation/vision)
- [Apple Foundation Models](https://developer.apple.com/documentation/foundationmodels)
- [Flutter Documentation](https://flutter.dev/)
- [Apple Share Extension Guide](https://developer.apple.com/documentation/uikit/share_extension)
- [OpenAI API Reference](https://platform.openai.com/docs)

---

*Last Updated: 2026-07-21*
*Version: 1.0.0 (Build 36)*
*Author: Komjirak.Studio*
