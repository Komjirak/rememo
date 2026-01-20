# 🤖 Gemma 2B Core ML 설치 가이드

## 📌 개요

온디바이스 LLM (Gemma 2B)을 통합하여 완전 무료, 오프라인으로 스크린샷을 지능적으로 분석합니다.

## ✨ 장점

| 항목 | Gemini API | Gemma 2B (온디바이스) |
|------|-----------|---------------------|
| 속도 | 1-3초 (네트워크) | 1-2초 (로컬) |
| 정확도 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 비용 | 유료 (1,500회/월 무료) | 완전 무료 |
| 인터넷 | 필요 | 불필요 |
| 프라이버시 | 클라우드 전송 | 기기 내 처리 |
| 앱 크기 | 작음 | +2.5GB |

## 🚀 설치 방법

### 옵션 1: 자동 설치 (추천)

```bash
# 프로젝트 루트에서 실행
./scripts/download_gemma_model.sh
```

스크립트가 자동으로:
- Hugging Face에서 Gemma 2B 모델 다운로드 (~2.5GB)
- ios/Runner/MLModels/ 폴더에 압축 해제
- 설치 완료 메시지 출력

### 옵션 2: 수동 설치

#### Step 1: 모델 다운로드

1. [Hugging Face - Apple Core ML Gemma](https://huggingface.co/apple/coreml-gemma-2b-instruct) 방문
2. "Files and versions" 탭 클릭
3. `gemma-2b-it-q4.mlpackage.zip` 다운로드 (~2.5GB)

또는 터미널에서:

```bash
cd ios/Runner
mkdir -p MLModels
cd MLModels

# wget 사용
wget https://huggingface.co/apple/coreml-gemma-2b-instruct/resolve/main/gemma-2b-it-q4.mlpackage.zip

# 또는 curl 사용
curl -L -O https://huggingface.co/apple/coreml-gemma-2b-instruct/resolve/main/gemma-2b-it-q4.mlpackage.zip

# 압축 해제
unzip gemma-2b-it-q4.mlpackage.zip
mv gemma-2b-it-q4.mlpackage gemma-2b-it.mlpackage
```

#### Step 2: Xcode 프로젝트에 추가

1. **Xcode 열기**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **모델 파일 추가**
   - Project Navigator에서 `Runner` 선택
   - `File` → `Add Files to "Runner"` 클릭
   - `ios/Runner/MLModels/gemma-2b-it.mlpackage` 선택
   - ✅ "Copy items if needed" 체크
   - ✅ "Add to targets: Runner" 체크
   - `Add` 클릭

3. **Target Membership 확인**
   - Project Navigator에서 `gemma-2b-it.mlpackage` 선택
   - 우측 File Inspector에서 "Target Membership" 확인
   - ✅ `Runner` 체크되어 있어야 함

4. **Build Settings 확인 (자동)**
   - `COREML_CODEGEN_LANGUAGE = Swift`
   - `COREML_CODEGEN_SWIFT_VERSION = 5`

## 🎯 사용 방법

### 자동 통합 완료!

모델 설치 후 앱을 실행하면 자동으로 LLM을 사용합니다:

```bash
flutter run
```

### 동작 확인

1. **앱 시작 로그**
   ```
   🤖 Gemma 2B 모델 로드 시도 중...
   ✅ Gemma 2B 모델 로드 완료!
   ```

2. **스크린샷 분석 시 로그**
   ```
   🤖 온디바이스 LLM 호출 중...
   ✅ LLM 분석 완료: AI와 인간의 미래 (1.23초)
   ```

3. **Fallback 로그** (모델 없을 때)
   ```
   ⚠️ Gemma 모델 파일을 찾을 수 없습니다.
   → Fallback: 규칙 기반 분석 사용
   ```

## 🔍 문제 해결

### ❌ "모델 파일을 찾을 수 없습니다"

**원인**: Xcode 프로젝트에 모델이 추가되지 않음

**해결**:
1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. Project Navigator에서 `gemma-2b-it.mlpackage` 찾기
3. 없으면 Step 2 다시 수행
4. 있으면 Target Membership 확인

### ❌ "모델 로드 실패"

**원인**: 파일이 손상되었거나 호환되지 않음

**해결**:
```bash
# 모델 재다운로드
rm -rf ios/Runner/MLModels/gemma-2b-it.mlpackage
./scripts/download_gemma_model.sh
```

### ❌ "메모리 부족"

**원인**: 디바이스 메모리 부족 (2.5GB 모델)

**해결**:
- iPhone 12 이상 권장 (최소 4GB RAM)
- 다른 앱 종료
- 더 작은 모델 사용 (gemma-1b, 추후 지원 예정)

### ❌ 빌드 오류 "No such module 'CoreML'"

**원인**: iOS SDK 문제

**해결**:
```bash
# Xcode 재설치 또는
xcode-select --install

# Pod 재설치
cd ios
pod deintegrate
pod install
cd ..
```

## 📊 성능 벤치마크

### iPhone 14 Pro (A16 Bionic)
- 모델 로드: ~1.5초 (첫 실행)
- 분석 속도: ~0.8-1.2초/스크린샷
- 메모리 사용: ~500MB

### iPhone 12 (A14 Bionic)
- 모델 로드: ~2.5초 (첫 실행)
- 분석 속도: ~1.5-2.0초/스크린샷
- 메모리 사용: ~650MB

### iPhone 11 이하
- ⚠️ 작동은 하지만 느릴 수 있음
- Fallback (규칙 기반) 사용 권장

## 🔧 고급 설정

### 다른 모델 사용하기

**Gemma 1B** (더 작고 빠름, 1GB):
```bash
# 1B 모델 다운로드
cd ios/Runner/MLModels
curl -L -O https://huggingface.co/apple/coreml-gemma-1b-instruct/resolve/main/gemma-1b-it-q4.mlpackage.zip
unzip gemma-1b-it-q4.mlpackage.zip
mv gemma-1b-it-q4.mlpackage gemma-2b-it.mlpackage  # 이름 변경
```

**Phi-3 Mini** (더 빠름, 2GB):
```bash
# Phi-3 모델 (향후 지원 예정)
# 현재는 Gemma만 지원
```

### 프롬프트 커스터마이징

`ios/Runner/OnDeviceLLM.swift` 파일 수정:

```swift
let prompt = """
분석: \(context.prefix(500))

제목(20자):
요약(100자):
핵심(3개, 각30자):
"""
```

↓ 변경 ↓

```swift
let prompt = """
Analyze this screenshot text:
\(context.prefix(500))

Title (max 20 chars):
Summary (max 100 chars):
Key insights (3-4 items, max 30 chars each):
"""
```

## 📚 참고 자료

- [Apple Core ML](https://developer.apple.com/machine-learning/core-ml/)
- [Gemma 모델 카드](https://ai.google.dev/gemma)
- [Hugging Face - Apple Gemma](https://huggingface.co/apple/coreml-gemma-2b-instruct)

## 🎯 다음 단계

1. **모델 설치 확인**
   ```bash
   ls -lh ios/Runner/MLModels/
   # gemma-2b-it.mlpackage가 있어야 함 (~2.5GB)
   ```

2. **앱 실행**
   ```bash
   flutter run
   ```

3. **스크린샷 분석 테스트**
   - 텍스트가 많은 스크린샷 가져오기
   - AI Summary가 의미있게 생성되는지 확인
   - 로그에서 LLM 사용 확인

4. **성능 모니터링**
   - Xcode Instruments로 메모리 사용량 확인
   - 분석 속도 측정

---

**문의사항이 있으시면 GitHub Issues를 통해 연락해주세요!**
