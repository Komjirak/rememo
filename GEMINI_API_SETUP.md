# Gemini API 설정 가이드

## 📌 개요

Folio 앱은 Google Gemini 2.0 Flash를 사용하여 스크린샷의 텍스트를 지능적으로 분석하고, 정확한 제목과 요약을 자동으로 생성합니다.

## 🔑 API 키 발급 방법

### 1. Google AI Studio 방문
[https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)

### 2. API 키 생성
- "Create API Key" 버튼 클릭
- 새 프로젝트 선택 또는 기존 프로젝트 선택
- API 키 복사

### 3. API 키 적용

#### lib/services/gemini_service.dart 파일 수정

```dart
class GeminiService {
  // 여기에 발급받은 API 키를 입력하세요
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  
  // 예시:
  // static const String _apiKey = 'AIzaSyDXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
```

## 🎯 기능 설명

### Gemini AI가 제공하는 기능

1. **스마트 타이틀 생성**
   - 스크린샷의 핵심 내용을 20자 이내로 요약한 명확한 제목
   - 예: "AI와 인간의 미래: 일의 변화와 교육의 방향"

2. **AI 요약 (AI Summary)**
   - 스크린샷의 주요 내용을 2-3문장으로 정리
   - 80-120자 길이의 명확한 요약문

3. **핵심 인사이트 추출**
   - 중요한 포인트 3-4개를 bullet point로 제공
   - 각 인사이트는 30자 이내

### Paddle OCR + Gemini AI 워크플로우

```
1. 스크린샷 촬영
   ↓
2. Paddle OCR로 텍스트 추출 (한국어, 영어, 일본어 지원)
   ↓
3. Gemini AI로 분석
   - 제목 생성
   - 요약 생성
   - 핵심 인사이트 추출
   ↓
4. 자동 카테고리 분류 및 태그 추가
   ↓
5. 데이터베이스 저장
```

## 💡 비용 안내

### Gemini 2.0 Flash 무료 할당량 (2026년 1월 기준)

- **무료**: 월 1,500회 요청 (RPM: 15)
- **각 스크린샷 분석**: 약 1회 API 호출
- **예상 사용량**: 하루 10개 스크린샷 → 월 300회 → 무료 사용 가능 ✅

### 할당량 확인
[https://ai.google.dev/pricing](https://ai.google.dev/pricing)

## 🔒 보안 권장사항

### ⚠️ 중요: API 키 보안

현재는 코드에 직접 API 키를 입력하지만, 프로덕션 배포 시에는 다음 방법을 사용하세요:

1. **환경 변수 사용**
   ```dart
   // .env 파일 사용 (flutter_dotenv 패키지)
   static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
   ```

2. **Firebase Remote Config 사용**
   - 원격으로 API 키 관리
   - 앱 재배포 없이 키 업데이트 가능

3. **백엔드 프록시 사용**
   - 서버에서 Gemini API 호출
   - 클라이언트는 서버 API만 호출

## 🧪 테스트

### API 키가 올바르게 설정되었는지 확인

1. 앱 실행
2. 스크린샷 가져오기
3. "Analyzing..." 로딩 표시 확인
4. AI Summary 섹션에 완전한 문장이 표시되는지 확인

### 문제 해결

#### "API 키 오류"
- API 키가 올바르게 복사되었는지 확인
- Google AI Studio에서 API 키가 활성화되어 있는지 확인

#### "할당량 초과"
- Google AI Studio에서 사용량 확인
- 무료 할당량 초과 시 대기 또는 유료 플랜 고려

#### "응답이 비어있음"
- 네트워크 연결 확인
- Gemini API 서비스 상태 확인

## 📚 추가 자료

- [Gemini API 문서](https://ai.google.dev/docs)
- [Flutter Google Generative AI 패키지](https://pub.dev/packages/google_generative_ai)
- [Google AI Studio](https://aistudio.google.com/)

## 🎨 예시 결과

### 이전 (단순 텍스트 추출)
```
제목: "watch"
요약: "• 이제 우리는 AI를 통해 더 높은 탐을 쌓을 수 있습니다."
      "• 그는 이제 계산과 닮은 AI가 하므로, 교육의 초점은..."
```

### 개선 후 (Gemini AI)
```
제목: "AI와 인간의 미래: 일의 변화와 교육"
요약: "이 스크린샷은 스티브 울프램의 발언을 포함하고 있으며, 
      AI가 인간의 일자리를 대체하지 않을 것이라고 예측하며, 
      대신 일의 종류가 변할 것이라고 주장합니다."

핵심 내용:
• AI를 통해 더 높은 탐을 쌓을 수 있다
• 계산과 닮은 AI가 하므로, 교육의 초점은 질문의 가치와 사고 방법에 맞춰야 한다
• 지 않는 미래는 오지 않을 것이라며, 대신 "일의 종류가 변할 것"
• 기초 연산에 매몰되는 대신, 그 위에 무엇을 구축할지 고민해야 한다
```

---

**문의사항이 있으시면 GitHub Issues를 통해 연락해주세요!**
