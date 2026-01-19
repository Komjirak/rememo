# Product Requirements Document (PRD)
# Stribe - AI-Powered Personal Knowledge Library

## 1. Executive Summary

### 1.1 Product Vision
**Stribe**는 사용자가 다양한 플랫폼에서 수집한 정보(스크린샷, URL)를 AI 기술을 통해 자동으로 분류하고 체계적으로 관리할 수 있는 "북마크 종합 선물 세트" 서비스입니다.

### 1.2 Problem Statement
현재 사용자들이 겪는 문제:
- **분산된 정보 저장**: Safari 북마크, Threads 저장, Instagram 저장 등 각 앱별로 정보가 흩어져 있음
- **맥락 손실**: URL만 저장 시 왜 저장했는지, 어떤 내용이었는지 기억하기 어려움
- **수동 정리의 번거로움**: 저장 후 분류/태그 작업이 번거로워 결국 방치됨
- **검색의 한계**: "예전에 봤던 그 디자인..."을 찾기 어려움

### 1.3 Solution
스크린샷 캡처 또는 URL 저장 시 AI가 자동으로:
1. 콘텐츠 분석 및 요약
2. 카테고리/태그 자동 분류
3. 검색 가능한 형태로 저장
4. 크로스플랫폼 동기화

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
- 팀과 공유할 레퍼런스를 체계적으로 관리하고 싶음
- Notion에 정리하지만 수동 작업이 너무 오래 걸림

---

## 3. Core Features

### 3.1 Phase 1: MVP (Must Have)

#### 3.1.1 스마트 캡처 (Smart Capture)
| Feature | Description | Platform |
|---------|-------------|----------|
| **스크린샷 자동 감지** | iOS에서 스크린샷 캡처 시 자동 감지 후 Stribe로 저장 제안 | iOS |
| **Share Extension** | 공유 메뉴를 통한 URL/이미지 저장 | iOS, Android |
| **웹 클리퍼** | 브라우저 확장 프로그램으로 웹페이지 저장 | Web |
| **수동 업로드** | 갤러리에서 직접 선택하여 업로드 | All |

#### 3.1.2 AI 분석 파이프라인
```
[캡처 이미지/URL]
    → OCR (텍스트 추출)
    → Content Analysis (콘텐츠 이해)
    → Auto Categorization (자동 분류)
    → Summary Generation (요약 생성)
    → Tag Extraction (태그 추출)
    → [Structured Memo Card]
```

**AI 기술 스택 고려사항:**
| 방식 | 장점 | 단점 |
|------|------|------|
| **Apple On-Device AI (Core ML)** | 프라이버시 보장, 오프라인 사용, 빠른 응답 | iOS 한정, 모델 크기 제한 |
| **Google ML Kit** | 크로스플랫폼, 오프라인 OCR | 고급 분석은 클라우드 필요 |
| **Cloud AI (OpenAI, Claude)** | 고품질 분석, 복잡한 추론 가능 | 네트워크 필요, 비용 발생, 프라이버시 |

**권장 하이브리드 접근:**
- 1차: On-Device (OCR, 기본 분류) - 즉시 처리
- 2차: Cloud AI (고급 요약, 관계 분석) - 백그라운드 처리

#### 3.1.3 메모 카드 (Memo Card)
저장된 각 아이템의 데이터 구조:

```json
{
  "id": "uuid",
  "created_at": "2024-01-15T10:30:00Z",
  "source": {
    "type": "screenshot | url | manual",
    "original_url": "https://...",
    "app_source": "Instagram | Twitter | Safari | ..."
  },
  "content": {
    "thumbnail": "image_path",
    "extracted_text": "OCR로 추출된 텍스트",
    "title": "AI가 생성한 제목",
    "summary": "2-3문장 요약"
  },
  "organization": {
    "category": "Design | Tech | News | Recipe | ...",
    "tags": ["UI", "모바일", "다크모드"],
    "user_notes": "사용자 메모"
  },
  "metadata": {
    "ai_confidence": 0.85,
    "language": "ko",
    "processed_at": "2024-01-15T10:30:05Z"
  }
}
```

