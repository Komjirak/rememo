//
//  OnDeviceLLM.swift
//  Runner
//
//  온디바이스 LLM - Apple NaturalLanguage 프레임워크 기반 스마트 분석
//  iOS 12+에서 지원되는 NLTagger, NLLanguageRecognizer 사용
//  (실제 LLM 모델 대신 고급 NLP 휴리스틱을 사용하여 경량화된 분석 제공)
//

import Foundation
import NaturalLanguage

class OnDeviceLLM {
    static let shared = OnDeviceLLM()

    private let languageRecognizer = NLLanguageRecognizer()

    init() {
        print("🤖 OnDeviceLLM 초기화 (Apple NaturalLanguage Framework)")
    }

    // MARK: - 메인 API

    /// 스크린샷 텍스트 분석 (메인 API)
    func analyzeSummary(title: String?, paragraphs: [String], keyPoints: [String]) -> [String: Any] {
        let startTime = Date()
        print("🔄 On-Device NLP 분석 시작...")
        
        // 입력 데이터 전처리 (빈 줄 제거 등)
        let cleanedParagraphs = paragraphs
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            
        print("   - 입력 제목: \(title ?? "없음")")
        print("   - 유효 문단 수: \(cleanedParagraphs.count)")

        // 언어 감지
        let allText = cleanedParagraphs.prefix(5).joined(separator: " ") // 앞부분만 사용하여 속도 향상
        languageRecognizer.reset()
        languageRecognizer.processString(allText)
        let detectedLanguage = languageRecognizer.dominantLanguage
        print("   - 감지된 언어: \(detectedLanguage?.rawValue ?? "알 수 없음")")

        // NLP 기반 스마트 분석
        let result = enhancedNLPAnalysis(
            title: title,
            paragraphs: cleanedParagraphs,
            keyPoints: keyPoints,
            language: detectedLanguage
        )

        let elapsed = Date().timeIntervalSince(startTime)
        print("✅ On-Device NLP 분석 완료 (\(String(format: "%.2f", elapsed))초)")
        return result
    }

    // MARK: - 향상된 NLP 분석

    // MARK: - 향상된 NLP 분석 (Persona & Context 적용)

    private enum ContentDomain: String {
        case shopping = "Shopping"
        case sns = "SNS"
        case receipt = "Receipt"
        case article = "Article"
        case generic = "Generic"
    }

    private func enhancedNLPAnalysis(title: String?, paragraphs: [String], keyPoints: [String], language: NLLanguage?) -> [String: Any] {
        // 1. 도메인(Persona) 감지 - Context Strategy
        let domain = detectDomain(from: paragraphs)
        print("   - 감지된 도메인(Persona): \(domain.rawValue)")

        // 2. 스마트 제목 생성 (도메인별 전략)
        var finalTitle = title ?? "New Memory"
        if finalTitle.isEmpty || finalTitle == "New Memory" || finalTitle == "Web Link" {
            finalTitle = generateSmartTitle(from: paragraphs, domain: domain, language: language)
        }

        // 3. 핵심 요약 생성 (Chain of Thought Simulation: 도메인 -> 핵심정보 -> 요약)
        let summary = generateDomainSpecificSummary(paragraphs: paragraphs, domain: domain, language: language)

        // 4. 핵심 인사이트 추출 (Structured Output)
        var insights = extractDomainInsights(from: paragraphs, domain: domain)
        
        // 기존 추출된 포인트 보강
        if insights.count < 3 {
             let genericPoints = extractKeyInsights(from: paragraphs, language: language)
             for item in genericPoints {
                 if !insights.contains(item) && insights.count < 4 {
                     insights.append(item)
                 }
             }
        }

        return [
            "title": finalTitle,
            "summary": summary,
            "keyInsights": insights,
            "domain": domain.rawValue // 메타데이터 추가
        ]
    }

    // MARK: - 도메인 감지 (Context Analysis)

    private func detectDomain(from paragraphs: [String]) -> ContentDomain {
        let fullText = paragraphs.prefix(10).joined(separator: "\n").lowercased()
        
        // Shopping Keywords
        let shoppingKeywords = ["price", "won", "buy", "order", "total", "cart", "shipping", "delivery",
                                "가격", "원", "구매", "주문", "합계", "장바구니", "배송", "결제", "품절"]
        if shoppingKeywords.contains(where: { fullText.contains($0) }) {
            // 가격 패턴(\d원, $\d)이 있으면 확실시
            if fullText.range(of: "[0-9,]+원|\\$[0-9,]+", options: .regularExpression) != nil {
                return .shopping
            }
        }
        
        // SNS Keywords
        let snsKeywords = ["like", "comment", "share", "follow", "repost", "caption",
                           "좋아요", "댓글", "공유", "팔로우", "리포스트", "조회수"]
        if snsKeywords.contains(where: { fullText.contains($0) }) {
            // @username 패턴이나 해시태그 #
             if fullText.contains("@") || fullText.contains("#") {
                 return .sns
             }
        }
        
        // Receipt/Finance
        let receiptKeywords = ["receipt", "payment", "card", "transferred", "balance",
                               "영수증", "결제완료", "카드", "이체", "잔액", "입금", "출금"]
        if receiptKeywords.contains(where: { fullText.contains($0) }) {
             return .receipt
        }
        
        // Article/News (긴 문단)
        let avgLength = paragraphs.reduce(0) { $0 + $1.count } / max(1, paragraphs.count)
        if avgLength > 80 {
            return .article
        }

        return .generic
    }

