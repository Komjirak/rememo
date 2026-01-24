// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Rememo';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonCreate => '생성';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonClose => '닫기';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonEdit => '편집';

  @override
  String get commonError => '오류';

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
  String get emptyMemories => '메모가 없습니다.';

  @override
  String get emptyFilter => '조건에 맞는 메모가 없습니다.';

  @override
  String get sheetNewMemory => '새 메모';

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
  String get detailSource => '출처';

  @override
  String get detailTags => '태그';

  @override
  String get detailTitleEdit => '제목 편집';

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
  String get tagAiAnalysis => 'AI 분석';

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
  String get msgDeleteConfirm => '이 메모를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get msgShareComingSoon => '공유 기능은 준비 중입니다.';

  @override
  String get folderSelect => '폴더 선택';

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
  String get settingsDarkMode => '다크 모드';

  @override
  String get settingsOrganization => '관리';

  @override
  String get settingsData => '데이터';

  @override
  String get settingsClearCache => '캐시 삭제';

  @override
  String get settingsStorageUsed => '사용된 저장 공간';

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
  String get msgCacheClearDesc =>
      '캐시를 삭제하면 모든 임시 이미지가 제거됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get errUrlLaunch => '웹사이트를 열 수 없습니다.';

  @override
  String get msgCacheClearTitle => '캐시 삭제';

  @override
  String get msgCacheClearConfirm => '임시 파일들을 삭제하시겠습니까? 원본 데이터는 유지됩니다.';

  @override
  String get msgCacheCleared => '캐시가 삭제되었습니다';
}
