# PaddleOCR iOS 통합 가이드

이 문서는 iOS 앱에 PaddleOCR을 통합하여 OCR 정확도를 향상시키는 방법을 설명합니다.

## 🚀 빠른 시작 (Quick Start)

### 1단계: 딕셔너리 파일 다운로드

```bash
# 프로젝트 루트에서 실행
./scripts/download_paddleocr_resources.sh
```

이 스크립트가 자동으로 `ppocr_keys_v1.txt` 파일을 다운로드합니다.

### 2단계: Paddle-Lite 프레임워크 추가

**상세 가이드는 `PADDLEOCR_FRAMEWORK_GUIDE.md` 참고**

간단 요약:
1. [Paddle-Lite Releases](https://github.com/PaddlePaddle/Paddle-Lite/releases)에서 iOS 프레임워크 다운로드
2. Xcode에서 `Runner.xcworkspace` 열기
3. 프레임워크 파일을 프로젝트에 드래그 앤 드롭
4. General → Frameworks, Libraries, and Embedded Content → "Embed & Sign" 설정

### 3단계: 모델 파일 추가 (선택사항)

PaddleOCR 모델 파일을 `ios/Runner/PaddleOCR/models/` 폴더에 추가하면 자동으로 감지됩니다.

---

## 현재 상태

현재 코드는 향상된 Vision Framework를 사용하며, PaddleOCR 모델이 추가되면 자동으로 전환되도록 설계되었습니다.

## PaddleOCR 모델 다운로드 및 설정

### 1. 딕셔너리 파일 자동 다운로드 (간편 방법)

프로젝트 루트에서 다음 스크립트를 실행하세요:

```bash
# 딕셔너리 파일 자동 다운로드
./scripts/download_paddleocr_resources.sh
```

이 스크립트는 다음 파일들을 자동으로 다운로드합니다:
- `ppocr_keys_v1.txt` (중국어 문자 사전, 기본)
- `korean_dict.txt` (한국어 사전, 선택)
- `en_dict.txt` (영어 사전, 선택)

### 2. 수동 다운로드 방법

#### ppocr_keys_v1.txt 다운로드

**방법 1: 직접 다운로드**
```bash
# 터미널에서 실행
cd ios/Runner
mkdir -p PaddleOCR/dict
curl -L -o PaddleOCR/dict/ppocr_keys_v1.txt \
  https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/ppocr_keys_v1.txt
```

**방법 2: GitHub에서 직접**
1. 브라우저에서 열기: https://github.com/PaddlePaddle/PaddleOCR/blob/main/ppocr/utils/ppocr_keys_v1.txt
2. Raw 버튼 클릭
3. 파일 저장 (이름: `ppocr_keys_v1.txt`)
4. `ios/Runner/PaddleOCR/dict/` 폴더에 복사

**다른 언어 딕셔너리:**
- 한국어: https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/dict/korean_dict.txt
- 영어: https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/dict/en_dict.txt
- 일본어: https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/dict/japan_dict.txt

### 3. 모델 파일 다운로드

PaddleOCR의 모바일용 경량 모델을 다운로드합니다:

**PP-OCRv3 모바일 모델 (권장):**
```bash
# Detection 모델
curl -L -o ios/Runner/PaddleOCR/models/ch_PP-OCRv3_det_infer.nb \
  https://paddleocr.bj.bcebos.com/PP-OCRv3/chinese/ch_PP-OCRv3_det_infer.tar

# Recognition 모델  
curl -L -o ios/Runner/PaddleOCR/models/ch_PP-OCRv3_rec_infer.nb \
  https://paddleocr.bj.bcebos.com/PP-OCRv3/chinese/ch_PP-OCRv3_rec_infer.tar

# 또는 전체 모델 패키지:
# https://github.com/PaddlePaddle/PaddleOCR/blob/release/2.7/deploy/lite/README.md
```

**필요한 파일:**
- `ch_PP-OCRv3_det_infer.nb` 또는 `inference.nb` (detection 모델)
- `ch_PP-OCRv3_rec_infer.nb` 또는 `rec_inference.nb` (recognition 모델)
- `ppocr_keys_v1.txt` (문자 사전) - 위에서 다운로드 완료

### 2. 모델 파일을 iOS 프로젝트에 추가

1. Xcode에서 `ios/Runner` 폴더에 `PaddleOCR` 폴더 생성
2. 다운로드한 모델 파일들을 `PaddleOCR` 폴더에 복사
3. Xcode에서 파일들을 프로젝트에 추가 (Add Files to "Runner")
4. Target Membership에서 "Runner" 체크 확인

### 4. Paddle-Lite iOS 프레임워크 다운로드 및 통합

#### Step 1: 프레임워크 다운로드

**Paddle-Lite iOS 프레임워크 다운로드:**

1. **GitHub Releases에서 다운로드:**
   - https://github.com/PaddlePaddle/Paddle-Lite/releases
   - 최신 버전의 iOS용 `.framework` 또는 `.xcframework` 파일 다운로드
   - 예: `PaddleLite.framework` 또는 `PaddleLite.xcframework`

2. **또는 직접 빌드:**
   ```bash
   git clone https://github.com/PaddlePaddle/Paddle-Lite.git
   cd Paddle-Lite
   # iOS 빌드 가이드 참고: https://paddle-lite.readthedocs.io/en/latest/user_guides/ios_x86.html
   ```

#### Step 2: Xcode 프로젝트에 프레임워크 추가

**방법 A: 드래그 앤 드롭 (가장 간단)**

1. **Finder에서 프레임워크 파일 준비**
   - 다운로드한 `PaddleLite.framework` 또는 `PaddleLite.xcframework` 파일 확인

2. **Xcode에서 프로젝트 열기**
   - `ios/Runner.xcworkspace` 열기 (`.xcodeproj`가 아님!)

3. **프레임워크를 프로젝트에 추가**
   - Xcode 왼쪽 Project Navigator에서 `Runner` 프로젝트 우클릭
   - 또는 `Frameworks` 폴더 우클릭
   - "Add Files to 'Runner'..." 선택
   - 다운로드한 프레임워크 파일 선택
   - **중요:** "Copy items if needed" 체크 ✅
   - "Add to targets: Runner" 체크 ✅
   - Add 클릭

**방법 B: 수동으로 Frameworks 폴더에 복사**

```bash
# 터미널에서 실행
cd ios/Runner
mkdir -p Frameworks
# 다운로드한 프레임워크를 Frameworks 폴더에 복사
cp /path/to/PaddleLite.framework Frameworks/
```

그 다음 Xcode에서:
- File → Add Files to "Runner"
- `Frameworks/PaddleLite.framework` 선택
- "Copy items if needed" 체크 해제 (이미 복사했으므로)
- Add

#### Step 3: Linked Frameworks and Libraries 설정

1. **Xcode에서 Target 설정 열기**
   - Project Navigator에서 최상위 `Runner` 프로젝트 클릭
   - TARGETS에서 `Runner` 선택
   - **General** 탭 클릭

2. **Frameworks, Libraries, and Embedded Content 추가**
   - "Frameworks, Libraries, and Embedded Content" 섹션 찾기
   - `+` 버튼 클릭
   - "Add Other..." → "Add Files..." 선택
   - 프로젝트에 추가한 `PaddleLite.framework` 선택
   - 또는 이미 목록에 있다면 그대로 사용

3. **Embed 설정 (중요!)**
   - 추가된 `PaddleLite.framework` 옆의 드롭다운 메뉴 클릭
   - **"Embed & Sign"** 선택 (앱 번들에 포함되어야 함)
   - 또는 "Do Not Embed" (정적 라이브러리인 경우)

#### Step 4: Build Settings 확인

1. **Build Settings 탭으로 이동**
   - TARGETS → Runner → Build Settings

2. **Framework Search Paths 확인**
   - 검색창에 "Framework Search Paths" 입력
   - `$(PROJECT_DIR)/Frameworks` 또는 프레임워크가 있는 경로 추가
   - 예: `$(SRCROOT)/Runner/Frameworks`

3. **Library Search Paths 확인**
   - "Library Search Paths"도 동일하게 설정

#### Step 5: Build Phases 확인

1. **Build Phases 탭으로 이동**
   - "Link Binary With Libraries" 섹션 확인
   - `PaddleLite.framework`가 목록에 있는지 확인

2. **Copy Bundle Resources 확인**
   - "Copy Bundle Resources" 섹션 확인
   - `ppocr_keys_v1.txt`가 포함되어 있는지 확인
   - 없다면 `+` 버튼으로 추가

#### Step 6: 헤더 파일 접근 설정 (필요한 경우)

만약 C++ 브리지가 필요하다면:

1. **Bridging Header 설정**
   - `ios/Runner/Runner-Bridging-Header.h` 파일 확인
   - Paddle-Lite 헤더 추가:
   ```objc
   #import <PaddleLite/PaddleLite.h>
   ```

2. **Objective-C++ 파일 생성 (필요시)**
   - `.mm` 확장자로 C++ 래퍼 클래스 생성

## 현재 구현

현재 `PaddleOCRHelper.swift`는 다음과 같이 동작합니다:

1. **모델 파일 확인**: `PaddleOCR` 폴더에서 모델 파일을 찾습니다
2. **Fallback 메커니즘**: 모델이 없으면 향상된 Vision Framework를 사용합니다
3. **이미지 전처리**: OCR 정확도 향상을 위한 이미지 전처리 포함

## 향상된 Vision Framework 설정

현재 구현에서는 Vision Framework의 다음 개선사항을 적용했습니다:

- **신뢰도 임계값 조정**: 0.3으로 낮춰 더 많은 텍스트 캡처
- **다중 후보 검토**: 상위 3개 후보 중 최고 신뢰도 선택
- **이미지 전처리**: 큰 이미지 자동 리사이즈
- **다국어 지원**: 한국어, 영어, 중국어, 일본어

## PaddleOCR 완전 통합 (향후 작업)

PaddleOCR 모델이 추가되면 `PaddleOCRHelper.swift`의 `recognizeText` 메서드를 업데이트하여 실제 Paddle-Lite 추론을 수행하도록 수정해야 합니다.

예시 코드 구조:

```swift
func recognizeText(image: UIImage, completion: @escaping (String) -> Void) {
    guard let modelPath = modelPath, isInitialized else {
        recognizeTextWithVision(image: image, completion: completion)
        return
    }
    
    // Paddle-Lite를 사용한 OCR 추론
    // 1. 이미지 전처리
    // 2. Detection 모델 실행
    // 3. Recognition 모델 실행
    // 4. 후처리 및 텍스트 조합
    // 5. completion 호출
}
```

## 테스트

1. 모델 파일 없이 테스트: 현재 Vision Framework 동작 확인
2. 모델 파일 추가 후 테스트: PaddleOCR 동작 확인
3. 다양한 이미지로 정확도 비교

## 참고 자료

- [PaddleOCR 공식 문서](https://github.com/PaddlePaddle/PaddleOCR)
- [Paddle-Lite iOS 가이드](https://paddle-lite.readthedocs.io/en/latest/user_guides/ios_x86.html)
- [PaddleOCR 모델 다운로드](https://github.com/PaddlePaddle/PaddleOCR/blob/release/2.7/doc/doc_ch/models_list.md)

## 문제 해결

### 모델 파일을 찾을 수 없음
- Xcode에서 파일이 Target에 포함되어 있는지 확인
- Bundle Resources에 파일이 포함되어 있는지 확인

### 빌드 오류
- Paddle-Lite 라이브러리 버전 확인
- iOS Deployment Target 확인 (최소 iOS 15.5)

### 성능 이슈
- 모바일용 경량 모델 사용 권장
- 이미지 크기 제한 (최대 2048px)
- 백그라운드 스레드에서 처리 확인
