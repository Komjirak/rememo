# Paddle-Lite iOS 프레임워크 통합 완전 가이드

이 문서는 Paddle-Lite iOS 프레임워크를 Xcode 프로젝트에 추가하는 **단계별 상세 가이드**입니다.

## 📋 준비물 체크리스트

- [ ] Paddle-Lite iOS 프레임워크 파일 (`.framework` 또는 `.xcframework`)
- [ ] Xcode 프로젝트 열기 (`ios/Runner.xcworkspace`)
- [ ] 관리자 권한 (필요시)

---

## 🔽 Step 1: Paddle-Lite 프레임워크 다운로드

### 방법 1: GitHub Releases에서 다운로드 (권장)

1. **Paddle-Lite GitHub Releases 페이지 열기**
   ```
   https://github.com/PaddlePaddle/Paddle-Lite/releases
   ```

2. **최신 버전 선택**
   - 최신 릴리즈를 찾습니다 (예: v2.14.0)
   - Assets 섹션 확장

3. **iOS용 프레임워크 다운로드**
   - `PaddleLite.framework.zip` 또는
   - `PaddleLite.xcframework.zip` 다운로드
   - 압축 해제

### 방법 2: 직접 빌드 (고급)

```bash
git clone https://github.com/PaddlePaddle/Paddle-Lite.git
cd Paddle-Lite
# iOS 빌드 가이드 참고
# https://paddle-lite.readthedocs.io/en/latest/user_guides/ios_x86.html
```

---

## 📁 Step 2: 프로젝트 구조 준비

프레임워크를 넣을 위치를 만듭니다:

```bash
cd ios/Runner
mkdir -p Frameworks
```

다운로드한 프레임워크를 `Frameworks` 폴더에 복사:

```bash
# 예시
cp /path/to/downloaded/PaddleLite.framework Frameworks/
# 또는
cp /path/to/downloaded/PaddleLite.xcframework Frameworks/
```

---

## 🎯 Step 3: Xcode에서 프레임워크 추가

### 3.1 Xcode 프로젝트 열기

**중요:** `.xcodeproj`가 아니라 **`.xcworkspace`**를 열어야 합니다!

```bash
open ios/Runner.xcworkspace
```

또는 Finder에서 `ios/Runner.xcworkspace` 더블클릭

### 3.2 프레임워크를 프로젝트에 추가

**방법 A: 드래그 앤 드롭 (가장 간단)**

1. **Finder에서 프레임워크 파일 찾기**
   - 다운로드한 `PaddleLite.framework` 또는 `PaddleLite.xcframework` 파일

2. **Xcode Project Navigator에서**
   - 왼쪽 사이드바에서 `Runner` 프로젝트 (최상위 파란 아이콘) 우클릭
   - 또는 `Frameworks` 폴더가 있다면 그 안에 드래그

3. **드래그 앤 드롭**
   - Finder에서 프레임워크 파일을 Xcode의 Project Navigator로 드래그
   - 팝업 창이 나타남:
     - ✅ **"Copy items if needed"** 체크 (프로젝트 내부로 복사)
     - ✅ **"Add to targets: Runner"** 체크
     - **"Create groups"** 선택 (폴더 구조 유지)
     - **Add** 클릭

**방법 B: Add Files 메뉴 사용**

1. Xcode 메뉴: **File → Add Files to "Runner"...**
2. 다운로드한 프레임워크 파일 선택
3. 옵션:
   - ✅ **"Copy items if needed"** 체크
   - ✅ **"Add to targets: Runner"** 체크
4. **Add** 클릭

---

## ⚙️ Step 4: Linked Frameworks and Libraries 설정

이 단계가 **가장 중요**합니다!

### 4.1 Target 설정 열기

1. Project Navigator에서 **최상위 `Runner` 프로젝트** 클릭 (파란 아이콘)
2. 중앙 패널에서 **TARGETS** 섹션의 **`Runner`** 선택
3. 상단 탭에서 **"General"** 탭 클릭

### 4.2 Frameworks, Libraries, and Embedded Content 추가

1. **"Frameworks, Libraries, and Embedded Content"** 섹션 찾기
   - General 탭을 스크롤하면 보입니다

2. **`+` 버튼 클릭**

3. **프레임워크 선택**
   - 목록에 `PaddleLite.framework`가 보이면 선택
   - 없으면 **"Add Other..." → "Add Files..."** 선택
   - 프로젝트에 추가한 프레임워크 파일 선택

4. **Embed 설정 (중요!)**
   - 추가된 `PaddleLite.framework` 옆의 드롭다운 메뉴 클릭
   - **"Embed & Sign"** 선택
     - 이렇게 하면 앱 번들에 프레임워크가 포함됩니다
     - 런타임에 프레임워크를 찾을 수 있습니다

### 4.3 확인

추가된 프레임워크가 다음과 같이 보여야 합니다:

