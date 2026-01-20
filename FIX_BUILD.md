# 🔧 빌드 오류 수정 가이드

## 🚨 문제
`OnDeviceLLM.swift` 파일이 Xcode 프로젝트에 포함되지 않음

## ✅ 해결 방법

### 방법 1: Xcode에서 파일 추가 (추천)

```bash
# 1. Xcode 열기
open ios/Runner.xcworkspace
```

**Xcode에서:**
1. **Project Navigator** (좌측 패널)
2. `Runner` 폴더에서 우클릭
3. **"Add Files to Runner"** 선택
4. `ios/Runner/OnDeviceLLM.swift` 파일 선택
5. ✅ **"Copy items if needed"** 체크
6. ✅ **"Add to targets: Runner"** 체크
7. **Add** 버튼 클릭

그 다음 터미널에서:
```bash
flutter clean
flutter build ios --no-codesign
```

### 방법 2: 자동 스크립트 (간편)

터미널에서 실행:
```bash
# Xcode가 열린 상태에서
# File → Add Files to "Runner" → OnDeviceLLM.swift 선택

# 또는 새 터미널에서
cd ios
pod install
cd ..
flutter build ios --no-codesign
```

## 📝 추가된 파일 확인

빌드 전 다음 파일들이 있어야 함:
- ✅ `ios/Runner/OnDeviceLLM.swift`
- ✅ `ios/Runner/AppDelegate.swift`
- ✅ `ios/Runner/PaddleOCRHelper.swift`

## 🎯 빌드 성공 후 로그

```
🤖 OnDeviceLLM 초기화 (NLP 기반 분석)
```

---

**다음 명령어로 현재 상태 확인:**
```bash
ls -la ios/Runner/*.swift
flutter doctor -v
```