    // MARK: - 스마트 제목 생성 (강화)

    private func generateSmartTitle(from paragraphs: [String], domain: ContentDomain, language: NLLanguage?) -> String {
        guard !paragraphs.isEmpty else { return "New Memory" }

        switch domain {
        case .shopping:
            // 쇼핑: 상품명 추정 (가격이 아닌 가장 긴 명사구 or 상단 텍스트)
            if let productCandidate = paragraphs.first(where: { !$0.contains("원") && !$0.contains("$") && $0.count > 5 }) {
                return truncateToTitle(productCandidate, maxLength: 30)
            }
            return "Shopping Item"
            
        case .receipt:
            // 영수증: 상단 업체명 추정
            if let storeName = paragraphs.first {
                return truncateToTitle(storeName, maxLength: 25)
            }
            return "Payment Receipt"
            
        case .sns:
            // SNS: 작성자 or 첫 줄
            if let handle = paragraphs.first(where: { $0.contains("@") }) {
                return "Post by \(handle)"
            }
            return "Social Post"
            
        default:
            // Generic Logic (Previously implemented)
            return generateGenericTitle(from: paragraphs, language: language)
        }
    }
    
    private func generateGenericTitle(from paragraphs: [String], language: NLLanguage?) -> String {
        // 1순위: 첫 번째 문단이 짧고 명사 위주라면 제목
        if let first = paragraphs.first, isLikelyTitle(first, language: language) {
            return truncateToTitle(first, maxLength: 40)
        }
        
        // 2순위: 제목 후보 점수 계산
        let candidates = paragraphs.prefix(5)
        var bestCandidate = (text: "", score: -1.0)
        
        for para in candidates {
            let score = scoreTitleCandidate(para, language: language)
            if score > bestCandidate.score {
                bestCandidate = (para, score)
            }
        }
        
        if bestCandidate.score > 10 {
             return truncateToTitle(bestCandidate.text, maxLength: 40)
        }
        
        return "New Memory"
    }

    // MARK: - 도메인별 요약 생성 (Prompt Persona Simulation)

    private func generateDomainSpecificSummary(paragraphs: [String], domain: ContentDomain, language: NLLanguage?) -> String {
        switch domain {
        case .shopping:
            // "Price: X, Product: Y" 형태
            let fullText = paragraphs.joined(separator: "\n")
            var summary = "🛍️ Shopping Item detected."
            
            // Extract Price
            if let match = fullText.range(of: "[0-9,]+원|\\$[0-9,]+\\.?[0-9]*", options: .regularExpression) {
                let price = String(fullText[match])
                summary += "\n💰 Price: \(price)"
            }
            
            // Extract Product (simple heuristic: first detected non-price line)
            if let product = paragraphs.first(where: { !$0.contains("원") && !$0.contains("$") && $0.count > 10 }) {
                 summary += "\n📦 Product: \(truncateSummary(product))"
            }
            return summary
            
        case .receipt:
             let fullText = paragraphs.joined(separator: "\n")
             var summary = "🧾 Payment detected."
             if let match = fullText.range(of: "[0-9,]+원|\\$[0-9,]+", options: .regularExpression) {
                let amount = String(fullText[match])
                summary += "\n💵 Total: \(amount)"
             }
             return summary

        case .sns:
            // Body text summary (focus on hashtags or long text)
            let body = paragraphs.first(where: { $0.count > 20 && !$0.contains("@") }) ?? paragraphs.first ?? ""
            return "💬 \(truncateSummary(body))"
            
        default:
            return generateContextualSummary(paragraphs: paragraphs, language: language)
        }
    }

    // MARK: - 도메인별 인사이트 추출

    private func extractDomainInsights(from paragraphs: [String], domain: ContentDomain) -> [String] {
        var insights: [String] = []
        let fullText = paragraphs.joined(separator: "\n")
        
        switch domain {
        case .shopping:
            insights.append("Category: Shopping")
            if fullText.contains("품절") || fullText.contains("Sold Out") {
                insights.append("Status: Sold Out")
            }
        case .receipt:
            insights.append("Category: Finance")
            // Date extraction
            if let match = fullText.range(of: "\\d{4}[-.]\\d{2}[-.]\\d{2}", options: .regularExpression) {
                insights.append("Date: \(String(fullText[match]))")
            }
        case .sns:
             insights.append("Category: Social")
             // Tag extraction
             let tags = paragraphs.flatMap { $0.components(separatedBy: " ") }
                 .filter { $0.hasPrefix("#") && $0.count > 1 }
             if !tags.isEmpty {
                 insights.append("Tags: \(tags.prefix(3).joined(separator: ", "))")
             }
        default:
            break
        }
        return insights
    }

