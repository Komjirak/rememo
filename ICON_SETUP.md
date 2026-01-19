# 📱 앱 아이콘 설정 가이드

## ✅ 현재 상태

모든 설정이 완료되었습니다! 이제 아이콘 이미지만 저장하면 됩니다.

## 🎯 다음 단계

### 1단계: 이미지 저장

제공하신 기하학적 AI 디자인 이미지를 다음 경로에 저장해주세요:

```
/Users/eunae/Desktop/komjirak/Stribe/assets/icon.png
```

**이미지 요구사항:**
- ✅ 크기: 1024x1024px (권장) 또는 512x512px 이상
- ✅ 형식: PNG
- ✅ 배경: 투명 또는 다크 (#0a0a0b)

### 2단계: 아이콘 생성

터미널에서 다음 명령어를 실행하세요:

```bash
cd /Users/eunae/Desktop/komjirak/Stribe
flutter pub run flutter_launcher_icons
```

이 명령어는 자동으로 다음 플랫폼의 아이콘을 생성합니다:
- 📱 iOS (모든 크기)
- 🤖 Android (모든 밀도)
- 💻 macOS

### 3단계: 앱 재실행

```bash
flutter run -d macos
```

## 🎨 현재 설정

`pubspec.yaml`에 다음과 같이 설정되어 있습니다:

```yaml
flutter_launcher_icons:
  android: true
  ios: true  
  macos: true
  image_path: "assets/icon.png"
  adaptive_icon_background: "#0a0a0b"
  adaptive_icon_foreground: "assets/icon.png"
  remove_alpha_ios: false
```

## 💡 팁

- **Android**: 어댑티브 아이콘이 자동으로 생성됩니다
- **iOS**: 모든 크기의 앱 아이콘이 자동 생성됩니다
- **macOS**: macOS 앱 번들 아이콘이 생성됩니다

## ❓ 이미지 저장 방법

### 방법 1: 파인더 사용
1. 제공한 이미지 파일을 다운로드
2. Finder에서 `/Users/eunae/Desktop/komjirak/Stribe/assets/` 폴더 열기
3. 이미지 파일을 `icon.png`로 이름 변경 후 복사

### 방법 2: 드래그 앤 드롭
1. 이미지를 다운로드
2. Cursor/VSCode에서 `assets` 폴더 열기
3. 이미지를 드래그하여 폴더에 놓기
4. `icon.png`로 이름 변경

---

## 🚀 완료 후

아이콘이 성공적으로 적용되면:
- ✅ 홈 화면에서 새 아이콘 확인
- ✅ Dock/런처에서 새 아이콘 확인
- ✅ 앱 전환 시 새 아이콘 표시
