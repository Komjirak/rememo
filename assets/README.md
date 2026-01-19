# App Icon Setup

## 아이콘 이미지 저장

제공하신 기하학적 AI 디자인 이미지를 다음 경로에 저장해주세요:
- `assets/icon.png`

이미지 요구사항:
- 크기: 1024x1024px (권장)
- 형식: PNG
- 배경: 투명 또는 다크 (#0a0a0b)

## 아이콘 생성 명령어

이미지 저장 후 다음 명령어를 실행하세요:

```bash
flutter pub run flutter_launcher_icons
```

이 명령어는 자동으로 다음 플랫폼의 아이콘을 생성합니다:
- iOS
- Android
- macOS

## 현재 설정

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
