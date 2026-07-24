import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:stribe/services/database_helper.dart';
import 'package:stribe/services/obsidian_export_service.dart';
import 'package:stribe/services/obsidian_folder_channel.dart';
import 'package:stribe/utils/app_logger.dart';

/// iOS 백그라운드 작업(BGAppRefreshTask)에 등록하는 고유 식별자.
/// AppDelegate.swift의 BGTaskSchedulerPermittedIdentifiers와 정확히 일치해야 한다.
const String obsidianAutoExportTaskId = 'com.rememo.komjirak.obsidianAutoExport';

/// "옵시디언 자동 내보내기" 설정/스케줄링/실행을 담당한다.
///
/// iOS의 BGTaskScheduler는 "정확히 매일/매주/매월" 실행을 보장하지 않는다
/// (기기 사용 패턴·배터리·충전 상태에 따라 iOS가 실행 시점을 결정한다).
/// 그래서 네이티브에는 비교적 자주(4시간 간격) "확인하러 오는" 것만 요청해두고,
/// 실제로 내보낼지 여부는 여기서 "마지막 성공 시각 + 사용자가 고른 주기"를
/// 기준으로 판단한다 — 이렇게 하면 실제 내보내기 빈도는 사용자가 고른 주기에
/// 가깝게 유지되면서도, iOS가 드물게만 깨워주는 상황에도 안전하게 동작한다.
class ObsidianAutoExportService {
  static const _keyEnabled = 'obsidian_auto_export_enabled';
  static const _keyFrequencyDays = 'obsidian_auto_export_frequency_days';
  static const _keyLastRunMillis = 'obsidian_auto_export_last_run_millis';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  /// 저장된 주기(일). 설정된 적 없으면 7일(매주) 기본값.
  static Future<int> frequencyDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFrequencyDays) ?? 7;
  }

  static Future<DateTime?> lastRunAt() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_keyLastRunMillis);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// 자동 내보내기를 켜고 주기를 저장한 뒤, 백그라운드 작업을 등록한다.
  static Future<void> enable({required int frequencyDays}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, true);
    await prefs.setInt(_keyFrequencyDays, frequencyDays);

    await Workmanager().registerPeriodicTask(
      obsidianAutoExportTaskId,
      obsidianAutoExportTaskId,
      initialDelay: const Duration(minutes: 5),
    );
    logInfo('✅ 자동 내보내기 활성화 (주기: $frequencyDays일)', name: 'ObsidianAutoExport');
  }

  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);
    await Workmanager().cancelByUniqueName(obsidianAutoExportTaskId);
    logInfo('⏸️ 자동 내보내기 비활성화', name: 'ObsidianAutoExport');
  }

  /// 마지막 실행 이후 설정된 주기가 지났으면 실행하고 성공 시각을 기록한다.
  /// 백그라운드 콜백 디스패처에서 호출된다.
  static Future<void> runIfDue() async {
    if (!await isEnabled()) return;
    if (!await ObsidianFolderChannel.hasFolder()) return;

    final last = await lastRunAt();
    final days = await frequencyDays();
    if (last != null && DateTime.now().difference(last) < Duration(days: days)) {
      return; // 아직 주기가 안 지남
    }

    await _runNow();
  }

  /// 주기와 무관하게 지금 바로 실행한다(설정 화면의 수동 테스트 버튼용).
  static Future<bool> runNow() async {
    if (!await ObsidianFolderChannel.hasFolder()) return false;
    return _runNow();
  }

  static Future<bool> _runNow() async {
    try {
      final cards = await DatabaseHelper.instance.readAllMemoCards();
      if (cards.isEmpty) return false;

      final folders = await DatabaseHelper.instance.readAllFolders();
      final manifest = await ObsidianExportService.buildManifest(cards, folders: folders);
      final success = await ObsidianFolderChannel.writeFiles(manifest);

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyLastRunMillis, DateTime.now().millisecondsSinceEpoch);
        logInfo('✅ 자동 내보내기 완료: ${cards.length}개 카드', name: 'ObsidianAutoExport');
      } else {
        logInfo('⚠️ 자동 내보내기 실패: 폴더 쓰기 실패', name: 'ObsidianAutoExport');
      }
      return success;
    } catch (e) {
      logInfo('❌ 자동 내보내기 실패: $e', name: 'ObsidianAutoExport');
      return false;
    }
  }
}
