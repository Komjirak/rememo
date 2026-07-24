// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonSave => '保存';

  @override
  String get commonCreate => '作成';

  @override
  String get commonDelete => '削除';

  @override
  String get commonEdit => '編集';

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
  String get emptyFilter => '条件に一致するメモがありません。';

  @override
  String get emptyStateTitle => 'ここから記憶が始まります';

  @override
  String get emptyStateDescription =>
      'どこでもスクリーンショットを撮るだけで、Rememoが自動的に整理し、検索できるナレッジに変えます。';

  @override
  String get emptyStateAction => '最初のメモを追加';

  @override
  String get emptyStateLearnMore => '使い方を見る';

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
  String get detailKeyInsights => 'キーポイント';

  @override
  String get detailShowMore => 'すべて表示';

  @override
  String get detailShowLess => '折りたたむ';

  @override
  String get detailAddNote => 'メモを追加';

  @override
  String get detailTranslate => '翻訳';

  @override
  String get detailShowOriginal => '原文を表示';

  @override
  String get detailShowTranslation => '翻訳を表示';

  @override
  String get msgCopied => 'コピーしました';

  @override
  String get msgTranslationDone => '翻訳が完了しました。';

  @override
  String get msgTranslationNotNeeded => '翻訳が不要か、サポートされていない言語です。';

  @override
  String get msgTranslationFailed => '翻訳に失敗しました。';

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
  String msgDeleteConfirm(Object title) {
    return '「$title」を削除してもよろしいですか？この操作は取り消せません。';
  }

  @override
  String msgMemoDeleted(Object title) {
    return '「$title」を削除しました';
  }

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
  String get settingsOrganization => '管理';

  @override
  String get settingsData => 'データ';

  @override
  String get settingsClearCache => 'すべてのデータを削除';

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
  String get msgCacheClearDesc => '保存されたすべてのメモと画像が端末から完全に削除されます。';

  @override
  String get errUrlLaunch => 'ウェブサイトを開けませんでした。';

  @override
  String get msgClearAllDataTitle => 'すべてのデータを削除しますか？';

  @override
  String msgClearAllDataConfirm(Object count) {
    return '$count件のアイテムが完全に削除されます。この操作は取り消せません。';
  }

  @override
  String get msgAllDataCleared => '✅ すべてのデータを削除しました';

  @override
  String get commonTest => 'テスト';

  @override
  String get folderEditTitle => 'フォルダを編集';

  @override
  String get folderNameInputHint => 'フォルダ名を入力';

  @override
  String get folderColorLabel => 'フォルダの色';

  @override
  String get folderEmptyTitle => 'フォルダがありません';

  @override
  String get folderEmptyHint => '+ボタンを押して新しいフォルダを作成してください';

  @override
  String folderItemCount(Object count) {
    return '$count件のアイテム';
  }

  @override
  String get msgFolderNameRequired => 'フォルダ名を入力してください';

  @override
  String get msgFolderDeleteTitle => 'フォルダを削除';

  @override
  String msgFolderDeleteConfirm(Object name) {
    return '「$name」フォルダを削除しますか？\nフォルダ内のメモは保持され、フォルダ未設定の状態になります。';
  }

  @override
  String msgFolderDeleted(Object name) {
    return '「$name」を削除しました';
  }

  @override
  String get sheetImportImageSubtitleDesktop => 'ライブラリから画像を追加';

  @override
  String get sheetImportImageSubtitleMobile => '最新のキャプチャを分析';

  @override
  String get sheetTakePhotoSubtitleDesktop => 'ファイルから選択';

  @override
  String get sheetTakePhotoSubtitleMobile => '新しく写真を撮影';

  @override
  String get sheetPasteUrlSubtitle => 'クリップボードのリンクを保存';

  @override
  String get analysisEmptyTitle => '空のスクリーンショット';

  @override
  String get analysisEmptyText => 'テキストが検出されませんでした。';

  @override
  String get analysisSavedText => 'スクリーンショットを保存しました。';

  @override
  String get msgWebLinkSaved => 'ウェブリンクを保存しました。';

  @override
  String get msgSharedContentSaved => '共有されたコンテンツを保存しました。';

  @override
  String msgSharedItemsSaved(Object count) {
    return '📥 共有された$count件のアイテムを保存しました！';
  }

  @override
  String msgSharedItemsError(Object error) {
    return '共有アイテムの処理中にエラーが発生しました: $error';
  }

  @override
  String get msgClipboardEmpty => 'クリップボードが空です。';

  @override
  String get msgInvalidUrl => '有効なURLではありません。';

  @override
  String get msgLinkSaved => '🔗 リンクを保存しました！';

  @override
  String msgUrlProcessError(Object error) {
    return 'URLの処理中にエラーが発生しました: $error';
  }

  @override
  String msgMemoCreated(Object title) {
    return '✨ メモを作成しました: $title';
  }

  @override
  String msgAnalysisFailed(Object error) {
    return '分析に失敗しました: $error';
  }

  @override
  String get msgTitleUpdated => 'タイトルを更新しました';

  @override
  String get errNoScreenshotFound => 'スクリーンショットが見つかりません。';

  @override
  String get splashTagline => 'あなたのAIメモリー';

  @override
  String get settingsAISectionHeader => 'AI分析';

  @override
  String get titleWebLink => 'ウェブリンク';

  @override
  String get titleNewItem => '新しいアイテム';

  @override
  String get titleNewMemo => '新しいメモ';

  @override
  String settingsOpenAIActive(Object model) {
    return '有効 • $model';
  }

  @override
  String get settingsOpenAIKeyNeeded => 'APIキーを設定してください';

  @override
  String get settingsConfigured => '設定済み';

  @override
  String get settingsConfigNeeded => '設定が必要';

  @override
  String get settingsModelLabel => 'モデル';

  @override
  String get settingsModelSelectTitle => 'モデルを選択';

  @override
  String get settingsVisionLabel => '画像分析（Vision）';

  @override
  String get settingsVisionDescription => 'スクリーンショットを低解像度で一緒に送信し、分析品質を向上';

  @override
  String get settingsOpenAIPrivacyNotice =>
      'OpenAI APIを使用すると、スクリーンショットとURLのAI要約品質が大幅に向上します。APIキーは端末のセキュアストレージ（Keychain）にのみ保存されます。\n\n⚠️ プライバシーについて: この機能をオンにすると、キャプチャしたテキスト（Vision有効時は画像も）が分析のためOpenAIサーバーに送信されます。オフにするとすべての分析は端末内でのみ行われます。デフォルトはオフです。';

  @override
  String get settingsApiKeyHelpText => 'platform.openai.comでAPIキーを取得できます。';

  @override
  String get settingsDeleteExistingKey => '既存のキーを削除';

  @override
  String get msgConnectionSuccess => '✅ 接続に成功しました！';

  @override
  String get msgConnectionFailed => '❌ 接続に失敗しました。キーを確認してください。';

  @override
  String get msgApiKeyDeleted => '🗑️ APIキーを削除しました';

  @override
  String get msgApiKeySaved => '✅ APIキーを保存しました';

  @override
  String get settingsExportObsidian => 'Obsidianにエクスポート';

  @override
  String get settingsExportObsidianDesc =>
      'すべてのメモをMarkdown（.md）ファイルに変換してzipで書き出します。保存先にiCloud DriveのVaultフォルダを選ぶと、PCと自動的に同期されます。';

  @override
  String get msgExportPreparing => '書き出すファイルを準備しています...';

  @override
  String get msgExportEmpty => '書き出すメモがありません。';

  @override
  String msgExportFailed(Object error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get exportPeriodTitle => '書き出す期間を選択';

  @override
  String get exportPeriodAll => 'すべて';

  @override
  String get exportPeriodLast7Days => '過去7日間';

  @override
  String get exportPeriodLast30Days => '過去30日間';

  @override
  String get exportPeriodLast90Days => '過去90日間';

  @override
  String get settingsAutoExport => '自動エクスポート';

  @override
  String get settingsVaultFolder => 'Vaultフォルダ';

  @override
  String get settingsVaultFolderNotSet => '未設定';

  @override
  String get settingsAutoExportToggle => '自動エクスポート';

  @override
  String get settingsRunAutoExportNow => '今すぐエクスポート';

  @override
  String get settingsAutoExportNeverRun => 'まだ実行されていません';

  @override
  String settingsAutoExportLastRun(Object date) {
    return '最終実行: $date';
  }

  @override
  String get settingsAutoExportDesc =>
      '選択した間隔が経過すると、新しいメモをVaultフォルダに自動で書き込みます。iOSは正確な実行時刻を保証せず、使用状況に応じて判断します — アプリをこまめに開くほど安定して動作します。';

  @override
  String get msgSelectFolderFirst => '先にVaultフォルダを選択してください。';

  @override
  String get settingsAutoExportFrequencyTitle => 'エクスポート頻度を選択';

  @override
  String get msgAutoExportSuccess => '✅ エクスポート完了';

  @override
  String get msgAutoExportFailed => 'エクスポートに失敗しました。フォルダへのアクセス権限をご確認ください。';

  @override
  String get autoExportFrequencyDaily => '毎日';

  @override
  String get autoExportFrequencyWeekly => '毎週';

  @override
  String get autoExportFrequencyMonthly => '毎月';
}
