# Folio - AI-Powered Screenshot Memory Manager

스크린샷을 지능적으로 분석하고 관리하는 Flutter 앱입니다.

## ✨ 주요 기능

### 🤖 AI 기반 스크린샷 분석
- **Paddle OCR**: 한국어, 영어, 일본어 텍스트 인식
- **온디바이스 분석**: 인터넷 연결 없이 빠른 분석 (무료)
- **자동 카테고리 분류**: Work, Design, Food, Shopping 등
- **스마트 태그 추출**: 핵심 키워드 자동 추출
- **UI 노이즈 제거**: 버튼, 메뉴 등 불필요한 텍스트 필터링

### 📸 자동 스크린샷 감지
- 새로운 스크린샷이 생성되면 자동으로 감지
- OCR 텍스트 추출 및 AI 분석
- 백그라운드에서 자동 저장

### 🗂️ 강력한 관리 기능
- **폴더 시스템**: 스크린샷을 폴더별로 정리
- **검색**: 제목, 내용, 태그로 빠른 검색
- **즐겨찾기**: 중요한 스크린샷 표시
- **Personal Note**: 개인 메모 추가

### 🎨 아름다운 UI/UX
- 다크 모드 디자인
- 직관적인 인터페이스
- 부드러운 애니메이션
- 전체 화면 이미지 뷰어

## 🚀 시작하기

### 1. Flutter 설치
```bash
# Flutter SDK 설치 확인
flutter doctor
```

### 2. 프로젝트 클론
```bash
git clone https://github.com/Komjirak/folio.git
cd folio
```

### 3. 패키지 설치
```bash
flutter pub get
```

### 4. AI 분석 선택 (옵션)

#### 옵션 A: 규칙 기반 분석 (기본, 추천)
- ✅ 추가 설정 불필요
- ✅ 즉시 사용 가능 (<0.1초)
- ✅ 앱 크기 작음
- ✅ 완전 무료

**현재 활성화됨!** 바로 사용 가능합니다.

#### 옵션 B: Gemma 2B LLM (온디바이스, 고급)
더 정확한 AI 분석을 원하시면:

```bash
# 모델 다운로드 (~2.5GB)
./scripts/download_gemma_model.sh

# Xcode에서 모델 추가
open ios/Runner.xcworkspace
# File → Add Files → gemma-2b-it.mlpackage
```

**장점**: 완전 무료, 오프라인, 프라이버시 보호  
**단점**: 앱 크기 +2.5GB

자세한 내용: [GEMMA_INSTALLATION.md](GEMMA_INSTALLATION.md)

