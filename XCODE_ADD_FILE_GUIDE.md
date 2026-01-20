# 📱 Xcode 파일 추가 가이드

## 🎯 현재 작업: OnDeviceLLM.swift 추가

Xcode가 열렸습니다. 아래 단계를 따라주세요.

---

## 📋 단계별 가이드

### Step 1: Project Navigator 확인
- 좌측 패널에 폴더 구조가 보입니다
- `Runner` 폴더를 찾으세요

### Step 2: Runner 폴더 우클릭
- `Runner` 폴더에서 **우클릭** (또는 Control + 클릭)
- 메뉴에서 **"Add Files to "Runner""** 선택

### Step 3: 파일 선택
- 파일 선택 다이얼로그가 나타납니다
- 다음 경로로 이동:
  ```
  ios/Runner/OnDeviceLLM.swift
  ```
- `OnDeviceLLM.swift` 파일을 **선택**

### Step 4: 옵션 설정
다이얼로그 하단에서 다음을 확인:

✅ **"Copy items if needed"** - 체크  
✅ **"Create groups"** - 선택 (기본값)  
✅ **"Add to targets: Runner"** - 체크 (매우 중요!)

### Step 5: 추가 완료
- **"Add"** 버튼 클릭
- Project Navigator에 `OnDeviceLLM.swift`가 나타나야 함

---

## ✅ 확인 사항

### 1. 파일이 추가되었는지 확인
Project Navigator에서:
```
Runner
  ├── AppDelegate.swift
  ├── OnDeviceLLM.swift  ← 이 파일이 보여야 함
  └── PaddleOCRHelper.swift
```

### 2. Target Membership 확인
- `OnDeviceLLM.swift` 파일 선택
- 우측 패널 (File Inspector)
- **Target Membership** 섹션
- ✅ `Runner` 체크되어 있어야 함

---

## 🚀 완료 후 작업

Xcode는 그대로 두고, **터미널**로 돌아와서:

```bash
# 이 명령어를 실행하라고 알려주세요
echo "READY_TO_BUILD"
```

그러면 제가 빌드를 진행하겠습니다!

---

## ❓ 문제 발생 시

### "Add Files to Runner" 메뉴가 안 보임
- `Runner` **프로젝트** 아이콘을 우클릭하는지 확인
- 또는 메뉴바: **File** → **Add Files to "Runner"**

### OnDeviceLLM.swift 파일을 찾을 수 없음
- Finder를 열어서 확인:
  ```bash
  open ios/Runner
  ```
- `OnDeviceLLM.swift` 파일이 있는지 확인

### Target Membership에 Runner가 없음
- 파일을 다시 제거하고 처음부터 다시 추가
- 제거: 파일 선택 → Delete → "Remove Reference"

---

**준비되면 터미널에 "READY_TO_BUILD"를 입력하거나 말씀해주세요!** 🎉
