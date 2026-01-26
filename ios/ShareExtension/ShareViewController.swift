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
    private var currentURL: URL?
    private var currentTitle: String = ""
    private var currentDomain: String = ""
    private var previewImage: UIImage?
    
    // MARK: - Color Constants
    private var accentTeal: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.18, green: 0.84, blue: 0.75, alpha: 1.0) // #2dd4bf
                    : UIColor(red: 0.18, green: 0.84, blue: 0.75, alpha: 1.0)
            }
        }
        return UIColor(red: 0.18, green: 0.84, blue: 0.75, alpha: 1.0)
    }
    
    private var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return traitCollection.userInterfaceStyle == .dark
        }
        return false
    }
    
    // MARK: - UI Components
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 32
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        return button
    }()
    
    private lazy var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var domainLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var aiStatusContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var aiStatusIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.backgroundColor = accentTeal
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var aiStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "AI will analyze this link"
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = accentTeal
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var viewInAppButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View in App", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(viewInAppAction), for: .touchUpInside)

        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        processSharedItems()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.addSubview(backgroundView)
        view.addSubview(containerView)
        
        containerView.addSubview(closeButton)
        containerView.addSubview(previewImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(domainLabel)
        containerView.addSubview(aiStatusContainer)
        containerView.addSubview(viewInAppButton)
        containerView.addSubview(saveButton)
        
        aiStatusContainer.addSubview(aiStatusIndicator)
        aiStatusContainer.addSubview(aiStatusLabel)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 340),
            
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            previewImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            previewImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            previewImageView.widthAnchor.constraint(equalToConstant: 64),
            previewImageView.heightAnchor.constraint(equalToConstant: 64),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: previewImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),
            titleLabel.heightAnchor.constraint(equalToConstant: 36),
            
            domainLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            domainLabel.leadingAnchor.constraint(equalTo: previewImageView.trailingAnchor, constant: 16),
            domainLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),
            
            aiStatusContainer.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 20),
            aiStatusContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            aiStatusContainer.heightAnchor.constraint(equalToConstant: 16),
            
            aiStatusIndicator.leadingAnchor.constraint(equalTo: aiStatusContainer.leadingAnchor),
            aiStatusIndicator.centerYAnchor.constraint(equalTo: aiStatusContainer.centerYAnchor),
            aiStatusIndicator.widthAnchor.constraint(equalToConstant: 8),
            aiStatusIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            aiStatusLabel.leadingAnchor.constraint(equalTo: aiStatusIndicator.trailingAnchor, constant: 8),
            aiStatusLabel.centerYAnchor.constraint(equalTo: aiStatusContainer.centerYAnchor),
            aiStatusLabel.trailingAnchor.constraint(equalTo: aiStatusContainer.trailingAnchor),
            
            viewInAppButton.topAnchor.constraint(equalTo: aiStatusContainer.bottomAnchor, constant: 16),
            viewInAppButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            viewInAppButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            viewInAppButton.heightAnchor.constraint(equalToConstant: 48),
            
            saveButton.topAnchor.constraint(equalTo: viewInAppButton.bottomAnchor, constant: 12),
            saveButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
        ])
        
        updateColors()
        setupCloseButton()
        startPulsingAnimation()
    }
    
    private func updateColors() {
        let dark = isDarkMode
        
        // Background
        backgroundView.backgroundColor = dark
            ? UIColor.black.withAlphaComponent(0.6)
            : UIColor.white.withAlphaComponent(0.4)
        
        // Container
        if dark {
            containerView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 0.9) // #1c1c1e/90
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        } else {
            containerView.backgroundColor = UIColor.white
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        }
        
        // Text colors
        titleLabel.textColor = dark ? .white : UIColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1.0) // charcoal
        domainLabel.textColor = dark ? UIColor.gray : UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        
        // Close button
        closeButton.tintColor = dark
            ? UIColor.white.withAlphaComponent(0.4)
            : UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        
        // View in App button
        viewInAppButton.backgroundColor = accentTeal
        viewInAppButton.setTitleColor(dark ? UIColor(red: 0.04, green: 0.18, blue: 0.16, alpha: 1.0) : .white, for: .normal)
        viewInAppButton.setTitleColor(dark ? UIColor(red: 0.04, green: 0.18, blue: 0.16, alpha: 0.5) : UIColor.white.withAlphaComponent(0.5), for: .disabled)
        viewInAppButton.layer.shadowColor = accentTeal.cgColor
        viewInAppButton.layer.shadowOpacity = 0.2
        viewInAppButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        viewInAppButton.layer.shadowRadius = 8
        
        // Save button
        saveButton.setTitleColor(accentTeal, for: .normal)
        saveButton.setTitleColor(accentTeal.withAlphaComponent(0.5), for: .disabled)
        saveButton.layer.borderColor = accentTeal.withAlphaComponent(0.4).cgColor
        saveButton.backgroundColor = dark
            ? accentTeal.withAlphaComponent(0.05)
            : .white
        
        // Preview image background
        previewImageView.backgroundColor = dark
            ? UIColor(red: 0.09, green: 0.09, blue: 0.09, alpha: 1.0) // card-dark
            : UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0) // gray-50
        
        if previewImageView.image == nil || previewImageView.image?.isSymbolImage == true {
            previewImageView.layer.borderWidth = 1
            previewImageView.layer.borderColor = dark
                ? UIColor.white.withAlphaComponent(0.1).cgColor
                : UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        } else {
            previewImageView.layer.borderWidth = 0
        }
    }
    
    private func setupCloseButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .light)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        closeButton.setImage(image, for: .normal)
    }
    
    private func startPulsingAnimation() {
        // Create pulsing animation for the indicator
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 1.5
        pulse.fromValue = 1.0
        pulse.toValue = 1.2
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.duration = 1.5
        opacity.fromValue = 0.75
        opacity.toValue = 0.4
        opacity.autoreverses = true
        opacity.repeatCount = .infinity
        opacity.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Create a separate layer for the pulsing effect
        let pulseLayer = CALayer()
        pulseLayer.frame = CGRect(x: 0, y: 0, width: 8, height: 8)
        pulseLayer.cornerRadius = 4
        pulseLayer.backgroundColor = accentTeal.cgColor
        pulseLayer.add(pulse, forKey: "pulse")
        pulseLayer.add(opacity, forKey: "opacity")
        
        // Add to indicator's superview layer instead
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.aiStatusIndicator.layer.insertSublayer(pulseLayer, at: 0)
        }
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
        currentURL = url
        currentDomain = prettifyDomain(url.host ?? "")
        currentTitle = currentDomain
        
        titleLabel.text = currentTitle
        domainLabel.text = url.host?.replacingOccurrences(of: "www.", with: "") ?? ""
        
        // 기본 아이콘 설정
        previewImageView.image = UIImage(systemName: "link.circle.fill")
        previewImageView.tintColor = accentTeal
        previewImage = nil
        
        let sharedItem: [String: Any] = [
            "type": "url",
            "url": url.absoluteString,
            "title": currentTitle,
            "timestamp": Date().timeIntervalSince1970,
            "status": "pending"
        ]
        
        self.sharedItems.append(sharedItem)
        self.processingComplete()
        
        // URL에서 메타데이터 가져오기 시도 (비동기)
        fetchURLMetadata(url: url)
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
            previewImageView.contentMode = .scaleAspectFill
            previewImage = img
        }
        
        currentTitle = "Image"
        titleLabel.text = currentTitle
        domainLabel.text = "Photo"
        
        processingComplete()
    }
    
    private func handleText(_ text: String) {
        let extractedURL = extractURL(from: text)
        
        var sharedItem: [String: Any] = [
            "type": "text",
            "text": text,
            "timestamp": Date().timeIntervalSince1970,
            "status": "pending"
        ]
        
        if let url = extractedURL {
            sharedItem["url"] = url
            handleURL(URL(string: url)!)
            return
        }
        
        sharedItems.append(sharedItem)
        
        previewImageView.image = UIImage(systemName: "doc.text.fill")
        previewImageView.tintColor = accentTeal
        currentTitle = String(text.prefix(30))
        titleLabel.text = currentTitle
        domainLabel.text = "Text"
        
        processingComplete()
    }
    
    private func handleWebPage(_ results: [String: Any]) {
        let urlString = results["url"] as? String ?? ""
        let title = results["title"] as? String ?? ""
        let selectedText = results["selectedText"] as? String
        
        guard let url = URL(string: urlString) else {
            processingComplete()
            return
        }
        
        currentURL = url
        currentTitle = title.isEmpty ? prettifyDomain(url.host ?? "") : title
        currentDomain = prettifyDomain(url.host ?? "")
        
        var sharedItem: [String: Any] = [
            "type": "webpage",
            "url": urlString,
            "title": currentTitle,
            "timestamp": Date().timeIntervalSince1970,
            "status": "pending"
        ]
        
        if let text = selectedText, !text.isEmpty {
            sharedItem["selectedText"] = text
        }
        
        sharedItems.append(sharedItem)
        
        titleLabel.text = currentTitle
        domainLabel.text = currentDomain.lowercased()
        previewImageView.image = UIImage(systemName: "globe")
        previewImageView.tintColor = accentTeal
        
        processingComplete()
        
        // 메타데이터 가져오기 시도
        fetchURLMetadata(url: url)
    }
    
    // MARK: - URL Metadata Fetching
    
    private func fetchURLMetadata(url: URL) {
        // URL에서 메타데이터 가져오기 (비동기)
        // 실제 구현에서는 WKWebView나 네트워크 요청을 사용해야 함
        // 여기서는 기본 정보만 표시
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 실제로는 여기서 URL의 OG 이미지 등을 가져와야 함
            // 지금은 기본 아이콘만 사용
        }
    }
    
    // MARK: - Helper Methods
    
    private func prettifyDomain(_ host: String) -> String {
        var name = host
        if name.hasPrefix("www.") {
            name = String(name.dropFirst(4))
        }
        if let dotIndex = name.firstIndex(of: ".") {
            name = String(name[..<dotIndex])
        }
        return name.prefix(1).uppercased() + name.dropFirst()
    }
    
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
                if !self.sharedItems.isEmpty {
                    self.viewInAppButton.isEnabled = true
                    self.saveButton.isEnabled = true
                    self.viewInAppButton.alpha = 1.0
                    self.saveButton.alpha = 1.0
                } else {
                    self.showError("저장할 항목이 없습니다")
                    self.viewInAppButton.isEnabled = false
                    self.saveButton.isEnabled = false
                    self.viewInAppButton.alpha = 0.5
                    self.saveButton.alpha = 0.5
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        titleLabel.text = message
        titleLabel.textColor = .systemRed
    }
    
    // MARK: - Actions
    
    @objc private func closeAction() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @objc private func saveAction() {
        saveToAppGroup()
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @objc private func viewInAppAction() {
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
    
    // MARK: - Missing property (for compatibility)
    private lazy var urlLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
}