    // MARK: - 기존 헬퍼 메서드 유지 (Contextual Summary, Scoring 등)
    // (Note: Re-implementing necessary helpers that were removed by replacement)

    private func generateContextualSummary(paragraphs: [String], language: NLLanguage?) -> String {
        guard !paragraphs.isEmpty else { return "No text detected." }
        if paragraphs.count == 1 { return truncateSummary(paragraphs[0]) }

        var candidates: [(text: String, score: Double)] = []
        for (index, para) in paragraphs.prefix(8).enumerated() {
            let sentences = splitIntoSentences(para)
            for sentence in sentences {
                let baseScore = scoreSentence(sentence, language: language)
                let positionMultiplier = max(1.0, 1.5 - (Double(index) * 0.1))
                candidates.append((sentence, baseScore * positionMultiplier))
            }
        }
        candidates.sort { $0.score > $1.score }
        
        let topSentences = candidates.prefix(2).map { $0.text }
        // Keep unique
         var finalSentences: [String] = []
         for s in topSentences {
              if !finalSentences.contains(where: { $0.contains(s) || s.contains($0) }) {
                  finalSentences.append(s)
              }
         }
        
        let combined = finalSentences.joined(separator: " ")
        return combined.isEmpty ? truncateSummary(paragraphs.first ?? "") : truncateSummary(combined)
    }
    
    // ... Copying Helper Helper Methods ...
    
    private func isLikelyTitle(_ text: String, language: NLLanguage?) -> Bool {
        let count = text.count
        if count < 3 || count > 60 { return false }
        if text.contains("http") || text.contains("www.") { return false }
        let lastChar = text.last
        if lastChar == "." || lastChar == "!" || lastChar == "?" { return false }
        return true
    }

    private func scoreTitleCandidate(_ text: String, language: NLLanguage?) -> Double {
        var score: Double = 0
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let length = cleaned.count
        
        if length >= 5 && length <= 35 { score += 20 }
        else if length > 35 && length <= 60 { score += 10 }
        else { score -= 10 }
        
        if isUINoiseText(cleaned) { return -100 }
        
        // Simple noun check proxy (lexical)
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = cleaned
        var nounCount = 0
        var wordCount = 0
        tagger.enumerateTags(in: cleaned.startIndex..<cleaned.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
            wordCount += 1
            if tag == .noun || tag == .organizationName { nounCount += 1 }
            return true
        }
        if wordCount > 0 && (Double(nounCount)/Double(wordCount) > 0.6) { score += 15 }
        if cleaned.range(of: "\\d{4}[-.]\\d{2}", options: .regularExpression) != nil { score += 5 }
        return score
    }

    private func isUINoiseText(_ text: String) -> Bool {
        let lower = text.lowercased()
        if text.range(of: "^\\d{1,2}:\\d{2}", options: .regularExpression) != nil { return true }
        if text.range(of: "^\\d{1,3}%$", options: .regularExpression) != nil { return true }
        let uiKeywords = ["back", "settings", "menu", "home", "edit", "share", "cancel", "done", "search", "뒤로", "설정", "메뉴", "홈", "편집", "공유", "취소", "완료", "검색"]
        if uiKeywords.contains(lower) { return true }
        return false
    }

    private func truncateToTitle(_ text: String, maxLength: Int) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= maxLength { return cleaned }
        return String(cleaned.prefix(maxLength - 3)) + "..."
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        return text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 10 }
    }

    private func truncateSummary(_ text: String) -> String {
        if text.count > 150 { return String(text.prefix(147)) + "..." }
        return text
    }

    private func scoreSentence(_ sentence: String, language: NLLanguage?) -> Double {
        var score: Double = 0
        let count = sentence.count
        if count >= 20 && count <= 100 { score += 10 }
        else if count < 10 { return 0 }
        
        let keywords = ["important", "summary", "conclusion", "total", "price", "order", "중요", "요약", "결론", "합계", "가격", "주문"]
        let lower = sentence.lowercased()
        for key in keywords { if lower.contains(key) { score += 20 } }
        
        if lower.contains("http") { score -= 10 }
        return score
    }

    private func extractKeyInsights(from paragraphs: [String], language: NLLanguage?) -> [String] {
        var insights: [String] = []
        // Bullet points
        for para in paragraphs {
            let trimmed = para.trimmingCharacters(in: .whitespaces)
            if trimmed.range(of: "^[-•*#] |^\\d+\\.", options: .regularExpression) != nil {
                 if trimmed.count > 5 && trimmed.count < 80 { insights.append(trimmed) }
            }
        }
        if insights.count >= 3 { return Array(insights.prefix(4)) }
        
        // Short sentences fallback
        var sentenceCandidates: [(String, Double)] = []
        for para in paragraphs.prefix(5) {
             for s in splitIntoSentences(para) {
                 if s.count < 60 {
                     sentenceCandidates.append((s, scoreSentence(s, language: language)))
                 }
             }
        }
        sentenceCandidates.sort{ $0.1 > $1.1 }
        for (cand, _) in sentenceCandidates {
             if !insights.contains(cand) { insights.append(cand) }
             if insights.count >= 4 { break }
        }
        return Array(insights.prefix(4))
    }
}

