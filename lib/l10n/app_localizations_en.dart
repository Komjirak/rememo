// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

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
  String get emptyFilter => 'No memories match your filter.';

  @override
  String get emptyStateTitle => 'Your memory starts here';

  @override
  String get emptyStateDescription =>
      'Capture screenshots anywhere and Rememo will automatically turn them into organized, searchable knowledge.';

  @override
  String get emptyStateAction => 'Add your first memory';

  @override
  String get emptyStateLearnMore => 'Learn how it works';

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
  String get detailKeyInsights => 'KEY POINTS';

  @override
  String get detailShowMore => 'Show all';

  @override
  String get detailShowLess => 'Collapse';

  @override
  String get detailAddNote => 'Add a note';

  @override
  String get detailTranslate => 'Translate';

  @override
  String get detailShowOriginal => 'Show original';

  @override
  String get detailShowTranslation => 'Show translation';

  @override
  String get msgCopied => 'Copied to clipboard';

  @override
  String get msgTranslationDone => 'Translation complete.';

  @override
  String get msgTranslationNotNeeded =>
      'Translation not needed or language not supported.';

  @override
  String get msgTranslationFailed => 'Translation failed.';

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
  String msgDeleteConfirm(Object title) {
    return 'Delete \"$title\"? This action cannot be undone.';
  }

  @override
  String msgMemoDeleted(Object title) {
    return '\"$title\" deleted';
  }

  @override
  String get folderNew => 'New Folder';

  @override
  String get folderNameHint => 'Folder Name';

  @override
  String get folderManage => 'Manage Folders';

  @override
  String get folderCreateEdit => 'Create & Edit folders';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsOrganization => 'Organization';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsClearCache => 'Clear All Data';

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
      'Permanently deletes all saved memories and images from this device.';

  @override
  String get errUrlLaunch => 'Could not open website.';

  @override
  String get msgClearAllDataTitle => 'Clear All Data?';

  @override
  String msgClearAllDataConfirm(Object count) {
    return 'This will permanently delete $count items. This action cannot be undone.';
  }

  @override
  String get msgAllDataCleared => '✅ All data cleared';

  @override
  String get commonTest => 'Test';

  @override
  String get folderEditTitle => 'Edit Folder';

  @override
  String get folderNameInputHint => 'Enter folder name';

  @override
  String get folderColorLabel => 'Folder Color';

  @override
  String get folderEmptyTitle => 'No folders yet';

  @override
  String get folderEmptyHint => 'Tap the + button to create a new folder';

  @override
  String folderItemCount(Object count) {
    return '$count items';
  }

  @override
  String get msgFolderNameRequired => 'Please enter a folder name';

  @override
  String get msgFolderDeleteTitle => 'Delete Folder';

  @override
  String msgFolderDeleteConfirm(Object name) {
    return 'Delete the folder \"$name\"?\nMemos inside will be kept and become unassigned.';
  }

  @override
  String msgFolderDeleted(Object name) {
    return '\"$name\" deleted';
  }

  @override
  String get sheetImportImageSubtitleDesktop => 'Add image from library';

  @override
  String get sheetImportImageSubtitleMobile => 'Analyze latest capture';

  @override
  String get sheetTakePhotoSubtitleDesktop => 'Choose from files';

  @override
  String get sheetTakePhotoSubtitleMobile => 'Take a new photo';

  @override
  String get sheetPasteUrlSubtitle => 'Save link from clipboard';

  @override
  String get analysisEmptyTitle => 'Empty Screenshot';

  @override
  String get analysisEmptyText => 'No text detected.';

  @override
  String get analysisSavedText => 'Screenshot saved.';

  @override
  String get msgWebLinkSaved => 'Web link saved.';

  @override
  String get msgSharedContentSaved => 'Shared content saved.';

  @override
  String msgSharedItemsSaved(Object count) {
    return '📥 $count shared items saved!';
  }

  @override
  String msgSharedItemsError(Object error) {
    return 'Error processing shared items: $error';
  }

  @override
  String get msgClipboardEmpty => 'Clipboard is empty.';

  @override
  String get msgInvalidUrl => 'Not a valid URL.';

  @override
  String get msgLinkSaved => '🔗 Link saved!';

  @override
  String msgUrlProcessError(Object error) {
    return 'An error occurred while processing the URL: $error';
  }

  @override
  String msgMemoCreated(Object title) {
    return '✨ Memo created: $title';
  }

  @override
  String msgAnalysisFailed(Object error) {
    return 'Analysis failed: $error';
  }

  @override
  String get msgTitleUpdated => 'Title updated';

  @override
  String get errNoScreenshotFound => 'No screenshot found.';

  @override
  String get splashTagline => 'YOUR AI MEMORY';

  @override
  String get settingsAISectionHeader => 'AI ANALYSIS';

  @override
  String get titleWebLink => 'Web Link';

  @override
  String get titleNewItem => 'New Item';

  @override
  String get titleNewMemo => 'New Memo';

  @override
  String settingsOpenAIActive(Object model) {
    return 'Active • $model';
  }

  @override
  String get settingsOpenAIKeyNeeded => 'Set up your API Key';

  @override
  String get settingsConfigured => 'Configured';

  @override
  String get settingsConfigNeeded => 'Setup needed';

  @override
  String get settingsModelLabel => 'Model';

  @override
  String get settingsModelSelectTitle => 'Select Model';

  @override
  String get settingsVisionLabel => 'Image Analysis (Vision)';

  @override
  String get settingsVisionDescription =>
      'Send a low-res copy of the screenshot to improve analysis quality';

  @override
  String get settingsOpenAIPrivacyNotice =>
      'Using the OpenAI API greatly improves AI summary quality for screenshots and URLs. Your API Key is stored only in the device\'s secure storage (Keychain).\n\n⚠️ Privacy notice: Turning this on sends captured text (and images, if Vision is enabled) to OpenAI\'s servers for analysis. Turning it off keeps all analysis on-device. Off by default.';

  @override
  String get settingsApiKeyHelpText =>
      'You can get an API Key at platform.openai.com.';

  @override
  String get settingsDeleteExistingKey => 'Delete Existing Key';

  @override
  String get msgConnectionSuccess => '✅ Connected successfully!';

  @override
  String get msgConnectionFailed => '❌ Connection failed. Check your key.';

  @override
  String get msgApiKeyDeleted => '🗑️ API Key deleted';

  @override
  String get msgApiKeySaved => '✅ API Key saved';

  @override
  String get settingsExportObsidian => 'Export to Obsidian';

  @override
  String get settingsExportObsidianDesc =>
      'Converts all memos into Markdown (.md) files and exports them as a zip. Save to your Vault folder in iCloud Drive to sync automatically with your PC.';

  @override
  String get msgExportPreparing => 'Preparing files to export...';

  @override
  String get msgExportEmpty => 'No memories to export.';

  @override
  String msgExportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get exportPeriodTitle => 'Select period to export';

  @override
  String get exportPeriodAll => 'All';

  @override
  String get exportPeriodLast7Days => 'Last 7 days';

  @override
  String get exportPeriodLast30Days => 'Last 30 days';

  @override
  String get exportPeriodLast90Days => 'Last 90 days';

  @override
  String get settingsAutoExport => 'Auto Export';

  @override
  String get settingsVaultFolder => 'Vault Folder';

  @override
  String get settingsVaultFolderNotSet => 'Not set';

  @override
  String get settingsAutoExportToggle => 'Auto Export';

  @override
  String get settingsRunAutoExportNow => 'Export Now';

  @override
  String get settingsAutoExportNeverRun => 'Never run yet';

  @override
  String settingsAutoExportLastRun(Object date) {
    return 'Last run: $date';
  }

  @override
  String get settingsAutoExportDesc =>
      'Automatically writes new memos to your Vault folder once the selected interval has passed. iOS does not guarantee exact timing — it decides based on your usage pattern, so opening the app regularly makes it more reliable.';

  @override
  String get msgSelectFolderFirst => 'Please select a Vault folder first.';

  @override
  String get settingsAutoExportFrequencyTitle => 'Select export frequency';

  @override
  String get msgAutoExportSuccess => '✅ Export complete';

  @override
  String get msgAutoExportFailed =>
      'Export failed. Please check folder access permission.';

  @override
  String get autoExportFrequencyDaily => 'Daily';

  @override
  String get autoExportFrequencyWeekly => 'Weekly';

  @override
  String get autoExportFrequencyMonthly => 'Monthly';
}