#### 3.1.4 라이브러리 UI
- **Inbox**: 새로 저장된 아이템 (AI 분석 대기/완료)
- **Library**: 분류된 아이템 그리드/리스트 뷰
- **Collections**: 사용자 정의 컬렉션
- **Search**: 자연어 검색 ("지난달 본 앱 UI 디자인들")

### 3.2 Phase 2: Enhanced Features (Should Have)

| Feature | Description |
|---------|-------------|
| **스마트 검색** | 자연어로 저장된 정보 검색 |
| **관련 아이템 추천** | "이것과 비슷한 항목들" |
| **트렌드 인사이트** | 내가 자주 저장하는 주제 분석 |
| **웹 대시보드** | 큰 화면에서 라이브러리 관리 |
| **팀 공유** | 컬렉션을 팀원과 공유 |

### 3.3 Phase 3: Future Vision (Nice to Have)

| Feature | Description |
|---------|-------------|
| **AI 질의응답** | "내가 저장한 것 중 React 관련 내용 요약해줘" |
| **자동 아카이브** | 오래된/중복 아이템 정리 제안 |
| **외부 연동** | Notion, Obsidian 내보내기 |
| **위젯** | 홈 화면에서 최근 저장 아이템 확인 |

---

## 4. Technical Architecture

### 4.1 System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Apps                          │
├───────────────┬───────────────┬───────────────┬────────────┤
│   iOS App     │  Android App  │   Web App     │  Browser   │
│  (Flutter)    │   (Flutter)   │  (Flutter Web)│  Extension │
└───────┬───────┴───────┬───────┴───────┬───────┴─────┬──────┘
        │               │               │             │
        └───────────────┴───────┬───────┴─────────────┘
                                │
                    ┌───────────▼───────────┐
                    │      API Gateway      │
                    │    (Supabase/Firebase)│
                    └───────────┬───────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
┌───────▼───────┐      ┌───────▼───────┐      ┌───────▼───────┐
│   Auth        │      │   Database    │      │   Storage     │
│   Service     │      │   (PostgreSQL)│      │   (S3/GCS)    │
└───────────────┘      └───────────────┘      └───────────────┘
                                │
                    ┌───────────▼───────────┐
                    │    AI Processing      │
                    │  (Cloud Functions)    │
                    ├───────────────────────┤
                    │ - On-Device: OCR,     │
                    │   Basic Classification│
                    │ - Cloud: Advanced     │
                    │   Summary, Relations  │
                    └───────────────────────┘
```

### 4.2 iOS 스크린샷 자동 감지 구현

**Option A: Photo Library 변경 감지 (권장)**
```swift
// PHPhotoLibraryChangeObserver 활용
// 장점: App Store 승인 가능, 안정적
// 단점: 약간의 지연 (1-2초)
```

**Option B: Share Extension**
```swift
// 사용자가 공유 버튼 → Stribe 선택
// 장점: 명시적 사용자 의도, 다양한 앱 지원
// 단점: 수동 액션 필요
```

**Option C: Shortcuts 자동화**
```swift
// iOS Shortcuts에서 "스크린샷 촬영 시" 트리거
// 장점: 시스템 레벨 자동화
// 단점: 사용자가 설정해야 함
```

### 4.3 Tech Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Mobile** | Flutter 3.x | 크로스플랫폼, 빠른 개발 |
| **State Management** | Riverpod / Bloc | 확장성, 테스트 용이 |
| **Local DB** | SQLite (sqflite) | 오프라인 지원 |
| **Backend** | Supabase | Auth + DB + Storage 통합 |
| **AI - On Device** | Core ML / ML Kit | OCR, 기본 분류 |
| **AI - Cloud** | OpenAI GPT-4 / Claude | 고급 분석, 요약 |
| **Image Storage** | Supabase Storage | CDN 포함 |

---

## 5. User Flows

### 5.1 Core Flow: 스크린샷 저장

```
[사용자]                    [시스템]                      [AI]
   │                          │                           │
   │  스크린샷 캡처            │                           │
   │────────────────────────▶│                           │
   │                          │  새 이미지 감지             │
   │                          │──────────────────────────▶│
   │                          │                           │  OCR 처리
   │  ◀─ 알림: "Stribe에      │                           │  콘텐츠 분석
   │      저장하시겠습니까?"   │                           │  카테고리 추론
   │                          │                           │  태그 추출
   │  [저장] 탭               │                           │
   │────────────────────────▶│ ◀──────────────────────────│
   │                          │  분석 결과 반환            │
   │                          │                           │
   │  ◀─ 저장 완료 + 요약 표시 │                           │
   │     "디자인 > UI 참고자료" │                           │
