# Rememo Design System Guide
# 디자인 시스템 가이드

> **중요**: 이 문서는 Rememo의 모든 디자인 작업에 대한 공식 가이드입니다. 새로운 기능 개발, UI 개선, 또는 디자인 변경 시 반드시 이 가이드를 따라야 합니다.

---

## 1. 브랜드 정체성 (Brand Identity)

### 서비스명
**Rememo** - AI 기반 스크린샷 지식 아카이브

### 핵심 가치
- **평온함** (Calmness): 복잡한 정보를 평온하게 정리
- **지적 자산** (Intellectual Asset): 개인의 지식을 체계적으로 축적
- **자동화된 기록** (Automated Recording): AI가 자동으로 분석하고 정리

### 심볼
캡처 프레임과 AI 코어가 결합된 **티알(Teal)** 로고

---

## 2. 컬러 시스템 (Color System)

### 2.1 다크 모드 (Primary - 기본)

| 구분 | Hex Code | 용도 |
|------|----------|------|
| **Main Background** | `#0A0A0A` | 메인 배경 (Deep Charcoal) |
| **Card / Surface** | `#161616` | 카드, 서피스 (Muted Dark) |
| **Accent Color** | `#4FD1C5` | 시그니처 티알, 버튼, 강조 |
| **Typography (High)** | `#F2F2F2` | 주요 텍스트 (Near White) |
| **Typography (Low)** | `#8E8E93` | 보조 텍스트 (Muted Gray) |

### 2.2 라이트 모드 (Optional)

| 구분 | Hex Code | 용도 |
|------|----------|------|
| **Main Background** | `#F8F9FA` | 메인 배경 (Off-White) |
| **Card / Surface** | `#FFFFFF` | 카드, 서피스 (Pure White) |
| **Accent Color** | `#38B2AC` | 시그니처 티알 (Deep Teal) |
| **Typography (High)** | `#1A1A1A` | 주요 텍스트 (Deep Charcoal) |
| **Typography (Low)** | `#636366` | 보조 텍스트 (Medium Gray) |

### 2.3 컬러 사용 원칙
- **다크 모드 우선**: 기본 테마는 다크 모드
- **티알 액센트**: 모든 주요 액션 버튼과 강조 요소에 `#4FD1C5` 사용
- **대비 유지**: 텍스트와 배경 간 충분한 대비 확보 (WCAG AA 이상)
- **일관성**: 동일한 요소는 항상 동일한 컬러 사용

---

## 3. 타이포그래피 (Typography)

### 3.1 폰트 패밀리
- **Primary**: Google Fonts - Inter / Roboto
- **Korean**: Pretendard (한글 최적화)

### 3.2 텍스트 위계

| 레벨 | 크기 | 굵기 | 용도 |
|------|------|------|------|
| **H1** | 28px | Bold (700) | 페이지 제목 |
| **H2** | 24px | SemiBold (600) | 섹션 제목 |
| **H3** | 20px | SemiBold (600) | 서브섹션 제목 |
| **Body** | 16px | Regular (400) | 본문 텍스트 |
| **Caption** | 14px | Regular (400) | 보조 정보 |
| **Small** | 12px | Regular (400) | 메타데이터 |

### 3.3 텍스트 컬러
- **High Emphasis**: `#F2F2F2` (다크) / `#1A1A1A` (라이트)
- **Medium Emphasis**: `#B0B0B0` (다크) / `#4A4A4A` (라이트)
- **Low Emphasis**: `#8E8E93` (다크) / `#636366` (라이트)

---

## 4. 레이아웃 및 스페이싱 (Layout & Spacing)

### 4.1 그리드 시스템
- **컬럼**: 2-3 컬럼 그리드 (화면 크기에 따라 조정)
- **거터**: 16px
- **마진**: 좌우 16px

### 4.2 스페이싱 스케일
```
4px  - XXS (아이콘 간격)
8px  - XS  (태그 간격)
12px - S   (카드 내부 여백)
16px - M   (섹션 간격)
24px - L   (큰 섹션 간격)
32px - XL  (페이지 상단 여백)
48px - XXL (특별한 구분)
```

---

## 5. 컴포넌트 (Components)

### 5.1 홈 화면 (Home Screen)

#### 상단 헤더
```
[Title: "Rememo"] + [Search Icon] + [Settings Icon]
```
- **배경**: `#0A0A0A` (다크) / `#F8F9FA` (라이트)
- **높이**: 56px
- **Title**: H2 크기, High Emphasis
- **아이콘**: 24px, Medium Emphasis