#### 옵션 C: Gemini API (클라우드)
클라우드 AI를 원하시면:
1. [Google AI Studio](https://aistudio.google.com/app/apikey)에서 API 키 발급
2. `lib/services/gemini_service.dart` 생성
3. API 키 설정

자세한 내용: [GEMINI_API_SETUP.md](GEMINI_API_SETUP.md)

### 5. iOS 실행
```bash
cd ios
pod install
cd ..
flutter run
```

### 6. 권한 설정
앱 실행 시 다음 권한을 허용해주세요:
- 📷 **사진 라이브러리 접근**: 스크린샷 가져오기
- 📸 **카메라 접근**: 사진 촬영 (선택사항)

## 📦 기술 스택

### Frontend
- **Flutter 3.10+**: 크로스 플랫폼 개발
- **Dart**: 프로그래밍 언어

### AI & ML
- **Paddle OCR**: 온디바이스 텍스트 인식 (iOS)
- **온디바이스 분석**: 규칙 기반 UI 노이즈 제거 및 구조 분석
- **Apple Vision Framework**: iOS 네이티브 OCR
- **Google Gemini 2.0 Flash** (선택사항): AI 분석 및 요약 생성

### 데이터베이스
- **SQLite**: 로컬 데이터 저장
- **sqflite**: Flutter SQLite 플러그인

### 주요 패키지
```yaml
dependencies:
  image_picker: ^1.0.7           # 이미지 선택
  permission_handler: ^11.1.0    # 권한 관리
  path_provider: ^2.1.2          # 파일 경로
  sqflite: ^2.3.0                # 데이터베이스
  url_launcher: ^6.2.4           # URL 열기
  
  # AI (선택사항)
  # google_generative_ai: ^0.4.6  # Gemini AI
```

## 🏗️ 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── models/                      # 데이터 모델
│   ├── memo_card.dart          # 메모 카드 모델
│   └── folder.dart             # 폴더 모델
├── screens/                     # 화면
│   └── home_screen.dart        # 메인 홈 화면
├── widgets/                     # UI 위젯
│   ├── detail_view_screen.dart # 상세 화면
│   ├── library_list_view.dart  # 리스트 뷰
│   └── ...
├── services/                    # 서비스
│   ├── ondevice_llm_service.dart # 온디바이스 분석
│   ├── gemini_service.dart     # Gemini AI (선택)
│   ├── database_helper.dart    # 데이터베이스 헬퍼
│   └── native_service.dart     # iOS 네이티브 브리지
└── theme/                       # 테마
    └── app_theme.dart          # 앱 테마 정의

ios/
├── Runner/
│   ├── AppDelegate.swift       # iOS 네이티브 코드
│   ├── PaddleOCRHelper.swift   # Paddle OCR 헬퍼
│   ├── PaddleOCRWrapper.mm     # Paddle OCR C++ 래퍼
│   └── PaddleOCR/              # OCR 모델 및 사전
└── libpaddle_api_light_bundled.a  # Paddle-Lite 라이브러리
```

## 📱 지원 플랫폼

- ✅ iOS 14.0+
- ⏳ Android (개발 중)
- ⏳ macOS (개발 중)

## 🔧 개발 가이드

### 디버그 모드 실행
```bash
flutter run --debug
```

### 릴리즈 빌드
```bash
flutter build ios --release
```

### Xcode에서 실행
```bash
open ios/Runner.xcworkspace
```

## 📚 추가 문서

### AI 분석
- [Gemma 2B 설치 가이드](GEMMA_INSTALLATION.md) - 온디바이스 LLM (추천)
- [온디바이스 LLM 가이드](ONDEVICE_LLM_GUIDE.md) - 아키텍처 및 기술 상세
- [Gemini API 설정 가이드](GEMINI_API_SETUP.md) - 클라우드 AI (선택)

### OCR 및 설정
- [Paddle OCR 설정 가이드](PADDLEOCR_SETUP.md)
- [Xcode 설정 가이드](PADDLEOCR_XCODE_SETUP.md)
- [PRD (Product Requirements Document)](PRD.md)

## 🎯 로드맵

### v1.0 (현재)
- [x] Paddle OCR 통합
- [x] 온디바이스 분석 (규칙 기반)
- [x] Gemma 2B LLM 지원 (선택)
- [x] 자동 스크린샷 감지
- [x] 폴더 시스템
- [x] 검색 기능

### v1.1 (계획 중)
- [ ] Bounding Box 기반 문서 구조 분석
- [ ] Android 지원
- [ ] 클라우드 동기화
- [ ] 공유 기능
- [ ] 다국어 지원 (영어, 일본어)
- [ ] 위젯 지원

### v1.2 (향후)
- [ ] macOS 앱
- [ ] 태그 편집 기능
- [ ] 고급 검색 필터
- [ ] 데이터 내보내기/가져오기

## 🤝 기여하기

이슈 및 Pull Request를 환영합니다!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

This project is licensed under the MIT License.

## 👨‍💻 개발자

**Komjirak Team**

- GitHub: [@Komjirak](https://github.com/Komjirak)

## 🙏 감사의 말

- [PaddlePaddle](https://github.com/PaddlePaddle/PaddleOCR) - 강력한 OCR 엔진
- [Google Gemini](https://ai.google.dev/) - AI 분석 기능
- [Flutter](https://flutter.dev/) - 크로스 플랫폼 프레임워크

---

⭐ 이 프로젝트가 마음에 드셨다면 Star를 눌러주세요!
