import Foundation
import UIKit
import UniformTypeIdentifiers

/// Obsidian Vault(또는 임의 폴더)에 대한 지속적인 쓰기 권한을
/// Security-Scoped Bookmark로 관리하고, 포그라운드/백그라운드 어느 쪽에서든
/// 별도 UI 없이 해당 폴더에 파일을 직접 쓸 수 있게 해주는 헬퍼.
///
/// 사용자는 최초 1회만 폴더를 선택(iOS 문서 피커)하면 되고, 이후에는
/// 앱이 재실행되거나 백그라운드 작업(BGTaskScheduler)이 실행될 때도
/// 북마크를 복원해 같은 폴더에 계속 쓸 수 있다.
class ObsidianExportHelper: NSObject, UIDocumentPickerDelegate {
    static let shared = ObsidianExportHelper()

    private let bookmarkKey = "obsidian_vault_bookmark"
    private let folderNameKey = "obsidian_vault_folder_name"
    private var pickerCompletion: ((Bool, String?) -> Void)?

    // MARK: - 폴더 선택 (최초 1회, 포그라운드 UI 필요)

    func pickFolder(from viewController: UIViewController, completion: @escaping (Bool, String?) -> Void) {
        pickerCompletion = completion
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        viewController.present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            pickerCompletion?(false, nil)
            pickerCompletion = nil
            return
        }

        guard url.startAccessingSecurityScopedResource() else {
            pickerCompletion?(false, nil)
            pickerCompletion = nil
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
            let name = url.lastPathComponent
            UserDefaults.standard.set(name, forKey: folderNameKey)
            pickerCompletion?(true, name)
        } catch {
            pickerCompletion?(false, nil)
        }
        pickerCompletion = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        pickerCompletion?(false, nil)
        pickerCompletion = nil
    }

    // MARK: - 저장된 폴더 정보

    var hasFolder: Bool {
        UserDefaults.standard.data(forKey: bookmarkKey) != nil
    }

    var folderDisplayName: String? {
        UserDefaults.standard.string(forKey: folderNameKey)
    }

    func clearFolder() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.removeObject(forKey: folderNameKey)
    }

    /// 북마크를 복원해 접근 가능한 URL을 반환한다. 반환된 URL은 호출부에서
    /// startAccessingSecurityScopedResource()/stopAccessingSecurityScopedResource()로
    /// 감싸서 사용해야 한다.
    private func resolveFolderURL() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        if isStale {
            // 시스템 변경 등으로 북마크가 오래되었으면 조용히 갱신을 시도한다.
            if let refreshed = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
                UserDefaults.standard.set(refreshed, forKey: bookmarkKey)
            }
        }
        return url
    }

    // MARK: - 파일 쓰기

    /// [files]를 선택된 폴더 하위의 "Rememo Export/" 디렉터리에 기록한다.
    /// 폴더 접근이 불가능하면(권한 취소 등) false를 반환한다.
    func writeFiles(_ files: [(path: String, data: Data)]) -> Bool {
        guard let folderURL = resolveFolderURL() else { return false }
        guard folderURL.startAccessingSecurityScopedResource() else { return false }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let exportRoot = folderURL.appendingPathComponent("Rememo Export", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: exportRoot, withIntermediateDirectories: true)
            for file in files {
                let destURL = exportRoot.appendingPathComponent(file.path)
                try FileManager.default.createDirectory(
                    at: destURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try file.data.write(to: destURL, options: .atomic)
            }
            return true
        } catch {
            return false
        }
    }
}
