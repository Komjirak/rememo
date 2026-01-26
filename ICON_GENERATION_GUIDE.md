# 🎨 앱 아이콘 생성 가이드

스플래시 화면 중앙의 디자인을 앱 아이콘으로 사용하기 위한 가이드입니다.

## 📋 사전 준비

1. Flutter 환경이 설정되어 있어야 합니다.
2. `assets/` 폴더가 존재해야 합니다.

## 🚀 아이콘 생성 방법

### 방법 1: Flutter로 직접 실행 (권장)

터미널에서 다음 명령어를 실행하세요:

```bash
cd /Users/eunae/Desktop/komjirak/rememo
flutter run -d macos tool/generate_icon.dart
```

또는 더 간단하게:

```bash
cd /Users/eunae/Desktop/komjirak/rememo
flutter run --target=tool/generate_icon.dart -d macos
```

### 방법 2: Flutter 앱으로 실행

임시로 Flutter 앱을 만들어서 실행할 수도 있습니다. 하지만 방법 1이 더 간단합니다.

## 📱 플랫폼별 아이콘 생성

아이콘 이미지가 생성되면 (`assets/icon.png`), 다음 명령어로 모든 플랫폼의 아이콘을 생성하세요:

```bash
flutter pub run flutter_launcher_icons
```

이 명령어는 자동으로 다음 플랫폼의 아이콘을 생성합니다:
- 📱 iOS (모든 크기)
- 🤖 Android (모든 밀도)
- 💻 macOS

## ✅ 확인 사항

아이콘이 성공적으로 생성되면:
- `assets/icon.png` 파일이 1024x1024 크기로 생성됩니다
- 스플래시 화면과 동일한 디자인이 적용됩니다:
  - 검은색 배경
  - 22.5% border-radius (iOS 스타일)
  - 4개 모서리 브래킷 (accent-teal 색상)
  - 중앙 auto_awesome 아이콘 (별/스파클 모양)
  - 중앙 원형 테두리

## 🔄 아이콘 업데이트 후

1. 앱을 완전히 종료하고 재시작하세요
2. 홈 화면에서 새 아이콘 확인
3. Dock/런처에서 새 아이콘 확인
4. 앱 전환 시 새 아이콘 표시

## ⚠️ 문제 해결

### "dart:ui is not available" 오류
- `flutter run`을 사용해야 합니다 (단순 `dart run`이 아님)

### 아이콘이 변경되지 않음
- 앱을 완전히 삭제하고 재설치하세요
- iOS 시뮬레이터의 경우 앱 삭제 후 재빌드

### 아이콘 생성 스크립트 실행 실패
- Flutter 환경이 제대로 설정되어 있는지 확인: `flutter doctor`
- `flutter pub get` 실행 후 다시 시도
