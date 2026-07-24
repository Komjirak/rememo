import 'package:flutter/services.dart';
import 'package:stribe/services/obsidian_export_service.dart';
import 'package:stribe/utils/app_logger.dart';

/// Obsidian Vault 폴더에 대한 지속적인 쓰기 권한(iOS Security-Scoped Bookmark)을
/// 관리하는 네이티브 채널의 Dart 래퍼. 사용자가 폴더를 한 번 선택해두면,
/// 이후로는 앱 재실행이나 백그라운드 실행에서도 같은 폴더에 바로 쓸 수 있다.
class ObsidianFolderChannel {
  static const _channel = MethodChannel('com.rememo.komjirak/obsidian_folder');

  /// 문서 피커를 띄워 폴더를 선택받는다. 성공 시 선택된 폴더 이름, 취소/실패 시 null.
  static Future<String?> pickFolder() async {
    try {
      final result = await _channel.invokeMethod('pickFolder');
      final map = Map<String, dynamic>.from(result as Map);
      if (map['success'] == true) {
        return map['folderName'] as String?;
      }
      return null;
    } catch (e) {
      logInfo('폴더 선택 실패: $e', name: 'ObsidianFolder');
      return null;
    }
  }

  static Future<bool> hasFolder() async {
    try {
      return await _channel.invokeMethod<bool>('hasFolder') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> folderName() async {
    try {
      return await _channel.invokeMethod<String>('folderName');
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearFolder() async {
    try {
      await _channel.invokeMethod('clearFolder');
    } catch (_) {
      // 무시 — 다음 hasFolder() 조회가 정확한 상태를 알려준다.
    }
  }

  /// [files]를 선택된 폴더 하위의 "Rememo Export/"에 직접 쓴다.
  /// 폴더가 선택되어 있지 않거나 접근에 실패하면 false를 반환한다.
  static Future<bool> writeFiles(List<ObsidianExportFile> files) async {
    try {
      final payload = files
          .map((f) => {
                'path': f.relativePath,
                'bytes': Uint8List.fromList(f.bytes),
              })
          .toList();
      final result = await _channel.invokeMethod<bool>('writeFiles', {'files': payload});
      return result ?? false;
    } catch (e) {
      logInfo('폴더 쓰기 실패: $e', name: 'ObsidianFolder');
      return false;
    }
  }
}
