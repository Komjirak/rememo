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
1. OCR로 텍스트 추출 (한국어, 영어, 일본어 지원)
2. 콘텐츠 분석 및 요약 생성
3. 카테고리/태그 자동 분류
4. 검색 가능한 형태로 로컬 저장 (프라이버시 보호)

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

## 3. Core Features (v0.5 - Current Implementation)

### 3.1 정보 수집 (Information Capture)

#### 3.1.1 스크린샷 자동 감지
- iOS Photo Library 변경 감지를 통한 자동 스크린샷 인식
- 새 스크린샷 감지 시 자동으로 OCR 분석 및 저장
- 백그라운드에서 자동 처리

#### 3.1.2 Share Extension (URL/웹페이지)
- Safari, Chrome 등 모든 앱에서 공유 메뉴를 통한 저장
- URL 메타데이터 자동 추출 (제목, 설명, OG 이미지)
- 웹페이지 본문 텍스트 추출 및 AI 요약
- 선택된 텍스트 저장 지원

#### 3.1.3 카메라 촬영
- 앱 내에서 직접 사진 촬영하여 저장
- 촬영 즉시 OCR 분석 및 AI 처리
- 갤러리에서 기존 사진 선택하여 추가 가능

### 3.2 AI 분석 파이프라인 (On-Device)

```
[입력: 스크린샷/URL/사진]
    ↓
[Paddle OCR] - 한국어, 영어, 일본어 텍스트 인식
    ↓
[UI 노이즈 제거] - 버튼, 메뉴 등 불필요한 텍스트 필터링
    ↓
[온디바이스 분석]
    - 문서 구조 분석
    - 카테고리 자동 분류 (Work, Design, Food, Shopping, Web 등)
    - 태그 자동 추출
    - 제목 생성
    ↓
[AI 요약 생성] (선택적)
    - 온디바이스 LLM을 통한 요약 생성
    - 다국어 지원 (OS 언어 기반 자동 번역)
    ↓
[로컬 DB 저장] - SQLite
```

**기술 스택:**
- **Paddle OCR**: iOS 네이티브 통합, 오프라인 OCR
- **Apple Vision Framework**: 보조 OCR
- **온디바이스 분석**: 규칙 기반 + LLM (선택적)
- **완전 무료**: 인터넷 연결 불필요, API 비용 없음

### 3.3 메모 카드 데이터 구조

```json
{
  "id": "uuid",
  "title": "AI가 생성한 제목 또는 사용자 제목",
  "summary": "AI 생성 요약",
  "ocrText": "OCR로 추출된 전체 텍스트",
  "personalNote": "사용자 개인 메모",
  "imagePath": "/local/path/to/image.jpg",
  "sourceUrl": "https://...",
  "category": "Design | Work | Food | Shopping | Web | Inbox",
  "tags": ["UI", "모바일", "다크모드"],
  "isFavorite": false,
  "folderId": "folder-uuid",
  "createdAt": "2026-01-24T10:30:00Z",
  "updatedAt": "2026-01-24T10:30:00Z"
}
```

### 3.4 관리 기능

#### 3.4.1 폴더 시스템
- 사용자 정의 폴더 생성
- 메모를 폴더별로 정리
- 폴더 간 이동 가능

#### 3.4.2 즐겨찾기
- 중요한 메모를 즐겨찾기로 표시
- 홈 화면에서 즐겨찾기 필터링
- 상세 화면에서 즐겨찾기 토글

#### 3.4.3 검색
- 제목, 내용, 태그로 전체 텍스트 검색
- 실시간 검색 결과 표시
- OCR 텍스트 포함 검색

#### 3.4.4 개인 메모
- 각 메모 카드에 개인 메모 추가
- AI 요약과 별도로 사용자 생각 기록

### 3.5 UI/UX

#### 3.5.1 홈 화면
- 그리드/리스트 뷰 전환
- 카테고리별 필터링
- 즐겨찾기 필터
- 폴더별 보기
- 검색 바

#### 3.5.2 상세 화면
- 전체 화면 이미지 뷰어
- AI 요약 표시 (다국어 번역)
- OCR 원본 텍스트 표시
- 개인 메모 편집
- 원본 URL로 돌아가기
- 플로팅 액션 메뉴:
  - 즐겨찾기 토글
  - 폴더 이동
  - 편집
  - 삭제

#### 3.5.3 설정 화면
- 다크 모드 (기본)
- 버전 정보 (동적 표시)
- Komjirak.Studio 링크
- 라이선스 정보

---

## 4. Technical Architecture

### 4.1 System Overview

```
┌─────────────────────────────────────────────┐
│           iOS App (Flutter)                 │
├─────────────────────────────────────────────┤
│  Screens:                                   │
│  - HomeScreen (메인 라이브러리)              │
│  - DetailViewScreen (상세 보기)              │
│  - SettingsScreen (설정)                     │
│  - EditCardScreen (편집)                     │
└─────────────────┬───────────────────────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐   ┌────▼────┐   ┌───▼────┐
│ Share │   │ Native  │   │ On-    │
│ Ext.  │   │ Service │   │ Device │
│       │   │ (OCR)   │   │ LLM    │
└───┬───┘   └────┬────┘   └───┬────┘
    │            │            │
    └────────────┼────────────┘
                 │
         ┌───────▼────────┐
         │  SQLite DB     │
         │  (Local)       │
         └────────────────┘
```

### 4.2 iOS Native Integration

