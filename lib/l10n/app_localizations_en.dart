// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rememo';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonError => 'Error';

  @override
  String get commonNone => 'None';

  @override
  String get commonColor => 'Color';

  @override
  String get commonMove => 'Move';

  @override
  String get filterAll => 'All';

  @override
  String get filterFavorite => 'Favorite';

  @override
  String get filterFolder => 'Folder';

  @override
  String get filterType => 'Type';

  @override
  String get typeScreenshot => 'SCREENSHOT';

  @override
  String get typeUrl => 'URL';

  @override
  String get typePhoto => 'PHOTO';

  @override
  String get searchHint => 'Search memories...';

  @override
  String searchNoResult(Object query) {
    return 'No results found for \"$query\".';
  }

  @override
  String get emptyMemories => 'No memories yet.';

  @override
  String get emptyFilter => 'No memories match your filter.';

  @override
  String get sheetNewMemory => 'New Memory';

  @override
  String get sheetImportScreenshot => 'Import Screenshot';

  @override
  String get sheetTakePhoto => 'Take Photo';

  @override
  String get sheetImportGallery => 'Import from Gallery';

  @override
  String get sheetPasteUrl => 'Paste URL';

  @override
  String get detailHeader => 'REMEMO INSIGHT';

  @override
  String get detailAiSummary => 'AI SUMMARY';

  @override
  String get detailPersonalNote => 'PERSONAL NOTE';

  @override
  String get detailPersonalNoteHint => 'Add your thoughts...';

  @override
  String get detailOriginalMessage => 'ORIGINAL MESSAGE';

  @override
  String get detailSource => 'Source';

  @override
  String get detailTags => 'TAGS';

  @override
  String get detailTitleEdit => 'Edit Title';

  @override
  String get detailTitleHint => 'Enter title';

  @override
  String get detailEditTitle => 'Edit Title';

  @override
  String get detailEditSummary => 'Edit Summary';

  @override
  String get detailEditNote => 'Edit Note';

  @override
  String get detailSummaryHint => 'Write your summary...';

  @override
  String get tagAiAnalysis => 'AI Analysis';

  @override
  String get menuFavorite => 'Favorite';

  @override
  String get menuMoveFolder => 'Move to Folder';

  @override
  String get menuDelete => 'Delete';

  @override
  String get msgFavoriteAdded => 'Added to favorites';

  @override
  String get msgFavoriteRemoved => 'Removed from favorites';

  @override
  String get msgDeleteTitle => 'Delete Memory';

  @override
  String get msgDeleteConfirm =>
      'Are you sure you want to delete this memory? This action cannot be undone.';

  @override
  String get msgShareComingSoon => 'Share functionality coming soon.';

  @override
  String get folderSelect => 'Select Folder';

  @override
  String get folderNew => 'New Folder';

  @override
  String get folderNameHint => 'Folder Name';

  @override
  String get folderManage => 'Manage Folders';

  @override
  String get folderCreateEdit => 'Create & Edit folders';

  @override
  String get settingsTitle => 'Data';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsOrganization => 'Organization';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsClearCache => 'Clear Cache';

  @override
  String get settingsStorageUsed => 'Storage Used';

  @override
  String get settingsInfo => 'Info';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get msgCacheClearDesc =>
      'Clearing cache will remove all temporary images. This action cannot be undone.';

  @override
  String get errUrlLaunch => 'Could not open website.';

  @override
  String get msgCacheClearTitle => 'Clear Cache';

  @override
  String get msgCacheClearConfirm =>
      'Are you sure you want to clear temporary files? Original data will safely remain.';

  @override
  String get msgCacheCleared => 'Cache cleared';
}
