# Rememo

AI 기반 개인 지식 라이브러리 앱입니다. 스크린샷, URL, 사진을 저장하면 온디바이스 OCR/분석으로 제목, 요약, 카테고리, 태그를 자동 생성해 다시 찾기 쉬운 형태로 정리합니다.

## Product Vision

Rememo는 "기억하고 싶은 모든 순간을 AI가 자동으로 정리해주는" 경험을 목표로 합니다.

- 분산된 정보(스크린샷/URL/메모)를 한 곳에 통합
- 저장 즉시 맥락(제목, 요약, 태그) 생성
- 로컬 우선 저장으로 프라이버시 보호
- 오프라인에서도 핵심 기능 사용 가능

자세한 배경은 PRD 문서를 참고하세요: [PRD.md](PRD.md)

## Core Features

### 1) 정보 수집
- 스크린샷 자동 감지 및 백그라운드 처리
- Share Extension 기반 URL/웹페이지 저장
- 앱 내 카메라 촬영 및 갤러리 이미지 추가

### 2) 온디바이스 AI 분석 파이프라인
- Paddle OCR로 다국어 텍스트 인식 (한국어/영어/일본어)
- UI 노이즈 텍스트 필터링
- 문서 구조 기반 제목/카테고리/태그 자동 생성
- 선택적으로 요약 생성

### 3) 라이브러리 관리
- 폴더 정리 및 폴더 이동
- 즐겨찾기
- 제목/태그/OCR 텍스트 통합 검색
- 카드별 개인 메모

### 4) 사용성
- 홈 화면 그리드/리스트 전환
- 카테고리/폴더/즐겨찾기 필터
- 상세 화면에서 OCR 원문, 요약, 원본 URL 확인

## What's New (from CHANGELOG)

### 1.0.0+27 (2026-02-02)
- iOS 빌드 이슈(`PhaseScriptExecution`) 수정
- CocoaPods include path 정리로 빌드 경고/링킹 리스크 개선

### 1.0.0+25 (2026-01-29)
- 템플릿 기반 요약을 스크린샷/이미지 플로우까지 확장
- 콘텐츠 타입 감지 정확도 개선 (Place/Shopping/News/SNS)
- 분석 로직 통합으로 입력 방식 간 품질 일관성 강화

### 1.0.0+24 (2026-01-29)
- 공유 링크의 실제 제목 추출 정확도 향상
- 링크/화면 기반 콘텐츠 타입 자동 분류 강화
- UI 노이즈 제거 로직 개선

전체 이력: [CHANGELOG.md](CHANGELOG.md)

## Tech Stack

- Flutter (Dart)
- SQLite (`sqflite`)
- Paddle OCR (iOS 네이티브 통합)
- Apple Vision Framework (보조 OCR)
- 온디바이스 분석 (규칙 기반 + 선택적 LLM)

## Project Structure

```text
lib/
  models/        # 메모 카드/폴더 모델
  screens/       # 홈/설정/편집 등 화면
  services/      # DB, 네이티브 브리지, 분석 로직
  widgets/       # 재사용 UI 컴포넌트
  theme/         # 앱 테마

ios/
  Runner/        # AppDelegate, 네이티브 분석/OCR 연동
  ShareExtension/# 공유 확장
```

## Getting Started

### Prerequisites
- Flutter SDK
- Xcode (iOS 개발 환경)
- CocoaPods

### Setup

```bash
git clone https://github.com/Komjirak/rememo.git
cd rememo
flutter pub get
cd ios && pod install && cd ..
```

### Run

```bash
flutter run
```

### Build (iOS Release)

```bash
flutter build ios --release
```

## Permissions

- Photo Library: 스크린샷 감지 및 이미지 저장
- Camera: 사진 촬영
- App Group: Share Extension 데이터 전달

## Platform Status

- iOS: 주요 기능 구현 및 운영
- Android/macOS/Windows/Linux/Web: 구조는 존재하며 기능 확장 진행 중

## Roadmap

PRD 기준 주요 계획:

- v0.6: Android 지원, 태그 편집, 고급 검색 필터, 데이터 내보내기
- v1.0: macOS 앱, 선택적 동기화, 위젯, Shortcuts 통합
- v1.1: 팀 공유, 외부 툴 연동, AI 질의응답

## Privacy & Security

- 로컬 우선 저장 (SQLite + 파일 시스템)
- 분석 처리 온디바이스 중심
- 사용자 데이터 외부 전송 최소화 원칙

## Documentation

- [PRD.md](PRD.md)
- [CHANGELOG.md](CHANGELOG.md)
- [README_PADDLEOCR.md](README_PADDLEOCR.md)
- [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)
- [TESTFLIGHT_CHECKLIST.md](TESTFLIGHT_CHECKLIST.md)

## Contributing

이슈와 PR을 환영합니다.

```bash
git checkout -b feature/your-feature
git commit -m "feat: your message"
git push origin feature/your-feature
```

## License

This project is licensed under the MIT License.
