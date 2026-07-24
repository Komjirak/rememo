// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonCreate => '생성';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonEdit => '편집';

  @override
  String get commonNone => '없음';

  @override
  String get commonColor => '색상';

  @override
  String get commonMove => '이동';

  @override
  String get filterAll => '전체';

  @override
  String get filterFavorite => '즐겨찾기';

  @override
  String get filterFolder => '폴더';

  @override
  String get filterType => '타입';

  @override
  String get typeScreenshot => '스크린샷';

  @override
  String get typeUrl => 'URL';

  @override
  String get typePhoto => '사진';

  @override
  String get searchHint => '메모 검색...';

  @override
  String searchNoResult(Object query) {
    return '\"$query\"에 대한 결과를 찾을 수 없습니다.';
  }

  @override
  String get emptyFilter => '조건에 맞는 메모가 없습니다.';

  @override
  String get emptyStateTitle => '여기서 기억이 시작돼요';

  @override
  String get emptyStateDescription =>
      '어디서든 스크린샷을 캡처하면 Rememo가 자동으로 정리하고 검색 가능한 지식으로 만들어드려요.';

  @override
  String get emptyStateAction => '첫 메모 추가하기';

  @override
  String get emptyStateLearnMore => '사용법 알아보기';

  @override
  String get sheetImportScreenshot => '스크린샷 가져오기';

  @override
  String get sheetTakePhoto => '사진 촬영';

  @override
  String get sheetImportGallery => '갤러리에서 가져오기';

  @override
  String get sheetPasteUrl => 'URL 붙여넣기';

  @override
  String get detailHeader => 'REMEMO INSIGHT';

  @override
  String get detailAiSummary => 'AI 요약';

  @override
  String get detailPersonalNote => '개인 메모';

  @override
  String get detailPersonalNoteHint => '생각을 남겨보세요...';

  @override
  String get detailOriginalMessage => '원본 메시지';

  @override
  String get detailTitleHint => '제목 입력';

  @override
  String get detailEditTitle => '제목 편집';

  @override
  String get detailEditSummary => '요약 편집';

  @override
  String get detailEditNote => '메모 편집';

  @override
  String get detailSummaryHint => '요약을 작성하세요...';

  @override
  String get detailKeyInsights => '핵심 포인트';

  @override
  String get detailShowMore => '전체 보기';

  @override
  String get detailShowLess => '접기';

  @override
  String get detailAddNote => '메모 추가';

  @override
  String get detailTranslate => '번역';

  @override
  String get detailShowOriginal => '원본 보기';

  @override
  String get detailShowTranslation => '번역 보기';

  @override
  String get msgCopied => '복사되었습니다';

  @override
  String get msgTranslationDone => '번역이 완료되었습니다.';

  @override
  String get msgTranslationNotNeeded => '번역이 필요하지 않거나 지원되지 않는 언어입니다.';

  @override
  String get msgTranslationFailed => '번역에 실패했습니다.';

  @override
  String get menuFavorite => '즐겨찾기';

  @override
  String get menuMoveFolder => '폴더로 이동';

  @override
  String get menuDelete => '삭제';

  @override
  String get msgFavoriteAdded => '즐겨찾기에 추가되었습니다';

  @override
  String get msgFavoriteRemoved => '즐겨찾기에서 제거되었습니다';

  @override
  String get msgDeleteTitle => '메모 삭제';

  @override
  String msgDeleteConfirm(Object title) {
    return '\'$title\' 메모를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String msgMemoDeleted(Object title) {
    return '$title 삭제됨';
  }

  @override
  String get folderNew => '새 폴더';

  @override
  String get folderNameHint => '폴더 이름';

  @override
  String get folderManage => '폴더 관리';

  @override
  String get folderCreateEdit => '폴더 생성 및 편집';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsAppearance => '화면 설정';

  @override
  String get settingsOrganization => '관리';

  @override
  String get settingsData => '데이터';

  @override
  String get settingsClearCache => '모든 데이터 삭제';

  @override
  String get settingsInfo => '정보';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsThemeSystem => '시스템';

  @override
  String get commonLoading => '로딩 중...';

  @override
  String get msgCacheClearDesc => '저장된 모든 메모와 이미지가 기기에서 영구적으로 삭제됩니다.';

  @override
  String get errUrlLaunch => '웹사이트를 열 수 없습니다.';

  @override
  String get msgClearAllDataTitle => '모든 데이터를 삭제하시겠습니까?';

  @override
  String msgClearAllDataConfirm(Object count) {
    return '$count개 항목이 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get msgAllDataCleared => '✅ 모든 데이터가 삭제되었습니다';

  @override
  String get commonTest => '테스트';

  @override
  String get folderEditTitle => '폴더 편집';

  @override
  String get folderNameInputHint => '폴더 이름 입력';

  @override
  String get folderColorLabel => '폴더 색상';

  @override
  String get folderEmptyTitle => '폴더가 없습니다';

  @override
  String get folderEmptyHint => '+ 버튼을 눌러 새 폴더를 만드세요';

  @override
  String folderItemCount(Object count) {
    return '$count개 항목';
  }

  @override
  String get msgFolderNameRequired => '폴더 이름을 입력하세요';

  @override
  String get msgFolderDeleteTitle => '폴더 삭제';

  @override
  String msgFolderDeleteConfirm(Object name) {
    return '$name 폴더를 삭제하시겠습니까?\n폴더 안의 메모는 유지되며, 폴더가 지정되지 않은 상태로 변경됩니다.';
  }

  @override
  String msgFolderDeleted(Object name) {
    return '$name 삭제됨';
  }

  @override
  String get sheetImportImageSubtitleDesktop => '라이브러리에서 이미지 추가';

  @override
  String get sheetImportImageSubtitleMobile => '가장 최신 캡처 분석';

  @override
  String get sheetTakePhotoSubtitleDesktop => '파일에서 선택';

  @override
  String get sheetTakePhotoSubtitleMobile => '새로운 사진 촬영';

  @override
  String get sheetPasteUrlSubtitle => '클립보드 링크 저장';

  @override
  String get analysisEmptyTitle => '빈 스크린샷';

  @override
  String get analysisEmptyText => '텍스트가 감지되지 않았습니다.';

  @override
  String get analysisSavedText => '스크린샷이 저장되었습니다.';

  @override
  String get msgWebLinkSaved => '웹 링크가 저장되었습니다.';

  @override
  String get msgSharedContentSaved => '공유된 컨텐츠가 저장되었습니다.';

  @override
  String msgSharedItemsSaved(Object count) {
    return '📥 $count개의 공유된 항목이 저장되었습니다!';
  }

  @override
  String msgSharedItemsError(Object error) {
    return '공유된 항목 처리 중 오류: $error';
  }

  @override
  String get msgClipboardEmpty => '클립보드가 비어있습니다.';

  @override
  String get msgInvalidUrl => '유효한 URL이 아닙니다.';

  @override
  String get msgLinkSaved => '🔗 링크가 저장되었습니다!';

  @override
  String msgUrlProcessError(Object error) {
    return 'URL 처리 중 오류가 발생했습니다: $error';
  }

  @override
  String msgMemoCreated(Object title) {
    return '✨ 메모가 생성되었습니다: $title';
  }

  @override
  String msgAnalysisFailed(Object error) {
    return '분석 실패: $error';
  }

  @override
  String get msgTitleUpdated => '제목이 수정되었습니다';

  @override
  String get errNoScreenshotFound => '스크린샷을 찾을 수 없습니다.';

  @override
  String get splashTagline => '당신의 AI 메모리';

  @override
  String get settingsAISectionHeader => 'AI 분석';

  @override
  String get titleWebLink => '웹 링크';

  @override
  String get titleNewItem => '새 항목';

  @override
  String get titleNewMemo => '새 메모';

  @override
  String settingsOpenAIActive(Object model) {
    return '활성화됨 • $model';
  }

  @override
  String get settingsOpenAIKeyNeeded => 'API Key를 설정하세요';

  @override
  String get settingsConfigured => '설정됨';

  @override
  String get settingsConfigNeeded => '설정 필요';

  @override
  String get settingsModelLabel => '모델';

  @override
  String get settingsModelSelectTitle => '모델 선택';

  @override
  String get settingsVisionLabel => '이미지 분석 (Vision)';

  @override
  String get settingsVisionDescription => '스크린샷 이미지를 저해상도로 함께 전송해 분석 품질 향상';

  @override
  String get settingsOpenAIPrivacyNotice =>
      'OpenAI API를 사용하면 스크린샷 및 URL의 AI 요약 품질이 크게 향상됩니다. API Key는 기기의 보안 저장소(Keychain)에만 저장됩니다.\n\n⚠️ 프라이버시 안내: 이 기능을 켜면 캡처한 텍스트(및 Vision 활성 시 이미지)가 분석을 위해 OpenAI 서버로 전송됩니다. 기능을 끄면 모든 분석은 기기 안에서만 수행됩니다. 기본값은 꺼짐입니다.';

  @override
  String get settingsApiKeyHelpText =>
      'platform.openai.com에서 API Key를 발급받을 수 있습니다.';

  @override
  String get settingsDeleteExistingKey => '기존 Key 삭제';

  @override
  String get msgConnectionSuccess => '✅ 연결 성공!';

  @override
  String get msgConnectionFailed => '❌ 연결 실패. Key를 확인하세요.';

  @override
  String get msgApiKeyDeleted => '🗑️ API Key가 삭제되었습니다';

  @override
  String get msgApiKeySaved => '✅ API Key가 저장되었습니다';

  @override
  String get settingsExportObsidian => '옵시디언으로 내보내기';

  @override
  String get settingsExportObsidianDesc =>
      '모든 메모를 마크다운(.md) 파일로 변환해 zip으로 내보냅니다. 저장 위치로 iCloud Drive의 Vault 폴더를 선택하면 PC와 자동으로 동기화됩니다.';

  @override
  String get msgExportPreparing => '내보낼 파일을 준비하는 중...';

  @override
  String get msgExportEmpty => '내보낼 메모가 없습니다.';

  @override
  String msgExportFailed(Object error) {
    return '내보내기 실패: $error';
  }

  @override
  String get exportPeriodTitle => '내보낼 기간 선택';

  @override
  String get exportPeriodAll => '전체';

  @override
  String get exportPeriodLast7Days => '최근 7일';

  @override
  String get exportPeriodLast30Days => '최근 30일';

  @override
  String get exportPeriodLast90Days => '최근 90일';

  @override
  String get settingsAutoExport => '자동 내보내기';

  @override
  String get settingsVaultFolder => 'Vault 폴더';

  @override
  String get settingsVaultFolderNotSet => '선택 안 됨';

  @override
  String get settingsAutoExportToggle => '자동 내보내기';

  @override
  String get settingsRunAutoExportNow => '지금 내보내기';

  @override
  String get settingsAutoExportNeverRun => '아직 실행되지 않음';

  @override
  String settingsAutoExportLastRun(Object date) {
    return '마지막 실행: $date';
  }

  @override
  String get settingsAutoExportDesc =>
      '선택한 주기가 지나면 새 메모를 Vault 폴더에 자동으로 씁니다. iOS는 정확한 실행 시각을 보장하지 않으며, 기기 사용 패턴에 따라 결정합니다 — 앱을 자주 열수록 더 안정적으로 동작합니다.';

  @override
  String get msgSelectFolderFirst => '먼저 Vault 폴더를 선택해주세요.';

  @override
  String get settingsAutoExportFrequencyTitle => '내보내기 주기 선택';

  @override
  String get msgAutoExportSuccess => '✅ 내보내기 완료';

  @override
  String get msgAutoExportFailed => '내보내기 실패. 폴더 접근 권한을 확인해주세요.';

  @override
  String get autoExportFrequencyDaily => '매일';

  @override
  String get autoExportFrequencyWeekly => '매주';

  @override
  String get autoExportFrequencyMonthly => '매월';
}