```

### 5.2 검색 Flow

```
사용자 입력: "지난 주에 저장한 로그인 화면 디자인"
    ↓
[자연어 처리]
- 시간 필터: last_week
- 카테고리: Design
- 키워드: "로그인", "화면"
    ↓
[검색 실행]
- Full-text search on extracted_text
- Tag matching
- Vector similarity (Phase 2)
    ↓
[결과 표시]
- 관련도 순 정렬
- 썸네일 + 요약 미리보기
```

---

## 6. Design Principles

### 6.1 UX 원칙
1. **Zero Friction**: 저장은 한 번의 탭으로
2. **Instant Value**: 저장 즉시 AI 분석 결과 제공
3. **Serendipity**: 잊고 있던 저장 아이템 재발견 유도
4. **Privacy First**: 민감 데이터는 온디바이스 우선 처리

### 6.2 UI 스타일
- **Aesthetic**: 미니멀, 콘텐츠 중심, 프리미엄 느낌
- **Theme**: 다크모드 기본 지원
- **Typography**: Inter / Pretendard (한글)
- **Color**: 뉴트럴 베이스 + 카테고리별 액센트

---

## 7. Success Metrics

### 7.1 Activation
- 첫 주 내 10개 이상 아이템 저장
- Share Extension 설정 완료율

### 7.2 Engagement
- 주간 활성 저장 횟수
- 검색 사용 빈도
- 컬렉션 생성 수

### 7.3 Retention
- D7, D30 리텐션
- 저장 후 재조회율

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| AI 분류 정확도 낮음 | 사용자 신뢰도 하락 | 사용자 피드백 루프로 개선, 수동 수정 쉽게 |
| 저장 공간 부족 | 사용 중단 | 이미지 압축, 클라우드 저장소 옵션 |
| 프라이버시 우려 | 설치 거부 | 온디바이스 처리 강조, 투명한 데이터 정책 |
| App Store 리젝 | 출시 지연 | Photo Library 가이드라인 준수 |

---

## 9. Competitive Landscape

| Product | 강점 | 약점 | Stribe 차별점 |
|---------|------|------|---------------|
| **Raindrop.io** | 깔끔한 북마크 관리 | URL만 지원, AI 없음 | 스크린샷 + AI 분석 |
| **Notion Web Clipper** | Notion 연동 | 수동 정리 필요 | 자동 분류 |
| **Pinterest** | 비주얼 수집 | 외부 소스 한정 | 모든 앱 스크린샷 |
| **Apple Notes** | 시스템 통합 | 검색/분류 한계 | AI 기반 체계적 관리 |
| **Readwise** | 독서 하이라이트 | 텍스트 중심 | 이미지 기반 수집 |

---

## 10. Open Questions

1. **Monetization**: 프리미엄 기능 (무제한 저장, 고급 AI 분석)?
2. **데이터 소유권**: 사용자 데이터 완전 내보내기 지원?
3. **팀 기능**: B2C vs B2B 확장 고려?
4. **AI 모델 선택**: 비용 vs 품질 트레이드오프?

---

## 11. Appendix

### 11.1 카테고리 기본값 (AI 학습용)
```
- Design (UI, UX, Graphic, Brand)
- Tech (Programming, Tools, News)
- Product (Features, Analysis, Startup)
- Lifestyle (Recipe, Travel, Fashion)
- Knowledge (Article, Research, Quote)
- Reference (Inspiration, Wishlist, Tutorial)
```

### 11.2 참고 자료
- [Apple Human Interface Guidelines - Photos](https://developer.apple.com/design/human-interface-guidelines/photos)
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Supabase Docs](https://supabase.com/docs)

---

*Last Updated: 2025-01-19*
*Version: 1.0*
*Author: Stribe Team*
