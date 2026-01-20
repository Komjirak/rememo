# ✅ Folio 설정 체크리스트

## 필수 설정

### 1. ✅ Gemini API 키 설정
- [ ] [Google AI Studio](https://aistudio.google.com/app/apikey)에서 API 키 발급
- [ ] `lib/services/gemini_service.dart` 파일 열기
- [ ] `_apiKey` 변수에 발급받은 API 키 입력
- [ ] 파일 저장

```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';  // ❌ 수정 필요
static const String _apiKey = 'AIzaSyDXXXXXXX...'; // ✅ 올바른 예시
```

### 2. ✅ Flutter 패키지 설치
```bash
flutter pub get
```

### 3. ✅ iOS CocoaPods 설치
```bash
cd ios
pod install
cd ..
```

## 선택 설정

### 4. ⚙️ Paddle OCR 모델 확인
현재 프로젝트에는 Paddle OCR 모델이 포함되어 있습니다:
- [ ] `ios/Runner/PaddleOCR/` 폴더 확인
- [ ] 모델 파일 존재 확인:
  - `ch_PP-OCRv3_det_infer.nb` (Detection)
  - `ch_PP-OCRv3_rec_infer.nb` (Recognition)
  - `dict/korean_dict.txt` (한국어 사전)

### 5. 🔐 권한 설정 (iOS)
앱 실행 시 다음 권한을 허용해주세요:
- [ ] 사진 라이브러리 접근 (필수)
- [ ] 카메라 접근 (선택)

## 테스트

### 6. 🧪 앱 실행 테스트
```bash
flutter run
```

### 7. 📸 기능 테스트
- [ ] 스크린샷 가져오기 버튼 클릭
- [ ] "Analyzing..." 로딩 표시 확인
- [ ] AI Summary가 완전한 문장으로 표시되는지 확인
- [ ] 제목이 의미있게 생성되었는지 확인

### 8. ✨ AI 분석 품질 확인
좋은 예시:
```
제목: AI와 인간의 미래: 일의 변화
요약: 이 스크린샷은 스티브 울프램의 발언을 포함하고 있으며...
```

나쁜 예시 (API 키 미설정):
```
제목: watch
요약: • 이제 우리는 AI를...
```

## 문제 해결

### ❌ "API 키 오류" 발생 시
1. API 키가 올바르게 복사되었는지 확인
2. 따옴표 안에 키가 들어있는지 확인
3. Google AI Studio에서 API 키가 활성화되어 있는지 확인

### ❌ "패키지 설치 실패" 발생 시
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

### ❌ "빌드 실패" 발생 시
1. Xcode 버전 확인 (14.0 이상 권장)
2. iOS 시뮬레이터 또는 실제 기기 연결 확인
3. Clean Build Folder (Xcode → Product → Clean Build Folder)

### ❌ "OCR 텍스트가 비어있음" 발생 시
1. 스크린샷에 텍스트가 포함되어 있는지 확인
2. 사진 권한이 허용되어 있는지 확인
3. iOS 시뮬레이터에서는 Paddle OCR이 작동하지 않을 수 있음 (실제 기기 사용 권장)

## 💡 팁

### 개발 중 유용한 명령어
```bash
# Hot reload
r

# Hot restart  
R

# 디버그 로그 확인
flutter logs

# 빌드 정리
flutter clean
```

### API 사용량 모니터링
- [Google AI Studio Console](https://aistudio.google.com/)에서 사용량 확인
- 무료 할당량: 월 1,500회 요청

### 성능 최적화
- 스크린샷 크기가 클 경우 OCR 처리 시간이 길어질 수 있음
- Wi-Fi 연결 시 Gemini API 응답이 더 빠름

---

✅ 모든 항목을 완료하셨다면 Folio를 사용할 준비가 완료되었습니다!

궁금한 점이 있으시면 [Issues](https://github.com/Komjirak/folio/issues)를 통해 문의해주세요.
