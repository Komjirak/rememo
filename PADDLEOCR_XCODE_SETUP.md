# Paddle-Lite Xcode 통합 가이드

빌드가 완료되었으니 이제 Xcode 프로젝트에 통합해야 합니다.

## 📋 현재 상태

- ✅ Paddle-Lite 빌드 완료
- ✅ 라이브러리 위치: `Paddle-Lite/build.ios.ios64.armv8/inference_lite_lib.ios64.armv8/`
- ⏳ Xcode 프로젝트 통합 필요

## 🔧 Xcode 통합 방법

`.a` 정적 라이브러리는 직접 드래그 앤 드롭으로 추가하지 않고, **Build Settings에서 경로를 설정**하는 방식이 더 적절합니다.

### 방법 1: 심볼릭 링크 생성 (권장)

프로젝트 내부에 심볼릭 링크를 만들어서 관리하기 쉽게 합니다:

```bash
cd /Users/sogsagim/folio/folio/ios/Runner
mkdir -p Frameworks/PaddleLite
ln -s ../../../Paddle-Lite/build.ios.ios64.armv8/inference_lite_lib.ios64.armv8/include Frameworks/PaddleLite/include
ln -s ../../../Paddle-Lite/build.ios.ios64.armv8/inference_lite_lib.ios64.armv8/lib Frameworks/PaddleLite/lib
```

### 방법 2: Xcode Build Settings 설정

1. **Xcode에서 `ios/Runner.xcworkspace` 열기**

2. **Project Navigator에서 `Runner` 프로젝트 선택** (파란 아이콘)

3. **TARGETS → Runner 선택**

4. **Build Settings 탭 클릭**

5. **검색창에 "Header Search Paths" 입력**
   - `Header Search Paths` 찾기
   - `+` 버튼 클릭
   - 다음 경로 추가:
     ```
     $(PROJECT_DIR)/../../Paddle-Lite/build.ios.ios64.armv8/inference_lite_lib.ios64.armv8/include
     ```
   - 또는 상대 경로:
     ```
     ../../Paddle-Lite/build.ios.ios64.armv8/inference_lite_lib.ios64.armv8/include
     ```

6. **검색창에 "Library Search Paths" 입력**
   - `Library Search Paths` 찾기
   - `+` 버튼 클릭
   - 다음 경로 추가:
     ```
     $(PROJECT_DIR)/../../Paddle-Lite/build.ios.ios64.armv8/inference_lite_lib.ios64.armv8/lib
     ```

7. **검색창에 "Other Linker Flags" 입력**
   - `Other Linker Flags` 찾기
   - `+` 버튼 클릭
   - 라이브러리 파일 이름 추가 (확인 필요):
     ```
     -lpaddle_light_api_shared
     ```
     또는
     ```
     -lpaddle_light_api
     ```
   - 실제 라이브러리 파일 이름을 확인해야 합니다

### 방법 3: 직접 파일 복사 (간단하지만 용량 증가)

```bash
cd /Users/sogsagim/folio/folio/ios/Runner
mkdir -p Frameworks/PaddleLite
cp -R ../Paddle-Lite/build.ios.ios64.armv8/inference_lite_lib.ios64.armv8/include Frameworks/PaddleLite/
cp -R ../Paddle-Lite/build.ios.ios64.armv8/inference_lite_lib.ios64.armv8/lib Frameworks/PaddleLite/
```

그 다음 Xcode에서:
- `Frameworks/PaddleLite/include` 폴더를 프로젝트에 추가 (드래그 앤 드롭)
- "Create groups" 선택
- Target: Runner 체크

## 🔍 라이브러리 파일 확인

먼저 어떤 라이브러리 파일이 있는지 확인하세요:

```bash
ls -la Paddle-Lite/build.ios.ios64.armv8/inference_lite_lib.ios64.armv8/lib/
```

출력 예시:
- `libpaddle_light_api_shared.a` → `-lpaddle_light_api_shared`
- `libpaddle_light_api.a` → `-lpaddle_light_api`
- `libpaddle_api_full_bundled.a` → `-lpaddle_api_full_bundled`

파일 이름에서 `lib` 접두사와 `.a` 확장자를 제거하고 `-l`을 앞에 붙이면 됩니다.

## ✅ 확인 방법

설정이 완료되면:

1. **Clean Build Folder**: `Shift + Cmd + K`
2. **Build**: `Cmd + B`
3. 빌드가 성공하면 통합 완료!

## ⚠️ 주의사항

- **"Not Applicable"이 뜨는 이유**: `.a` 파일이나 빌드 산출물을 직접 추가하려고 할 때 발생합니다
- **해결책**: Build Settings에서 경로만 설정하면 됩니다
- **파일 추가는 필요 없음**: 헤더 파일(`.h`)만 필요하면 추가할 수 있지만, 라이브러리는 경로만 설정하면 됩니다

## 📝 다음 단계

라이브러리 통합이 완료되면:
1. `Runner-Bridging-Header.h`에 Paddle-Lite 헤더 추가
2. `PaddleOCRHelper.swift`에서 실제 Paddle-Lite API 호출 코드 작성
