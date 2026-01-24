# Changelog
# Rememo - Version History

All notable changes to Rememo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.5.1] - Build 17 - 2026-01-24 (Current)

### AI & On-Device Translation (by Claude Code & AI Assistant)
- ✅ **Full On-Device Translation**: Google ML Kit 기반 온디바이스 번역 시스템 구축
- ✅ **Automatic Translation**: 스크린샷 분석 시 시스템 언어와 다른 경우 자동 번역 수행
- ✅ **Manual Translation**: 상세 화면에서 언제든 수동으로 번역 실행 가능
- ✅ **Translation Persistence**: 번역된 텍스트와 원본 텍스트를 함께 저장 (DB 스키마 v7 업데이트)
- ✅ **Translation UI**: 상세 화면에서 원본/번역 텍스트 토글 기능 추가

### UI/UX Improvements
- ✅ **Splash Screen Unification**: 다크/라이트 모드에서 동일한 디자인 적용 (아이콘 + 브랜드명 + 배경)
- ✅ **Design System**: 통합 디자인 시스템 가이드 문서 작성 (DESIGNSYSTEM.md)
- ✅ **Home Screen Filters**: 전체 | 즐겨찾기 | 폴더 (드롭다운) | 타입 (드롭다운) 필터 추가
- ✅ **Detail Screen Menus**: 플로팅 메뉴 및 더보기 메뉴 한국어화 (즐겨찾기 | 폴더로 이동 | 삭제)

### Settings Updates
- ✅ **AI Preferences 제거**: 사용하지 않는 AI 설정 메뉴 제거
- ✅ **저장 공간 정보**: Clear Cache 위에 현재 저장된 용량 및 파일 개수 표시
- ✅ **Info 섹션 추가**: 
  - Komjirak Studio 링크 (인앱 브라우저)
  - 동적 버전 정보 (pubspec.yaml 기반)

### New Features
- ✅ **즐겨찾기 토글**: 상세 화면에서 즐겨찾기 추가/제거 기능
- ✅ **필터링 시스템**: 홈 화면에서 즐겨찾기, 폴더, 타입별 필터링 지원

### Dependencies
- ✅ **package_info_plus**: 동적 버전 정보 표시를 위한 패키지 추가

---

## [0.5.0] - Build 16 - 2026-01-24

### 주요 기능 (Core Features)

#### 정보 수집 (Information Capture)
- ✅ **스크린샷 자동 감지**: Photo Library 변경 감지를 통한 자동 스크린샷 인식 및 저장
- ✅ **Share Extension**: Safari, Chrome 등 모든 앱에서 URL/웹페이지 공유하여 저장
  - URL 메타데이터 자동 추출 (제목, 설명, OG 이미지)
  - 웹페이지 본문 텍스트 추출
  - 선택된 텍스트 저장 지원
- ✅ **카메라 촬영**: 앱 내에서 직접 사진 촬영 또는 갤러리에서 선택

#### AI 분석 (AI Analysis)
- ✅ **Paddle OCR**: 한국어, 영어, 일본어 텍스트 인식 (온디바이스)
- ✅ **UI 노이즈 제거**: 버튼, 메뉴 등 불필요한 텍스트 자동 필터링
- ✅ **자동 분류**: Work, Design, Food, Shopping, Web 등 카테고리 자동 분류
- ✅ **태그 자동 추출**: 핵심 키워드 자동 추출
- ✅ **AI 요약 생성**: 온디바이스 LLM을 통한 콘텐츠 요약
- ✅ **다국어 지원**: OS 언어 기반 자동 번역 (한국어, 영어, 일본어)

#### 관리 기능 (Management)
- ✅ **폴더 시스템**: 사용자 정의 폴더 생성 및 메모 정리
- ✅ **즐겨찾기**: 중요한 메모 즐겨찾기 표시 및 필터링
- ✅ **검색**: 제목, 내용, 태그로 전체 텍스트 검색
- ✅ **개인 메모**: 각 메모 카드에 개인 메모 추가

