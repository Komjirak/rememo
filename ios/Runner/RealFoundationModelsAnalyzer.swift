//
//  RealFoundationModelsAnalyzer.swift
//  Runner
//
//  Apple Foundation Models (iOS 26+) 실제 연동
//
//  FoundationModelsAnalyzer.swift (NLP 휴리스틱) 와의 차이:
//  - import FoundationModels: 온디바이스 생성형 AI 모델 사용
//  - SystemLanguageModel.default: Apple 기기에 탑재된 언어 모델
//  - LanguageModelSession: 프롬프트 기반 텍스트 생성
//  - 실제 자연어 이해 기반 제목/요약 생성 (규칙 기반 아님)
//

import Foundation
import NaturalLanguage
import FoundationModels

// MARK: - Structured Output Schema

/// Foundation Models @Generable 구조체
/// 프롬프트 응답을 타입 안전하게 파싱
@available(iOS 26.0, *)
@Generable
struct ContentAnalysisSchema {
    @Guide(description: "콘텐츠를 대표하는 제목. 30자 이내. UI 요소(시간, 배터리, 탭바 텍스트)는 제외.")
    var title: String

    @Guide(description: "핵심 내용을 2~3문장으로 요약. 맥락과 의미를 포함.")
    var summary: String

    @Guide(description: "콘텐츠 유형. 'news'|'blog'|'product'|'restaurant'|'social'|'education'|'general' 중 하나.")
    var contentType: String

    @Guide(description: "핵심 키워드 태그 목록. 최대 5개.")
    var tags: [String]

    @Guide(description: "주목할 인사이트 또는 핵심 포인트. 최대 3개.")
    var insights: [String]
}

// MARK: - RealFoundationModelsAnalyzer

@available(iOS 26.0, *)
class RealFoundationModelsAnalyzer {
    static let shared = RealFoundationModelsAnalyzer()

    private init() {
        print("[RealFoundationModels] 🚀 initialized (iOS 26 Foundation Models)")
    }

    // MARK: - Availability

    /// 디바이스에서 Foundation Models를 실제로 사용 가능한지 확인
    static func isAvailable() -> Bool {
        return SystemLanguageModel.default.isAvailable
    }

    // MARK: - Main Analysis

    /// 텍스트 블록을 Foundation Models로 분석
    func analyze(
        textBlocks: [[String: Any]],
        imageSize: [String: CGFloat]
    ) async throws -> AnalysisResult {

        print("[RealFoundationModels] 🔍 분석 시작 (\(textBlocks.count) blocks)")
        let startTime = Date()

        // 1. 노이즈 필터링
        let filteredBlocks = filterUINoiseBlocks(textBlocks, imageSize: imageSize)
        let cleanText = filteredBlocks
            .compactMap { $0["text"] as? String }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanText.isEmpty else {
            throw RealFoundationModelsError.emptyText
        }

        // 2. 텍스트 길이 제한 (모델 컨텍스트 절약)
        let truncatedText = String(cleanText.prefix(2000))

        print("[RealFoundationModels] 📝 분석 대상 텍스트 길이: \(truncatedText.count)자")

        // 3. Foundation Models 세션 생성 및 분석
        let session = LanguageModelSession()
        let prompt = buildPrompt(for: truncatedText)

        let response = try await session.respond(
            to: prompt,
            generating: ContentAnalysisSchema.self
        )

        let schema = response.content

        // 4. 검증 및 AnalysisResult 변환
        let title = sanitizeTitle(schema.title, fallbackBlocks: filteredBlocks)
        let summary = schema.summary.isEmpty ? buildFallbackSummary(cleanText) : schema.summary

        // 5. 구조화된 데이터(URL, 전화번호 등) 별도 추출
        let fullText = textBlocks.compactMap { $0["text"] as? String }.joined(separator: "\n")
        let detectedData = detectStructuredData(in: fullText)

        let elapsed = Date().timeIntervalSince(startTime)
        print("[RealFoundationModels] ✅ 분석 완료 (\(String(format: "%.2f", elapsed))초)")
        print("[RealFoundationModels]   - 제목: \(title)")
        print("[RealFoundationModels]   - 요약: \(summary.prefix(80))...")
        print("[RealFoundationModels]   - 타입: \(schema.contentType)")
        print("[RealFoundationModels]   - 태그: \(schema.tags)")

        return AnalysisResult(
            title: title,
            explanation: summary,
            summary: summary,
            insights: schema.insights,
            tags: schema.tags,
            contentType: schema.contentType,
            refinedText: cleanText,
            detectedData: detectedData,
            provider: "RealFoundationModels (iOS 26)"
        )
    }