```
Frameworks, Libraries, and Embedded Content
├─ PaddleLite.framework
│  └─ Embed & Sign  ← 이렇게 설정되어 있어야 함
```

---

## 🔧 Step 5: Build Settings 확인

### 5.1 Framework Search Paths 설정

1. **Build Settings 탭으로 이동**
   - TARGETS → Runner → **Build Settings** 탭

2. **검색창에 "Framework Search Paths" 입력**

3. **경로 추가**
   - `$(PROJECT_DIR)/Frameworks` 또는
   - `$(SRCROOT)/Runner/Frameworks`
   - `+` 버튼으로 추가

### 5.2 Library Search Paths 설정

1. 검색창에 **"Library Search Paths"** 입력
2. 동일한 경로 추가:
   - `$(PROJECT_DIR)/Frameworks`

---

## 📦 Step 6: Build Phases 확인

### 6.1 Link Binary With Libraries

1. **Build Phases 탭으로 이동**
   - TARGETS → Runner → **Build Phases** 탭

2. **"Link Binary With Libraries"** 섹션 확장
   - `PaddleLite.framework`가 목록에 있는지 확인
   - 없으면 `+` 버튼으로 추가

### 6.2 Copy Bundle Resources

1. **"Copy Bundle Resources"** 섹션 확장
2. 다음 파일들이 포함되어 있는지 확인:
   - `ppocr_keys_v1.txt` (딕셔너리 파일)
   - 모델 파일들 (`.nb` 파일들)
3. 없으면 `+` 버튼으로 추가

---

## 🔗 Step 7: Bridging Header 설정 (C++ 사용 시)

Paddle-Lite는 C++ API를 사용하므로, Swift에서 사용하려면 브리징이 필요합니다.

### 7.1 Bridging Header 파일 확인

`ios/Runner/Runner-Bridging-Header.h` 파일이 있는지 확인

없으면 생성:
1. File → New → File
2. **Header File** 선택
3. 이름: `Runner-Bridging-Header.h`
4. Target: Runner 체크

### 7.2 Bridging Header에 헤더 추가

`Runner-Bridging-Header.h` 파일에 추가:

```objc
//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <PaddleLite/PaddleLite.h>
// 또는 실제 헤더 파일 경로에 맞게 수정
```

### 7.3 Build Settings에서 Bridging Header 경로 설정

1. Build Settings 탭
2. 검색창에 **"Objective-C Bridging Header"** 입력
3. 경로 설정:
   ```
   Runner/Runner-Bridging-Header.h
   ```

---

## ✅ Step 8: 빌드 및 테스트

### 8.1 Clean Build

1. **Product → Clean Build Folder** (Shift + Cmd + K)
2. **Product → Build** (Cmd + B)

### 8.2 오류 확인

빌드 오류가 발생하면:

**오류: "No such module 'PaddleLite'"**
- Framework Search Paths 확인
- 프레임워크가 올바른 위치에 있는지 확인

**오류: "dyld: Library not loaded"**
- Embed 설정이 "Embed & Sign"인지 확인
- 프레임워크가 Copy Bundle Resources에 포함되어 있는지 확인

**오류: "Undefined symbols"**
- Link Binary With Libraries에 프레임워크가 있는지 확인
- Bridging Header 설정 확인

---

## 📝 Step 9: Swift 코드에서 사용

프레임워크가 제대로 추가되면, Swift 코드에서 사용할 수 있습니다:

```swift
import PaddleLite
// 또는 C++ 래퍼를 통해 사용
```

---

## 🎉 완료!

이제 Paddle-Lite 프레임워크가 프로젝트에 통합되었습니다.

다음 단계:
1. `PaddleOCRHelper.swift`에서 실제 Paddle-Lite API 호출 코드 추가
2. 모델 파일 로드 및 초기화
3. OCR 추론 실행

---

## 📚 참고 자료

- [Paddle-Lite 공식 문서](https://paddle-lite.readthedocs.io/)
- [Paddle-Lite iOS 가이드](https://paddle-lite.readthedocs.io/en/latest/user_guides/ios_x86.html)
- [Paddle-Lite GitHub](https://github.com/PaddlePaddle/Paddle-Lite)

---

## 🆘 문제 해결

### 프레임워크를 찾을 수 없음

1. Framework Search Paths 확인
2. 프레임워크 파일이 실제로 프로젝트 폴더에 있는지 확인
3. "Copy items if needed"가 체크되어 있는지 확인

### 런타임 오류

1. Embed 설정이 "Embed & Sign"인지 확인
2. 프레임워크가 앱 번들에 포함되어 있는지 확인:
   ```bash
   # 앱 번들 확인
   unzip -l YourApp.ipa | grep PaddleLite
   ```

### 빌드 오류

1. Clean Build Folder 실행
2. Derived Data 삭제:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. CocoaPods 재설치:
   ```bash
   cd ios
   pod deintegrate
   pod install
   ```
