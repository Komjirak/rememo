//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Eunae on 1/21/26.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers


class ShareViewController: UIViewController {

    private let appGroupId = "group.com.rememo.komjirak"
    private var sharedItems: [[String: Any]] = []
    private var processingCount = 0

    // MARK: - UI Components
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Rememo에 저장"
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "준비 중..."
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var progressIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        return indicator
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("저장", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var urlLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemBlue
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        processSharedItems()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(previewImageView)
        containerView.addSubview(urlLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(progressIndicator)
        containerView.addSubview(cancelButton)
        containerView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 320),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            previewImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            previewImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            previewImageView.widthAnchor.constraint(equalToConstant: 120),
            previewImageView.heightAnchor.constraint(equalToConstant: 120),

            urlLabel.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 8),
            urlLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            urlLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            progressIndicator.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            progressIndicator.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),

            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),

            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 80),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    // MARK: - Process Shared Items

    private func processSharedItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            showError("공유할 항목이 없습니다")
            return
        }

        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments else { continue }

            for attachment in attachments {
                processingCount += 1
                processAttachment(attachment)
            }
        }

        if processingCount == 0 {
            showError("지원하지 않는 형식입니다")
        }
    }

    private func processAttachment(_ attachment: NSItemProvider) {
        // 1. URL 처리 (웹 링크)
        if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (data, error) in
                DispatchQueue.main.async {
                    if let url = data as? URL {
                        self?.handleURL(url)
                    } else {
                        self?.processingComplete()
                    }
                }
            }
            return
        }

        // 2. 이미지 처리
        if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (data, error) in
                DispatchQueue.main.async {
                    self?.handleImage(data)
                }
            }
            return
        }

        // 3. 텍스트 처리
        if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (data, error) in
                DispatchQueue.main.async {
                    if let text = data as? String {
                        self?.handleText(text)
                    } else {
                        self?.processingComplete()
                    }
                }
            }
            return
        }

        // 4. Property List (웹페이지 공유 시)
        if attachment.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { [weak self] (data, error) in
                DispatchQueue.main.async {
                    if let dict = data as? [String: Any],
                       let results = dict[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any] {
                        self?.handleWebPage(results)
                    } else {
                        self?.processingComplete()
                    }
                }
            }
            return
        }

        processingComplete()
    }

    // MARK: - Handle Different Content Types

    private func handleURL(_ url: URL) {
        // 즉시 UI 업데이트 (네트워크 요청 없음)
        urlLabel.text = url.absoluteString
        previewImageView.image = UIImage(systemName: "link.circle.fill")
        previewImageView.tintColor = .systemBlue
        
        // 기본 호스트 이름만 추출하여 제목으로 사용
        let hostTitle = prettifyHost(url.host) ?? "Web Link"
        titleLabel.text = hostTitle
        statusLabel.text = "링크가 준비되었습니다"
        
        let sharedItem: [String: Any] = [
            "type": "url",
            "url": url.absoluteString,
            "title": hostTitle,
            "timestamp": Date().timeIntervalSince1970,
            "status": "pending" // 앱에서 나중에 메타데이터를 가져오도록 표사
        ]
        
        self.sharedItems.append(sharedItem)
        self.processingComplete()
    }

    // MARK: - WKWebView for Metadata Fetching
    
    /// 호스트 이름을 보기 좋게 변환 (예: www.example.com -> Example)
    private func prettifyHost(_ host: String?) -> String? {
        guard let host = host else { return nil }
        var name = host
        if name.hasPrefix("www.") {
            name = String(name.dropFirst(4))
        }
        // 도메인에서 .com, .co.kr 등 제거하고 첫 글자 대문자
        if let dotIndex = name.firstIndex(of: ".") {
            name = String(name[..<dotIndex])
        }
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    private func handleImage(_ data: Any?) {
        var image: UIImage?
        var imagePath: String?

        if let url = data as? URL {
            image = UIImage(contentsOfFile: url.path)
            imagePath = saveImageToSharedContainer(url: url)
        } else if let uiImage = data as? UIImage {
            image = uiImage
            imagePath = saveImageToSharedContainer(image: uiImage)
        } else if let imageData = data as? Data {
            image = UIImage(data: imageData)
            if let img = image {
                imagePath = saveImageToSharedContainer(image: img)
            }
        }

        guard let savedPath = imagePath else {
            processingComplete()
            return
        }

        let sharedItem: [String: Any] = [
            "type": "image",
            "imagePath": savedPath,
            "timestamp": Date().timeIntervalSince1970,
            "status": "pending"
        ]
        sharedItems.append(sharedItem)

        if let img = image {
            previewImageView.image = img
        }
        statusLabel.text = "이미지 저장됨"

        processingComplete()
    }

    private func handleText(_ text: String) {
        // URL 추출 시도
        let extractedURL = extractURL(from: text)

        var sharedItem: [String: Any] = [
            "type": "text",
            "text": text,
            "timestamp": Date().timeIntervalSince1970,
            "status": "pending"
        ]

        if let url = extractedURL {
            sharedItem["url"] = url
            urlLabel.text = url
        }

        sharedItems.append(sharedItem)

        previewImageView.image = UIImage(systemName: "doc.text.fill")
        previewImageView.tintColor = .systemGray
        statusLabel.text = "텍스트: \(text.prefix(30))..."

        processingComplete()
    }

    private func handleWebPage(_ results: [String: Any]) {
        let url = results["url"] as? String ?? ""
        let title = results["title"] as? String ?? ""
        let selectedText = results["selectedText"] as? String

        var sharedItem: [String: Any] = [
            "type": "webpage",
            "url": url,
            "title": title,
            "timestamp": Date().timeIntervalSince1970,
            "status": "pending"
        ]

        if let text = selectedText, !text.isEmpty {
            sharedItem["selectedText"] = text
        }

        sharedItems.append(sharedItem)

        urlLabel.text = url
        titleLabel.text = title.isEmpty ? "웹 페이지" : String(title.prefix(30))
        previewImageView.image = UIImage(systemName: "globe")
        previewImageView.tintColor = .systemBlue

        processingComplete()
    }

    // MARK: - Helper Methods

    private func extractURL(from text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text))

        if let match = matches?.first, let url = match.url {
            return url.absoluteString
        }

        let urlPattern = "(https?://[^\\s]+)|(www\\.[^\\s]+)"
        if let regex = try? NSRegularExpression(pattern: urlPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }

        return nil
    }

    private func saveImageToSharedContainer(url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return saveImageData(data)
    }

    private func saveImageToSharedContainer(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        return saveImageData(data)
    }

    private func saveImageData(_ data: Data) -> String? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }

        let sharedImagesDir = containerURL.appendingPathComponent("SharedImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: sharedImagesDir, withIntermediateDirectories: true)

        let fileName = UUID().uuidString + ".jpg"
        let fileURL = sharedImagesDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            return nil
        }
    }

    private func processingComplete() {
        processingCount -= 1

        if processingCount <= 0 {
            DispatchQueue.main.async {
                self.progressIndicator.stopAnimating()

                if !self.sharedItems.isEmpty {
                    self.statusLabel.text = "\(self.sharedItems.count)개 항목 준비됨"
                    self.saveButton.isEnabled = true
                    self.saveButton.alpha = 1.0
                } else {
                    self.showError("저장할 항목이 없습니다")
                }
            }
        }
    }

    private func showError(_ message: String) {
        statusLabel.text = message
        statusLabel.textColor = .systemRed
        progressIndicator.stopAnimating()
    }

    // MARK: - Actions

    @objc private func cancelAction() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    @objc private func saveAction() {
        saveToAppGroup()

        // 메인 앱 실행 (URL Scheme 사용)
        if let url = URL(string: "rememo://shared") {
            var responder: UIResponder? = self
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(url, options: [:], completionHandler: nil)
                    break
                }
                responder = responder?.next
            }
        }

        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func saveToAppGroup() {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return }

        // 기존 pending items 가져오기
        var pendingItems = userDefaults.array(forKey: "pendingSharedItems") as? [[String: Any]] ?? []

        // 새 items 추가
        pendingItems.append(contentsOf: sharedItems)

        // 저장
        userDefaults.set(pendingItems, forKey: "pendingSharedItems")
        userDefaults.synchronize()
    }
}
