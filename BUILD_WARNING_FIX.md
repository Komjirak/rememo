# 🔧 빌드 경고 수정 가이드

## 문제 상황

Xcode 빌드 시 다음과 같은 경고가 대량으로 발생했습니다:
```
ld: warning: object file (.../MLKitCommon.framework/MLKitCommon[arm64]...)
was built for newer 'iOS' version (15.5) than being linked (14.0)
```

## 원인 분석

1. **Podfile 설정**: iOS 15.5로 설정되어 있음
2. **Xcode 프로젝트 설정**: 일부 타겟이 iOS 13.0 또는 14.0으로 설정되어 있음
3. **MLKitCommon 프레임워크**: iOS 15.5로 빌드됨
4. **결과**: 버전 불일치로 인한 링커 경고 발생

## 해결 방법

### ✅ 적용된 수정사항

1. **Xcode 프로젝트 배포 타겟 통일**
   - 모든 타겟의 `IPHONEOS_DEPLOYMENT_TARGET`을 `15.5`로 변경
   - `project.pbxproj` 파일에서 9개 타겟 업데이트

2. **ShareExtension 버전 확인**
   - CFBundleVersion이 부모 앱과 일치하는지 확인 (21)

### 📋 다음 단계

1. **Xcode에서 Clean Build**
   ```bash
   # Xcode에서 Product > Clean Build Folder (Shift+Cmd+K)
   ```

2. **Pod 재설치 (선택사항)**
   ```bash
   cd ios
   pod deintegrate
   pod install
   ```

3. **빌드 재시도**
   - Xcode에서 Product > Build (Cmd+B)
   - 경고가 대폭 감소하거나 사라져야 합니다

### ⚠️ 주의사항

- **최소 iOS 버전**: 이제 앱은 iOS 15.5 이상에서만 실행됩니다
- **기기 호환성**: iOS 15.5 미만 기기는 앱을 설치할 수 없습니다
- **TestFlight**: iOS 15.5 이상 기기에서만 테스트 가능

### 🔍 추가 확인사항

만약 여전히 경고가 발생한다면:

1. **Xcode에서 직접 확인**
   - Project Navigator에서 프로젝트 선택
   - 각 타겟의 "General" 탭에서 "Minimum Deployments" 확인
   - 모든 타겟이 15.5로 설정되어 있는지 확인

2. **Build Settings 확인**
   - "iOS Deployment Target" 검색
   - 모든 타겟이 15.5로 설정되어 있는지 확인

3. **Pod 재설치**
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   ```

## 예상 결과

수정 후:
- ✅ MLKitCommon 관련 경고 대폭 감소 또는 제거
- ✅ Google 프레임워크 관련 경고 감소
- ✅ 빌드는 여전히 성공 (경고만 제거)
- ✅ 앱 기능에는 영향 없음

## 참고

- 이 경고들은 **경고(warning)**이지 **오류(error)**가 아닙니다
- 빌드는 성공했지만, 버전 불일치를 해결하는 것이 좋습니다
- iOS 15.5는 2021년 9월 출시된 버전으로, 대부분의 활성 기기에서 지원됩니다