#### UI/UX
- ✅ **다크모드**: 기본 다크 테마
- ✅ **그리드/리스트 뷰**: 뷰 모드 전환 가능
- ✅ **전체 화면 이미지 뷰어**: 이미지 확대/축소
- ✅ **플로팅 액션 메뉴**: 즐겨찾기, 폴더 이동, 편집, 삭제
- ✅ **원본 URL로 돌아가기**: 웹페이지 원본 링크 제공

#### 설정 (Settings)
- ✅ **버전 정보**: 동적 버전 표시 (CFBundleShortVersionString 기반)
- ✅ **Komjirak.Studio 링크**: 클릭 가능한 개발자 링크
- ✅ **라이선스 정보**: 오픈소스 라이선스 표시

### 기술 스택 (Tech Stack)
- **Flutter**: 3.10+
- **Paddle OCR**: iOS 네이티브 통합
- **SQLite**: 로컬 데이터베이스
- **온디바이스 AI**: 완전 무료, 오프라인 분석

### 버그 수정 (Bug Fixes)
- Fixed: 하드코딩된 버전 정보를 동적 표시로 변경
- Fixed: AI 설정 버튼 제거 (사용하지 않는 기능)
- Fixed: 즐겨찾기 필터링 로직 개선
- Fixed: Original Message 포맷팅 개선 (HTML 태그 및 공백 정리)
- Fixed: Share Extension에서 보안 페이지 제목 처리 개선

### 알려진 이슈 (Known Issues)
- iOS 14.0+ 만 지원 (Android 미지원)
- iCloud 동기화 미지원 (로컬 저장만 가능)

---

## [0.4.0] - Build 12-15 - 2026-01-23

### Added
- Share Extension 기본 구현
- URL 메타데이터 추출 기능
- 폴더 시스템 구현
- 즐겨찾기 기능 추가

### Changed
- UI 개선: 다크모드 최적화
- 검색 기능 개선

### Fixed
- OCR 정확도 개선
- 메모리 누수 수정

---

## [0.3.0] - Build 8-11 - 2026-01-20

### Added
- Paddle OCR 통합
- 온디바이스 AI 분석 (규칙 기반)
- 카테고리 자동 분류
- 태그 자동 추출

### Changed
- 데이터베이스 스키마 개선
- UI 레이아웃 개선

---

## [0.2.0] - Build 4-7 - 2026-01-15

### Added
- 스크린샷 자동 감지 기능
- 기본 OCR (Apple Vision Framework)
- SQLite 데이터베이스 구현
- 기본 검색 기능

### Changed
- 홈 화면 UI 개선

---

## [0.1.0] - Build 1-3 - 2026-01-10

### Added
- 초기 프로젝트 설정
- 기본 Flutter 앱 구조
- 카메라 촬영 기능
- 갤러리 이미지 선택

---

## 버전 관리 규칙 (Versioning Rules)

### 버전 번호 형식
- **Major.Minor.Patch+Build**
- 예: `0.5.0+16`

### 버전 업데이트 기준
- **Major (1.0.0)**: 주요 기능 추가 또는 아키텍처 변경
- **Minor (0.X.0)**: 새로운 기능 추가
- **Patch (0.0.X)**: 버그 수정 및 작은 개선
- **Build (+X)**: TestFlight 빌드 번호 (매 빌드마다 증가)

### TestFlight 빌드 업데이트
- 사용자가 명시적으로 TestFlight 빌드 업데이트를 요청할 때만 빌드 번호 증가
- 동일 버전 내에서 개발 중일 때는 빌드 번호 유지

---

## 다음 버전 계획 (Upcoming Versions)

### v0.6.0 (계획 중)
- [ ] Android 지원
- [ ] 태그 편집 기능
- [ ] 고급 검색 필터 (날짜, 카테고리)
- [ ] 데이터 내보내기 (JSON, PDF)

### v1.0.0 (향후)
- [ ] macOS 앱
- [ ] iCloud 동기화 (선택적)
- [ ] 위젯 지원
- [ ] Shortcuts 통합
- [ ] 관련 아이템 추천

---

*Last Updated: 2026-01-24*  
*Current Version: 0.5.1 (Build 17)*
