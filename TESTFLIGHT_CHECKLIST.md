# TestFlight 배포 전 체크리스트

## ✅ 완료된 작업

1. **PaddleOCR iOS 통합**
   - ✅ Paddle-Lite 라이브러리 빌드 완료
   - ✅ Detection/Recognition 모델 실행 코드 구현
   - ✅ Vision Framework → PaddleOCR 전환 완료

2. **상세 화면 개선**
   - ✅ 제목: 스크린샷 핵심 제목 추론 표시
   - ✅ AI Summary: 스크린샷 정보 요약 표시
   - ✅ Original Message: 전체 OCR 원본 텍스트 표시 (새로 추가)

## 🔍 빌드 전 확인사항

### 1. 코드 검증
- [x] Linter 오류 없음
- [x] `_buildOriginalMessageSection()` 메서드 구현됨
- [x] `ocrText` 필드가 데이터베이스에 저장됨

### 2. iOS 빌드 확인
```bash
# Xcode에서 빌드 테스트
# Cmd + B (빌드)
# Cmd + R (시뮬레이터 실행)
```

**확인할 사항:**
- [ ] 빌드 성공 (에러 없음)
- [ ] PaddleOCR 초기화 로그 확인
- [ ] OCR 동작 확인

### 3. 실제 디바이스 테스트 (권장)
- [ ] 실제 iPhone/iPad에서 테스트
- [ ] 스크린샷 캡처 → OCR 동작 확인
- [ ] 상세 화면에서 Original Message 표시 확인

## 📱 TestFlight 배포 단계

### Step 1: Archive 빌드
1. Xcode에서 **Product → Scheme → Runner** 선택
2. **Product → Destination → Any iOS Device** 선택
3. **Product → Archive** 실행
4. 빌드 완료 대기

### Step 2: App Store Connect 업로드
1. Organizer 창에서 **Distribute App** 클릭
2. **App Store Connect** 선택
3. **Upload** 선택
4. 서명 옵션 확인 후 **Upload** 클릭

### Step 3: TestFlight 설정
1. App Store Connect에서 **TestFlight** 탭으로 이동
2. 빌드가 처리될 때까지 대기 (보통 10-30분)
3. **Internal Testing** 또는 **External Testing** 그룹에 추가
4. 테스터 초대

## 🧪 테스트 시나리오

### 기본 기능 테스트
1. **스크린샷 캡처**
   - [ ] 앱이 자동으로 스크린샷 감지
   - [ ] OCR 처리 완료
   - [ ] 카드 생성 확인

2. **상세 화면 확인**
   - [ ] 제목이 올바르게 표시됨
   - [ ] AI Summary가 요약된 내용으로 표시됨
   - [ ] **Original Message 섹션이 표시됨** (새 기능)
   - [ ] Original Message에 전체 OCR 텍스트가 표시됨
   - [ ] Copy 버튼 동작 확인

3. **PaddleOCR 정확도 확인**
   - [ ] Vision Framework보다 정확도 향상 확인
   - [ ] 전체 텍스트 파싱 확인
   - [ ] 다국어 지원 확인 (한국어, 영어 등)

### 예상되는 개선사항
- ✅ 텍스트 인식 정확도 향상
- ✅ 전체 텍스트 파싱 (누락 감소)
- ✅ 제목/내용 추출 개선
- ✅ Original Message로 원본 텍스트 확인 가능

## ⚠️ 주의사항

### 앱 크기
- Paddle-Lite 라이브러리와 모델 파일로 인해 앱 크기가 증가할 수 있음
- 예상: +50MB ~ +100MB 정도

### 성능
- 첫 OCR 실행 시 모델 로딩으로 약간의 지연 가능
- 이후 실행은 캐시되어 빠름

### 오류 발생 시
1. **PaddleOCR 초기화 실패**
   - 로그 확인: "✅ PaddleOCR 초기화 완료" 메시지 확인
   - 모델 파일 경로 확인
   - 자동으로 Vision Framework로 fallback됨

2. **OCR 결과가 비어있음**
   - 이미지 품질 확인
   - 로그에서 "⚠️ PaddleOCR 결과가 비어있습니다" 메시지 확인
   - Vision Framework로 자동 fallback됨

## 📝 다음 단계

빌드가 성공하면:
1. 실제 디바이스에서 테스트
2. 다양한 스크린샷으로 OCR 정확도 확인
3. TestFlight에 업로드
4. 테스터 피드백 수집

문제가 발생하면 로그를 확인하고 알려주세요!