**AppDelegate.swift:**
- Method Channel 설정
- Photo Library 변경 감지
- Share Extension 데이터 수신

**PaddleOCRHelper.swift:**
- Paddle OCR 초기화
- 텍스트 인식 수행
- 다국어 지원 (한국어, 영어, 일본어)

**ShareViewController.swift:**
- Share Extension UI
- URL 메타데이터 추출
- App Group을 통한 데이터 전달

### 4.3 Tech Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Mobile** | Flutter 3.10+ | 크로스플랫폼 개발 |
| **Local DB** | SQLite (sqflite) | 오프라인 우선, 프라이버시 |
| **OCR** | Paddle OCR | 온디바이스, 다국어, 무료 |
| **AI Analysis** | 규칙 기반 + 온디바이스 LLM | 완전 무료, 오프라인 |
| **Storage** | Local File System | 프라이버시 보호 |
| **UI** | Material Design + Custom | 다크모드 중심 |

---

## 5. User Flows

### 5.1 스크린샷 저장 Flow

```
[사용자가 스크린샷 캡처]
    ↓
[Photo Library 변경 감지]
    ↓
[Paddle OCR 텍스트 추출]
    ↓
[AI 분석: 카테고리, 태그, 제목 생성]
    ↓
[SQLite에 자동 저장]
    ↓
[홈 화면에 새 카드 표시]
```

### 5.2 URL 저장 Flow (Share Extension)

```
[Safari/앱에서 공유 버튼 탭]
    ↓
[Rememo Share Extension 선택]
    ↓
[URL 메타데이터 추출 (제목, 설명, 이미지)]
    ↓
[웹페이지 본문 텍스트 추출]
    ↓
[AI 요약 생성]
    ↓
[App Group에 저장]
    ↓
[메인 앱 실행 시 자동 가져오기]
    ↓
[홈 화면에 표시]
```

### 5.3 검색 Flow

```
[검색어 입력: "디자인"]
    ↓
[SQLite Full-Text Search]
    - 제목 검색
    - OCR 텍스트 검색
    - 태그 검색
    ↓
[결과 표시 (그리드/리스트)]
```

---

## 6. Design Principles

### 6.1 UX 원칙
1. **Zero Friction**: 스크린샷은 자동 저장, URL은 한 번의 공유로
2. **Privacy First**: 모든 데이터는 로컬 저장, 외부 전송 없음
3. **Offline First**: 인터넷 연결 없이도 모든 기능 사용 가능
4. **Instant Value**: 저장 즉시 AI 분석 결과 제공

### 6.2 UI 스타일
- **Theme**: 다크모드 기본
- **Typography**: Google Fonts (Inter/Roboto)
- **Color**: 뉴트럴 다크 베이스 + 카테고리별 액센트
- **Layout**: 그리드/리스트 전환 가능

---

## 7. Current Version

**Version**: 0.5.0  
**Build**: 16  
**Platform**: iOS 14.0+  
**Release**: TestFlight (Internal Testing)

### 7.1 Implemented Features
- ✅ 스크린샷 자동 감지 및 저장
- ✅ Share Extension (URL/웹페이지)
- ✅ 카메라 촬영 및 갤러리 선택
- ✅ Paddle OCR (한국어, 영어, 일본어)
- ✅ 온디바이스 AI 분석 (카테고리, 태그, 제목)
- ✅ AI 요약 생성 (다국어)
- ✅ 폴더 시스템
- ✅ 즐겨찾기
- ✅ 검색 기능
- ✅ 개인 메모
- ✅ 다크모드 UI
- ✅ 그리드/리스트 뷰

---

## 8. Future Roadmap

### 8.1 v0.6 (계획 중)
- [ ] Android 지원
- [ ] 태그 편집 기능
- [ ] 고급 검색 필터 (날짜, 카테고리)
- [ ] 데이터 내보내기 (JSON, PDF)

### 8.2 v1.0 (향후)
- [ ] macOS 앱
- [ ] iCloud 동기화 (선택적)
- [ ] 위젯 지원
- [ ] Shortcuts 통합
- [ ] 관련 아이템 추천

### 8.3 v1.1 (향후)
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
| **Evernote** | 노트 기능 | 무거움, 유료 | 가볍고 무료 |

---

## 10. Privacy & Security

### 10.1 Data Privacy
- **로컬 우선**: 모든 데이터는 기기 내 SQLite에 저장
- **외부 전송 없음**: 인터넷 연결 불필요
- **온디바이스 AI**: OCR 및 분석 모두 기기 내에서 처리
- **사용자 제어**: 언제든 데이터 삭제 가능

### 10.2 Permissions
- **Photo Library**: 스크린샷 감지 및 이미지 저장
- **Camera**: 사진 촬영 (선택적)
- **App Group**: Share Extension 데이터 공유

---

## 11. Appendix

### 11.1 카테고리 기본값
```
- Inbox (기본)
- Work (업무)
- Design (디자인)
- Food (음식)
- Shopping (쇼핑)
- Web (웹)
- Personal (개인)
```

### 11.2 참고 자료
- [Paddle OCR](https://github.com/PaddlePaddle/PaddleOCR)
- [Flutter Documentation](https://flutter.dev/)
- [Apple Share Extension Guide](https://developer.apple.com/documentation/uikit/share_extension)

---

*Last Updated: 2026-01-24*  
*Version: 0.5.0 (Build 16)*  
*Author: Komjirak.Studio*