#### 필터링 섹션
```
[All] [Favorite] (Pill Buttons) | [Folders ▼] [Type ▼] (Dropdowns)
```
- **Pill Button (Active)**: 배경 `#4FD1C5`, 텍스트 `#0A0A0A`
- **Pill Button (Inactive)**: 배경 `#161616`, 텍스트 `#8E8E93`
- **Dropdown**: 배경 `#161616`, 텍스트 `#F2F2F2`

#### 플로팅 액션 버튼 (FAB)
- **위치**: 우측 하단 (16px margin)
- **크기**: 56x56px
- **배경**: `#4FD1C5` (시그니처 티알)
- **아이콘**: '+' (흰색, 24px)
- **그림자**: 0px 4px 12px rgba(79, 209, 197, 0.3)

#### 메모 카드 (Grid/List View)
- **배경**: `#161616`
- **모서리**: 12px border-radius
- **패딩**: 12px
- **그림자**: 0px 2px 8px rgba(0, 0, 0, 0.2)
- **호버**: 약간 밝아짐 (`#1C1C1C`)

### 5.2 상세 페이지 (Detail Page)

#### 페이지 구조 (위에서 아래로)
```
1. AI Generated Title (H1)
2. Date & Metadata (Caption)
3. Automated Tags (Tag Chips)
4. Original Image & URL (Image Card)
5. AI Summary (Section)
6. Personal Note (Editable Section)
7. Original Message (Collapsible Section)
8. Floating Menu (Bottom Bar)
```

#### 1. AI Generated Title
- **크기**: H1 (28px, Bold)
- **컬러**: `#F2F2F2` (High Emphasis)
- **여백**: 상단 32px, 하단 8px

#### 2. Date & Metadata
- **크기**: Caption (14px, Regular)
- **컬러**: `#8E8E93` (Low Emphasis)
- **포맷**: "2026년 1월 24일 오후 8:12"

#### 3. Automated Tags
- **배경**: `#161616`
- **테두리**: 1px solid `#4FD1C5`
- **텍스트**: `#4FD1C5` (14px, Medium)
- **패딩**: 6px 12px
- **모서리**: 16px border-radius
- **간격**: 8px

#### 4. Original Image & URL
- **이미지 카드**: 배경 `#161616`, 12px border-radius
- **URL 링크**: `#4FD1C5`, 밑줄 없음, 호버 시 밑줄
- **아이콘**: 외부 링크 아이콘 (16px)

#### 5. AI Summary
- **제목**: "AI 요약" (H3, 20px, SemiBold)
- **배경**: `#161616` (카드 형태)
- **패딩**: 16px
- **텍스트**: Body (16px, Regular), `#F2F2F2`

#### 6. Personal Note
- **제목**: "개인 메모" (H3, 20px, SemiBold)
- **입력 필드**: 배경 `#161616`, 테두리 1px `#2A2A2A`
- **플레이스홀더**: "메모를 입력하세요..." (`#8E8E93`)
- **저장 버튼**: 배경 `#4FD1C5`, 텍스트 `#0A0A0A`

#### 7. Original Message
- **제목**: "원본 메시지" (H3, 20px, SemiBold)
- **접기/펼치기**: 기본 접힌 상태
- **배경**: `#0F0F0F` (약간 더 어두운 배경)
- **텍스트**: Caption (14px), `#B0B0B0`

#### 8. Floating Menu (Bottom Bar)
- **위치**: 화면 하단 고정
- **배경**: `#161616` (블러 효과)
- **높이**: 64px
- **버튼**: [폴더 이동] [삭제]
- **버튼 스타일**: 
  - 폴더 이동: 배경 `#4FD1C5`, 텍스트 `#0A0A0A`
  - 삭제: 배경 `#FF3B30`, 텍스트 `#FFFFFF`

### 5.3 설정 화면 (Settings)

#### 섹션 구조
```
1. Theme (테마 설정)
2. Management (관리)
3. System (시스템)
4. About (정보)
```

#### 설정 항목 스타일
- **배경**: `#161616`
- **구분선**: 1px solid `#2A2A2A`
- **제목**: Body (16px, Regular), `#F2F2F2`
- **설명**: Caption (14px), `#8E8E93`
- **스위치**: 활성 시 `#4FD1C5`

#### Theme 섹션
- **옵션**: Dark / Light / System
- **선택 표시**: 체크마크 (`#4FD1C5`)

#### Management 섹션
- **폴더 생성**: '+' 버튼 (`#4FD1C5`)
- **폴더 편집**: 이름 변경, 아이콘 선택
- **폴더 삭제**: 스와이프 액션