    // MARK: - Prompt Builder

    private func buildPrompt(for text: String) -> String {
        return """
        다음은 iOS 스크린샷에서 추출한 텍스트입니다.

        ---
        \(text)
        ---

        위 텍스트를 분석하여 JSON 형식으로 응답해주세요:
        - title: 콘텐츠를 대표하는 제목 (30자 이내, UI 요소 제외)
        - summary: 핵심 내용을 2~3문장으로 요약
        - contentType: news/blog/product/restaurant/social/education/general 중 하나
        - tags: 핵심 키워드 (최대 5개)
        - insights: 주목할 포인트 (최대 3개)
        """
    }

    // MARK: - Title Sanitization

    /// 생성된 제목에서 UI 노이즈 제거 및 길이 보정
    private func sanitizeTitle(_ rawTitle: String, fallbackBlocks: [[String: Any]]) -> String {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        // 제목이 너무 짧거나 없으면 fallback
        guard trimmed.count >= 4 else {
            return extractTitleFromBlocks(fallbackBlocks) ?? "New Memory"
        }

        // 길이 초과 시 자르기
        return trimmed.count > 50 ? String(trimmed.prefix(50)) : trimmed
    }

    /// 블록 상단에서 제목 후보 추출 (fallback용)
    private func extractTitleFromBlocks(_ blocks: [[String: Any]]) -> String? {
        let topBlocks = blocks
            .filter { ($0["top"] as? Double ?? 1.0) < 0.3 }
            .compactMap { $0["text"] as? String }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count >= 5 && $0.count <= 80 }

        return topBlocks.first
    }

    // MARK: - Fallback Summary

    private func buildFallbackSummary(_ text: String) -> String {
        let sentences = text
            .components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 15 }

        let selected = sentences.prefix(2).joined(separator: " ")
        return selected.isEmpty
            ? String(text.prefix(120))
            : (selected.count > 200 ? String(selected.prefix(200)) + "..." : selected)
    }

    // MARK: - UI Noise Filter
    // FoundationModelsAnalyzer와 임계값을 통일 (상단 5%, 하단 8%)

    private func filterUINoiseBlocks(
        _ blocks: [[String: Any]],
        imageSize: [String: CGFloat]
    ) -> [[String: Any]] {

        return blocks.filter { block in
            guard let text = block["text"] as? String else { return false }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.count > 1 else { return false }

            let top = block["top"] as? Double ?? 0.5
            let confidence = block["confidence"] as? Double ?? 0.8

            // 상단 5% 상태 표시줄 노이즈 제거 (통일된 임계값)
            if top < 0.05 && trimmed.count < 10 {
                if trimmed.range(of: "^\\d{1,2}:\\d{2}", options: .regularExpression) != nil { return false }
                if trimmed.range(of: "^\\d{1,3}%?$", options: .regularExpression) != nil { return false }
            }

            // 신뢰도 임계값 (통일: 0.05)
            if confidence < 0.05 { return false }

            // 단독 URL 제거
            if trimmed.range(of: "^https?://[^\\s]+$", options: .regularExpression) != nil { return false }

            // AD 마커 제거
            if trimmed == "AD" || trimmed == "광고" { return false }

            return true
        }
    }

    // MARK: - Structured Data Detection

    private func detectStructuredData(in text: String) -> DetectedData {
        var urls: [String] = []
        var phoneNumbers: [String] = []

        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            return DetectedData(urls: [], phoneNumbers: [], emails: [])
        }

        let matches = detector.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        for match in matches {
            if let url = match.url { urls.append(url.absoluteString) }
            if let phone = match.phoneNumber { phoneNumbers.append(phone) }
        }

        return DetectedData(
            urls: Array(Set(urls)),
            phoneNumbers: Array(Set(phoneNumbers)),
            emails: []
        )
    }
}

// MARK: - Errors

@available(iOS 26.0, *)
enum RealFoundationModelsError: Error, LocalizedError {
    case emptyText
    case modelUnavailable
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "분석할 텍스트가 없습니다."
        case .modelUnavailable:
            return "Foundation Models를 사용할 수 없는 기기입니다."
        case .parseError(let detail):
            return "응답 파싱 오류: \(detail)"
        }
    }
}
