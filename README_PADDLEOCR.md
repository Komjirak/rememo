# PaddleOCR 통합 완료 가이드

## ✅ 완료된 작업

1. ✅ **PaddleOCRHelper.swift** 생성 - PaddleOCR 통합을 위한 헬퍼 클래스
2. ✅ **AppDelegate.swift** 업데이트 - PaddleOCRHelper 사용하도록 변경
3. ✅ **딕셔너리 다운로드 스크립트** 생성 - `scripts/download_paddleocr_resources.sh`
4. ✅ **상세 가이드 문서** 작성:
   - `PADDLEOCR_SETUP.md` - 전체 통합 가이드
   - `PADDLEOCR_FRAMEWORK_GUIDE.md` - 프레임워크 추가 상세 가이드

## 📋 당신이 해야 할 일 (3단계)

### 1️⃣ 딕셔너리 파일 다운로드

터미널에서 실행:

```bash
cd /Users/sogsagim/folio/folio
./scripts/download_paddleocr_resources.sh
```

또는 수동으로:
```bash
mkdir -p ios/Runner/PaddleOCR/dict
curl -L -o ios/Runner/PaddleOCR/dict/ppocr_keys_v1.txt \
  https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/ppocr_keys_v1.txt
```

### 2️⃣ Paddle-Lite 프레임워크 추가

**`PADDLEOCR_FRAMEWORK_GUIDE.md` 파일을 열어서 단계별로 따라하세요!**

요약:
1. https://github.com/PaddlePaddle/Paddle-Lite/releases 에서 iOS 프레임워크 다운로드
2. Xcode에서 `ios/Runner.xcworkspace` 열기
3. 프레임워크를 프로젝트에 드래그 앤 드롭
4. General 탭 → Frameworks, Libraries, and Embedded Content → "Embed & Sign" 설정

### 3️⃣ 모델 파일 추가 (선택사항, 나중에)

PaddleOCR 모델 파일을 추가하면 자동으로 감지됩니다:
- `ios/Runner/PaddleOCR/models/ch_PP-OCRv3_det_infer.nb` (Detection)
- `ios/Runner/PaddleOCR/models/ch_PP-OCRv3_rec_infer.nb` (Recognition)

## 🎯 현재 동작 방식

- **딕셔너리 파일만 있으면**: 향상된 Vision Framework 사용 (현재 상태)
- **딕셔너리 + 모델 파일 있으면**: PaddleOCR 모델 감지 (아직 Paddle-Lite 통합 필요)
- **모든 파일 + 프레임워크 있으면**: 완전한 PaddleOCR 동작 (추후 구현)

## 📚 참고 문서

- **`PADDLEOCR_SETUP.md`** - 전체 통합 가이드 및 모델 다운로드 방법
- **`PADDLEOCR_FRAMEWORK_GUIDE.md`** - 프레임워크 추가 상세 가이드 (단계별 스크린샷 포함)

## ❓ 문제 해결

### ppocr_keys_v1.txt를 찾을 수 없음
- 스크립트 실행 확인: `./scripts/download_paddleocr_resources.sh`
- 파일 위치 확인: `ios/Runner/PaddleOCR/dict/ppocr_keys_v1.txt`
- Xcode에서 Target Membership 확인

### 프레임워크 추가 오류
- `PADDLEOCR_FRAMEWORK_GUIDE.md`의 Step 4-6 참고
- "Embed & Sign" 설정 확인
- Framework Search Paths 확인

### 빌드 오류
- Clean Build Folder 실행 (Shift + Cmd + K)
- CocoaPods 재설치: `cd ios && pod install`
