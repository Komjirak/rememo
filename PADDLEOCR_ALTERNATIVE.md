# PaddleOCR iOS 통합 - 대안 방법

GitHub Releases에 프레임워크 파일이 없는 경우의 대안 방법입니다.

## 🎯 현재 상황

- ✅ 모델 파일: 준비 완료 (`ch_PP-OCRv3_det_infer.nb`, `ch_PP-OCRv3_rec_infer.nb`)
- ✅ 딕셔너리 파일: 준비 완료 (`ppocr_keys_v1.txt`)
- ❌ Paddle-Lite 프레임워크: 없음 (Releases에 없음)

## 🔧 해결 방법

### 방법 1: 소스에서 빌드 (권장)

이미 Paddle-Lite 소스를 클론했으므로, 빌드 스크립트를 실행하세요:

```bash
cd /Users/sogsagim/folio/folio
./scripts/build_paddlelite_ios.sh
```

**주의사항:**
- 빌드에 30분~1시간 이상 걸릴 수 있습니다
- Xcode와 CMake가 필요합니다
- macOS에서만 실행 가능합니다

### 방법 2: PaddleOCR 공식 문서 확인

PaddleOCR 공식 문서에서 프리빌트 라이브러리 링크 확인:
- https://www.paddlepaddle.org.cn/lite/develop/quick_start/release_lib.html
- https://paddlepaddle.github.io/PaddleOCR/v2.9.1/en/ppocr/infer_deploy/lite.html

### 방법 3: Vision Framework 사용 (현재 상태 유지)

Paddle-Lite 없이도 현재 구현된 **향상된 Vision Framework**를 사용할 수 있습니다:

- ✅ 이미 구현되어 있음
- ✅ 다국어 지원 (한국어, 영어, 중국어, 일본어)
- ✅ 신뢰도 임계값 조정으로 정확도 향상
- ✅ 이미지 전처리 포함

**현재 Vision Framework의 장점:**
- 즉시 사용 가능
- 추가 의존성 없음
- 앱 크기 증가 없음
- 빠른 처리 속도

## 📋 권장 사항

**지금 당장 OCR이 필요하다면:**
→ 현재 구현된 Vision Framework 사용 (이미 작동 중)

**정말 높은 정확도가 필요하다면:**
→ Paddle-Lite 소스 빌드 시도 (`./scripts/build_paddlelite_ios.sh`)

**빌드가 복잡하거나 실패하면:**
→ Vision Framework로 충분한지 테스트 후 결정

## 🚀 다음 단계

1. **빌드 시도:**
   ```bash
   ./scripts/build_paddlelite_ios.sh
   ```

2. **빌드 실패 시:**
   - Vision Framework로 충분한지 테스트
   - 필요시 PaddleOCR 공식 문서에서 다른 방법 확인

3. **빌드 성공 시:**
   - `PADDLEOCR_FRAMEWORK_GUIDE.md` 가이드 따라 Xcode에 추가
   - `PaddleOCRHelper.swift`에서 실제 Paddle-Lite API 호출 코드 추가
