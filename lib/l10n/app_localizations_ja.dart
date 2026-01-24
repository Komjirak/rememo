// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Rememo';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonSave => '保存';

  @override
  String get commonCreate => '作成';

  @override
  String get commonDelete => '削除';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonEdit => '編集';

  @override
  String get commonError => 'エラー';

  @override
  String get commonNone => 'なし';

  @override
  String get commonColor => 'カラー';

  @override
  String get commonMove => '移動';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterFavorite => 'お気に入り';

  @override
  String get filterFolder => 'フォルダ';

  @override
  String get filterType => 'タイプ';

  @override
  String get typeScreenshot => 'スクリーンショット';

  @override
  String get typeUrl => 'URL';

  @override
  String get typePhoto => '写真';

  @override
  String get searchHint => 'メモを検索...';

  @override
  String searchNoResult(Object query) {
    return '\"$query\" の検索結果はありません。';
  }

  @override
  String get emptyMemories => 'メモがありません。';

  @override
  String get emptyFilter => '条件に一致するメモがありません。';

  @override
  String get sheetNewMemory => '新しいメモ';

  @override
  String get sheetImportScreenshot => 'スクリーンショットをインポート';

  @override
  String get sheetTakePhoto => '写真を撮る';

  @override
  String get sheetImportGallery => 'ギャラリーからインポート';

  @override
  String get sheetPasteUrl => 'URLを貼り付け';

  @override
  String get detailHeader => 'REMEMO INSIGHT';

  @override
  String get detailAiSummary => 'AI概要';

  @override
  String get detailPersonalNote => 'パーソナルメモ';

  @override
  String get detailPersonalNoteHint => '考えを入力してください...';

  @override
  String get detailOriginalMessage => 'オリジナルメッセージ';

  @override
  String get detailSource => 'ソース';

  @override
  String get detailTags => 'タグ';

  @override
  String get detailTitleEdit => 'タイトルの編集';

  @override
  String get detailTitleHint => 'タイトルを入力';

  @override
  String get detailEditTitle => 'タイトルの編集';

  @override
  String get detailEditSummary => '要約の編集';

  @override
  String get detailEditNote => 'メモの編集';

  @override
  String get detailSummaryHint => '要約を入力してください...';

  @override
  String get tagAiAnalysis => 'AI分析';

  @override
  String get menuFavorite => 'お気に入り';

  @override
  String get menuMoveFolder => 'フォルダへ移動';

  @override
  String get menuDelete => '削除';

  @override
  String get msgFavoriteAdded => 'お気に入りに追加しました';

  @override
  String get msgFavoriteRemoved => 'お気に入りを解除しました';

  @override
  String get msgDeleteTitle => 'メモの削除';

  @override
  String get msgDeleteConfirm => 'このメモを削除してもよろしいですか？この操作は取り消せません。';

  @override
  String get msgShareComingSoon => '共有機能は準備中です。';

  @override
  String get folderSelect => 'フォルダ選択';

  @override
  String get folderNew => '新しいフォルダ';

  @override
  String get folderNameHint => 'フォルダ名';

  @override
  String get folderManage => 'フォルダ管理';

  @override
  String get folderCreateEdit => 'フォルダの作成と編集';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsAppearance => '画面設定';

  @override
  String get settingsDarkMode => 'ダークモード';

  @override
  String get settingsOrganization => '管理';

  @override
  String get settingsData => 'データ';

  @override
  String get settingsClearCache => 'キャッシュ削除';

  @override
  String get settingsStorageUsed => '使用中のストレージ';

  @override
  String get settingsInfo => '情報';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get commonLoading => '読み込み中...';

  @override
  String get msgCacheClearDesc => 'キャッシュをクリアすると、すべての一時画像が削除されます。この操作は取り消せません。';

  @override
  String get errUrlLaunch => 'ウェブサイトを開けませんでした。';

  @override
  String get msgCacheClearTitle => 'キャッシュ削除';

  @override
  String get msgCacheClearConfirm => '一時ファイルを削除してもよろしいですか？元のデータは保持されます。';

  @override
  String get msgCacheCleared => 'キャッシュが削除されました';
}