#### System 섹션
- **캐시 삭제**: 버튼 스타일, 위험 액션 (빨간색 텍스트)
- **저장 공간**: 진행 바 (`#4FD1C5`)

---

## 6. 인터랙션 (Interactions)

### 6.1 애니메이션
- **기본 duration**: 200ms
- **easing**: cubic-bezier(0.4, 0.0, 0.2, 1)
- **페이드**: opacity 0 → 1
- **슬라이드**: translateY(20px) → 0

### 6.2 호버 상태
- **카드**: 배경 약간 밝아짐 + 그림자 증가
- **버튼**: 배경 10% 밝아짐
- **링크**: 밑줄 표시

### 6.3 터치 피드백
- **버튼**: 눌렀을 때 scale(0.95)
- **카드**: 눌렀을 때 opacity 0.8

---

## 7. 아이콘 시스템 (Icons)

### 7.1 아이콘 스타일
- **스타일**: Outlined (선 기반)
- **크기**: 24px (기본), 20px (작은 아이콘), 16px (인라인)
- **선 두께**: 2px
- **컬러**: `#F2F2F2` (기본), `#4FD1C5` (강조)

### 7.2 주요 아이콘
- **홈**: 집 아이콘
- **검색**: 돋보기
- **설정**: 톱니바퀴
- **추가**: '+' 원형
- **폴더**: 폴더 아이콘
- **즐겨찾기**: 별 (채워진/빈)
- **삭제**: 휴지통
- **편집**: 연필
- **공유**: 공유 아이콘

---

## 8. 이미지 처리 (Image Handling)

### 8.1 썸네일
- **비율**: 16:9 또는 1:1 (카드 스타일에 따라)
- **모서리**: 8px border-radius
- **로딩**: 스켈레톤 UI (`#161616` 배경)

### 8.2 전체 화면 이미지
- **배경**: `#000000` (완전한 검정)
- **확대/축소**: 핀치 제스처 지원
- **닫기**: 상단 'X' 버튼 (`#FFFFFF`)

---

## 9. 다크/라이트 모드 전환 (Theme Switching)

### 9.1 전환 규칙
- **시스템 설정 연동**: OS 설정 자동 감지
- **수동 전환**: 설정에서 Dark / Light / System 선택
- **애니메이션**: 부드러운 컬러 전환 (300ms)

### 9.2 컬러 매핑
| 요소 | 다크 모드 | 라이트 모드 |
|------|-----------|-------------|
| Background | `#0A0A0A` | `#F8F9FA` |
| Surface | `#161616` | `#FFFFFF` |
| Accent | `#4FD1C5` | `#38B2AC` |
| Text High | `#F2F2F2` | `#1A1A1A` |
| Text Low | `#8E8E93` | `#636366` |

---

## 10. 접근성 (Accessibility)

### 10.1 대비율
- **텍스트**: 최소 4.5:1 (WCAG AA)
- **큰 텍스트**: 최소 3:1
- **UI 요소**: 최소 3:1

### 10.2 터치 타겟
- **최소 크기**: 44x44px (iOS 기준)
- **간격**: 최소 8px

### 10.3 다크 모드 고려사항
- **눈의 피로 감소**: 낮은 밝기 유지
- **OLED 최적화**: 순수 검정 사용 (`#000000`)

---

## 11. 디자인 체크리스트

새로운 화면이나 컴포넌트를 디자인할 때 다음을 확인하세요:

- [ ] 시그니처 티알 컬러 (`#4FD1C5`) 사용
- [ ] 다크 모드 우선 디자인
- [ ] 타이포그래피 위계 준수
- [ ] 스페이싱 스케일 적용 (4px 배수)
- [ ] 12px border-radius (카드)
- [ ] 접근성 대비율 확인
- [ ] 터치 타겟 크기 확인 (44x44px)
- [ ] 애니메이션 duration 200ms
- [ ] 아이콘 크기 24px (기본)
- [ ] 라이트 모드 호환성 확인

---

## 12. 참고 자료

### 12.1 디자인 도구
- **Figma**: UI 디자인 및 프로토타입
- **ColorSlurp**: 컬러 피커
- **SF Symbols**: iOS 아이콘 라이브러리

### 12.2 영감 소스
- **Apple Human Interface Guidelines**: iOS 디자인 원칙
- **Material Design**: 컴포넌트 패턴
- **Dribbble**: 다크 모드 UI 트렌드

---

*Last Updated: 2026-01-24*  
*Version: 1.0*  
*Author: Komjirak.Studio*
