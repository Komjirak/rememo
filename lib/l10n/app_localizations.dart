import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'Rememo'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @commonCreate.
  ///
  /// In ko, this message translates to:
  /// **'생성'**
  String get commonCreate;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// No description provided for @commonEdit.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get commonEdit;

  /// No description provided for @commonError.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get commonError;

  /// No description provided for @commonNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get commonNone;

  /// No description provided for @commonColor.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get commonColor;

  /// No description provided for @commonMove.
  ///
  /// In ko, this message translates to:
  /// **'이동'**
  String get commonMove;

  /// No description provided for @filterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get filterAll;

  /// No description provided for @filterFavorite.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get filterFavorite;

  /// No description provided for @filterFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더'**
  String get filterFolder;

  /// No description provided for @filterType.
  ///
  /// In ko, this message translates to:
  /// **'타입'**
  String get filterType;

  /// No description provided for @typeScreenshot.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷'**
  String get typeScreenshot;

  /// No description provided for @typeUrl.
  ///
  /// In ko, this message translates to:
  /// **'URL'**
  String get typeUrl;

  /// No description provided for @typePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get typePhoto;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'메모 검색...'**
  String get searchHint;

  /// No description provided for @searchNoResult.
  ///
  /// In ko, this message translates to:
  /// **'\"{query}\"에 대한 결과를 찾을 수 없습니다.'**
  String searchNoResult(Object query);

  /// No description provided for @emptyMemories.
  ///
  /// In ko, this message translates to:
  /// **'메모가 없습니다.'**
  String get emptyMemories;

  /// No description provided for @emptyFilter.
  ///
  /// In ko, this message translates to:
  /// **'조건에 맞는 메모가 없습니다.'**
  String get emptyFilter;

  /// No description provided for @sheetNewMemory.
  ///
  /// In ko, this message translates to:
  /// **'새 메모'**
  String get sheetNewMemory;

  /// No description provided for @sheetImportScreenshot.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷 가져오기'**
  String get sheetImportScreenshot;

  /// No description provided for @sheetTakePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 촬영'**
  String get sheetTakePhoto;

  /// No description provided for @sheetImportGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 가져오기'**
  String get sheetImportGallery;

  /// No description provided for @sheetPasteUrl.
  ///
  /// In ko, this message translates to:
  /// **'URL 붙여넣기'**
  String get sheetPasteUrl;

  /// No description provided for @detailHeader.
  ///
  /// In ko, this message translates to:
  /// **'REMEMO INSIGHT'**
  String get detailHeader;

  /// No description provided for @detailAiSummary.
  ///
  /// In ko, this message translates to:
  /// **'AI 요약'**
  String get detailAiSummary;

  /// No description provided for @detailPersonalNote.
  ///
  /// In ko, this message translates to:
  /// **'개인 메모'**
  String get detailPersonalNote;

  /// No description provided for @detailPersonalNoteHint.
  ///
  /// In ko, this message translates to:
  /// **'생각을 남겨보세요...'**
  String get detailPersonalNoteHint;

  /// No description provided for @detailOriginalMessage.
  ///
  /// In ko, this message translates to:
  /// **'원본 메시지'**
  String get detailOriginalMessage;

  /// No description provided for @detailSource.
  ///
  /// In ko, this message translates to:
  /// **'출처'**
  String get detailSource;

  /// No description provided for @detailTags.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get detailTags;

  /// No description provided for @detailTitleEdit.
  ///
  /// In ko, this message translates to:
  /// **'제목 편집'**
  String get detailTitleEdit;

  /// No description provided for @detailTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'제목 입력'**
  String get detailTitleHint;

  /// No description provided for @tagAiAnalysis.
  ///
  /// In ko, this message translates to:
  /// **'AI 분석'**
  String get tagAiAnalysis;

  /// No description provided for @menuFavorite.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get menuFavorite;

  /// No description provided for @menuMoveFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더로 이동'**
  String get menuMoveFolder;

  /// No description provided for @menuDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get menuDelete;

  /// No description provided for @msgFavoriteAdded.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에 추가되었습니다'**
  String get msgFavoriteAdded;

  /// No description provided for @msgFavoriteRemoved.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에서 제거되었습니다'**
  String get msgFavoriteRemoved;

  /// No description provided for @msgDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모 삭제'**
  String get msgDeleteTitle;

  /// No description provided for @msgDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 메모를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'**
  String get msgDeleteConfirm;

  /// No description provided for @msgShareComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'공유 기능은 준비 중입니다.'**
  String get msgShareComingSoon;

  /// No description provided for @folderSelect.
  ///
  /// In ko, this message translates to:
  /// **'폴더 선택'**
  String get folderSelect;

  /// No description provided for @folderNew.
  ///
  /// In ko, this message translates to:
  /// **'새 폴더'**
  String get folderNew;

  /// No description provided for @folderNameHint.
  ///
  /// In ko, this message translates to:
  /// **'폴더 이름'**
  String get folderNameHint;

  /// No description provided for @folderManage.
  ///
  /// In ko, this message translates to:
  /// **'폴더 관리'**
  String get folderManage;

  /// No description provided for @folderCreateEdit.
  ///
  /// In ko, this message translates to:
  /// **'폴더 생성 및 편집'**
  String get folderCreateEdit;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In ko, this message translates to:
  /// **'화면 설정'**
  String get settingsAppearance;

  /// No description provided for @settingsDarkMode.
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get settingsDarkMode;

  /// No description provided for @settingsOrganization.
  ///
  /// In ko, this message translates to:
  /// **'관리'**
  String get settingsOrganization;

  /// No description provided for @settingsData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get settingsData;

  /// No description provided for @settingsClearCache.
  ///
  /// In ko, this message translates to:
  /// **'캐시 삭제'**
  String get settingsClearCache;

  /// No description provided for @settingsStorageUsed.
  ///
  /// In ko, this message translates to:
  /// **'사용된 저장 공간'**
  String get settingsStorageUsed;

  /// No description provided for @settingsInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get settingsInfo;

  /// No description provided for @settingsVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get settingsVersion;

  /// No description provided for @settingsTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get settingsThemeSystem;

  /// No description provided for @commonLoading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get commonLoading;

  /// No description provided for @msgCacheClearDesc.
  ///
  /// In ko, this message translates to:
  /// **'캐시를 삭제하면 모든 임시 이미지가 제거됩니다. 이 작업은 되돌릴 수 없습니다.'**
  String get msgCacheClearDesc;

  /// No description provided for @errUrlLaunch.
  ///
  /// In ko, this message translates to:
  /// **'웹사이트를 열 수 없습니다.'**
  String get errUrlLaunch;

  /// No description provided for @msgCacheClearTitle.
  ///
  /// In ko, this message translates to:
  /// **'캐시 삭제'**
  String get msgCacheClearTitle;

  /// No description provided for @msgCacheClearConfirm.
  ///
  /// In ko, this message translates to:
  /// **'임시 파일들을 삭제하시겠습니까? 원본 데이터는 유지됩니다.'**
  String get msgCacheClearConfirm;

  /// No description provided for @msgCacheCleared.
  ///
  /// In ko, this message translates to:
  /// **'캐시가 삭제되었습니다'**
  String get msgCacheCleared;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
