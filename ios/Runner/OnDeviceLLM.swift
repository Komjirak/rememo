//
//  OnDeviceLLM.swift
//  Runner
//
//  온디바이스 LLM - Apple NaturalLanguage 프레임워크 기반 스마트 분석
//  iOS 12+에서 지원되는 NLTagger, NLLanguageRecognizer 사용
//  언어 감지 및 번역 필요성 판단 지원
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

import Foundation
import NaturalLanguage
import CoreGraphics

class EnhancedContentAnalyzer {
    static let shared = EnhancedContentAnalyzer()
    
    // MARK: - Main Entry Point
    func analyzeSummary(
        textBlocks: [[String: Any]],
        layoutRegions: [[String: Any]]? = nil,
        importantAreas: [[String: Any]]? = nil,
        imageSize: [String: CGFloat]
    ) -> [String: Any] {
        
        // 1. 전처리: 노이즈 제거
        let filteredBlocks = filterUINoiseBlocks(textBlocks, imageSize: imageSize)
        
        // 2. 레이아웃 분석
        let layout = analyzeLayout(
            textBlocks: filteredBlocks,
            layoutRegions: layoutRegions ?? [],
            importantAreas: importantAreas ?? [],
            imageSize: imageSize
        )
        
        // 3. 콘텐츠 타입 감지
        let contentType = detectContentType(
            textBlocks: filteredBlocks,
            layout: layout
        )
        
        // 4. 제목 추출
        let title = extractTitle(
            textBlocks: filteredBlocks,
            layout: layout,
            contentType: contentType
        )
        
        // 5. 요약 생성
        let summary = generateSummary(
            textBlocks: filteredBlocks,
            layout: layout,
            contentType: contentType
        )
        
        // 6. 태그 생성
        let tags = generateTags(
            textBlocks: filteredBlocks,
            contentType: contentType
        )
        
        return [
            "title": title,
            "summary": summary,
            "tags": tags,
            "contentType": contentType
        ]
    }
    
    // MARK: - 1. 노이즈 필터링
    private func filterUINoiseBlocks(
        _ blocks: [[String: Any]],
        imageSize: [String: CGFloat]
    ) -> [[String: Any]] {
        print("[EnhancedContentAnalyzer] === Filtering UI Noise ===")
        print("[EnhancedContentAnalyzer] Input blocks: \(blocks.count)")
        
        let filtered = blocks.filter { block in
            guard let text = block["text"] as? String,
                  let top = block["top"] as? Double,
                  let confidence = block["confidence"] as? Double else {
                return false
            }
            
            print("[EnhancedContentAnalyzer] Checking block: '\(text)' (top: \(top), conf: \(confidence))")
            
            // 1. 신뢰도 필터 (0.6 → 0.5로 낮춰 유용한 텍스트 보존)
            if confidence < 0.5 {
                print("[EnhancedContentAnalyzer] ❌ FILTERED: Low confidence")
                return false
            }

            // 2. 위치 필터 (상단 3%, 하단 5%로 축소하여 콘텐츠 손실 방지)
            if top < 0.03 || top > 0.95 {
                print("[EnhancedContentAnalyzer] ❌ FILTERED: Position (Header/Footer)")
                return false
            }
            
            // 3. 길이 필터 (너무 짧으면 노이즈)
            if text.count < 2 { 
                 print("[EnhancedContentAnalyzer] ❌ FILTERED: Too short")
                return false 
            }
            
            // 4. 패턴 필터 개선
            let noisePatterns = [
                "^\\d{1,2}:\\d{2}$",              // 시간
                "^\\d{1,3}%$",                     // 배터리
                "^Back$", "^Close$", "^Menu$",    // UI 버튼
                "^AD$", "^광고$", "^Sponsored$",  // 광고
                "^https?://.*",                    // URL 프로토콜
                "^www\\..*",                       // www로 시작
            ]

            // URL 패턴 필터링 (정규식 기반으로 정확도 향상)
            // 전체 URL 형태인 경우만 필터링 (부분 매칭 오탐 방지)
            let urlPatterns = [
                "^https?://",                           // URL 프로토콜로 시작
                "^www\\.",                              // www로 시작
                "\\.[a-z]{2,4}(/|$|\\?)",              // .com/, .io 등으로 끝나거나 경로 시작
                "^[a-z0-9-]+\\.[a-z]{2,4}$",          // 단순 도메인 (example.com)
            ]

            for pattern in urlPatterns {
                if text.lowercased().range(of: pattern, options: .regularExpression) != nil {
                    print("[EnhancedContentAnalyzer] ❌ FILTERED: URL pattern '\(pattern)' matched in '\(text)'")
                    return false
                }
            }

            // 케밥케이스 URL 패턴 (a-b-c.xxx 형태)
            // 예: developers-apps-in-toss.toss.im
            if text.matches("^[a-z]+-[a-z]+.*\\.[a-z]+") {
                print("[EnhancedContentAnalyzer] ❌ FILTERED: Kebab-case URL pattern")
                return false
            }

            // 하이픈이 2개 이상 포함된 텍스트 (URL일 가능성 높음)
            // 단, 날짜(2024-01-25) 및 전화번호(010-1234-5678) 패턴은 예외 처리
            let hyphenCount = text.filter { $0 == "-" }.count
            if hyphenCount >= 2 && text.count > 10 {
                // 날짜 패턴: YYYY-MM-DD 또는 YY-MM-DD
                let isDatePattern = text.range(of: "^\\d{2,4}-\\d{1,2}-\\d{1,2}$", options: .regularExpression) != nil
                // 전화번호 패턴: 010-1234-5678, 02-123-4567 등
                let isPhonePattern = text.range(of: "^\\d{2,4}-\\d{3,4}-\\d{4}$", options: .regularExpression) != nil
                // 날짜 범위 패턴: 2024-01-01 ~ 2024-12-31
                let isDateRangePattern = text.range(of: "\\d{4}-\\d{2}-\\d{2}.*\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) != nil

                if !isDatePattern && !isPhonePattern && !isDateRangePattern {
                    print("[EnhancedContentAnalyzer] ❌ FILTERED: Multiple hyphens (likely URL): '\(text)'")
                    return false
                } else {
                    print("[EnhancedContentAnalyzer] ✅ KEPT (date/phone pattern): '\(text)'")
                }
            }

            // 숫자로만 구성된 텍스트 (섹션 번호)
            if text.matches("^[0-9]+\\.$") {
                print("[EnhancedContentAnalyzer] ❌ FILTERED: Section number")
                return false
            }
            
            for pattern in noisePatterns {
                if text.range(of: pattern, options: .regularExpression) != nil {
                    print("[EnhancedContentAnalyzer] ❌ FILTERED: Pattern match (\(pattern))")
                    return false
                }
            }
            
            print("[EnhancedContentAnalyzer] ✅ KEPT: '\(text)'")
            return true
        }
        
        print("[EnhancedContentAnalyzer] Output blocks: \(filtered.count)")
        return filtered
    }
    
    // MARK: - 2. 레이아웃 분석
    private func analyzeLayout(
        textBlocks: [[String: Any]],
        layoutRegions: [[String: Any]],
        importantAreas: [[String: Any]],
        imageSize: [String: CGFloat]
    ) -> LayoutAnalysis {
        
        // Y좌표 기준 섹션 분할
        let sections = clusterIntoSections(textBlocks)
        
        // 제목 영역 추정
        let titleRegion = estimateTitleRegion(
            sections: sections,
            importantAreas: importantAreas
        )
        
        // 본문 영역들
        let contentRegions = sections.filter { section in
            !isInRegion(section, titleRegion)
        }
        
        return LayoutAnalysis(
            titleRegion: titleRegion,
            contentSections: contentRegions,
            totalSections: sections.count
        )
    }
    
    private func clusterIntoSections(_ blocks: [[String: Any]]) -> [[[String: Any]]] {
        guard !blocks.isEmpty else { return [] }
        
        // Y좌표로 정렬
        let sorted = blocks.sorted { a, b in
            (a["top"] as? Double ?? 0) < (b["top"] as? Double ?? 0)
        }
        
        var sections: [[[String: Any]]] = []
        var currentSection: [[String: Any]] = [sorted[0]]
        var lastTop = sorted[0]["top"] as? Double ?? 0
        
        for i in 1..<sorted.count {
            let block = sorted[i]
            let currentTop = block["top"] as? Double ?? 0
            
            // 간격이 크면 새 섹션 시작
            if currentTop - lastTop > 0.05 {
                sections.append(currentSection)
                currentSection = []
            }
            
            currentSection.append(block)
            lastTop = currentTop
        }
        
        if !currentSection.isEmpty {
            sections.append(currentSection)
        }
        
        return sections
    }
    
    private func estimateTitleRegion(
        sections: [[[String: Any]]],
        importantAreas: [[String: Any]]
    ) -> [String: Any]? {
        
        guard !sections.isEmpty else { return nil }
        
        // 상위 3개 섹션에서 제목 후보 찾기
        for section in sections.prefix(3) {
            // 평균 height (큰 텍스트 = 제목)
            let avgHeight = section.reduce(0.0) { sum, block in
                sum + (block["height"] as? Double ?? 0)
            } / Double(section.count)
            
            // 평균 confidence
            let avgConfidence = section.reduce(0.0) { sum, block in
                sum + (block["confidence"] as? Double ?? 0)
            } / Double(section.count)
            
            // 텍스트 길이
            let text = section.compactMap { $0["text"] as? String }.joined(separator: " ")
            
            // 제목 조건
            if avgHeight > 0.03 &&       // 충분히 큼
               avgConfidence > 0.8 &&    // 신뢰도 높음
               text.count > 5 &&         // 너무 짧지 않음
               text.count < 100 {        // 너무 길지 않음
                
                // Saliency와 교차 확인
                let isImportant = checkSaliencyMatch(section, importantAreas)
                
                if isImportant {
                    return createBoundingBox(from: section)
                }
            }
        }
        
        return nil
    }
    
    private func checkSaliencyMatch(
        _ section: [[String: Any]],
        _ importantAreas: [[String: Any]]
    ) -> Bool {
        guard !importantAreas.isEmpty,
              let sectionBox = createBoundingBox(from: section) else {
            return true  // Saliency 없으면 통과
        }
        
        // 겹치는 영역 확인
        for area in importantAreas {
            if boxesIntersect(sectionBox, area) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - 3. 콘텐츠 타입 감지
    private func detectContentType(
        textBlocks: [[String: Any]],
        layout: LayoutAnalysis
    ) -> String {
        
        let fullText = textBlocks
            .compactMap { $0["text"] as? String }
            .joined(separator: " ")
            .lowercased()
        
        // 패턴 매칭
        let patterns: [(type: String, keywords: [String])] = [
            ("news", ["사고", "정전", "피해", "발생", "경찰", "소방", "news", "report"]),
            ("weather", ["날씨", "기온", "예보", "강수", "℃", "weather"]),
            ("shopping", ["주문", "배송", "결제", "원", "price", "won", "shipping", "order"]),
            ("tech", ["api", "코드", "개발", "programming", "code", "software"])
        ]
        
        var scores: [String: Int] = [:]
        
        for (type, keywords) in patterns {
            let score = keywords.reduce(0) { count, keyword in
                count + (fullText.contains(keyword) ? 1 : 0)
            }
            scores[type] = score
        }
        
        // 최고점 타입 반환
        if let best = scores.max(by: { $0.value < $1.value }),
           best.value > 0 {
            return best.key
        }
        
        return "general"
    }
    
    // MARK: - 4. 제목 추출
    private func extractTitle(
        textBlocks: [[String: Any]],
        layout: LayoutAnalysis,
        contentType: String
    ) -> String {
        
        // 레이아웃에서 제목 영역 찾음
        if let titleRegion = layout.titleRegion {
            let titleText = textBlocks.filter { block in
                isBlockInRegion(block, titleRegion)
            }.compactMap { $0["text"] as? String }
             .joined(separator: " ")
            
            if !titleText.isEmpty {
                return cleanTitle(titleText)
            }
        }
        
        // 폴백: 첫 섹션
        if let firstSection = layout.contentSections.first {
            let text = firstSection
                .compactMap { $0["text"] as? String }
                .joined(separator: " ")
            return cleanTitle(text)
        }
        
        return "New Memory"
    }
    
    private func cleanTitle(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // URL 제거
        cleaned = cleaned.replacingOccurrences(
            of: "https?://\\S+",
            with: "",
            options: .regularExpression
        )
        
        // 길이 제한
        if cleaned.count > 50 {
            cleaned = String(cleaned.prefix(50))
        }
        
        return cleaned.isEmpty ? "New Memory" : cleaned
    }
    
    // MARK: - 5. 요약 생성
    private func generateSummary(
        textBlocks: [[String: Any]],
        layout: LayoutAnalysis,
        contentType: String
    ) -> String {
        print("[EnhancedContentAnalyzer] === Generating Summary ===")
        
        let fullText = textBlocks.compactMap { $0["text"] as? String }.joined(separator: " ")
        print("[EnhancedContentAnalyzer] Full text length: \(fullText.count)")
        print("[EnhancedContentAnalyzer] Full text: \(fullText.prefix(200))...")
        
        // NLTagger로 문장 분리
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = fullText
        
        var sentences: [(String, Double)] = []
        
        tagger.enumerateTags(in: fullText.startIndex..<fullText.endIndex, unit: .sentence, scheme: .tokenType, options: [.omitWhitespace]) { _, range in
            let sentence = String(fullText[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                let score = scoreSentence(sentence, fullText: fullText, contentType: contentType)
                print("[EnhancedContentAnalyzer] Sentence: '\(sentence.prefix(50))...' -> Score: \(score)")
                sentences.append((sentence, score))
            }
            return true
        }
        
        let topSentences = sentences.sorted { $0.1 > $1.1 }.prefix(3)
        print("[EnhancedContentAnalyzer] Top 3 sentences selected")
        
        let result = topSentences.map { $0.0 }.joined(separator: " ")
        print("[EnhancedContentAnalyzer] Final summary: \(result)")
        
        if result.isEmpty {
             return String(fullText.prefix(150)) + "..."
        }
        
        return result
    }
    
    private func scoreSentence(_ sentence: String, fullText: String, contentType: String) -> Double {
        var score = 0.0

        print("[EnhancedContentAnalyzer] Scoring: '\(sentence.prefix(50))...'")

        // 1. URL 포함 문장은 큰 감점 (확장된 도메인 목록)
        let urlDomains = [".com", ".io", ".im", ".kr", ".net", ".org", ".co", ".app", ".dev", ".me", ".tv", ".ai"]
        for domain in urlDomains {
            if sentence.contains(domain) {
                print("[EnhancedContentAnalyzer]   - URL domain '\(domain)' detected: -15.0")
                score -= 15.0
                break
            }
        }

        if sentence.contains("https://") || sentence.contains("http://") || sentence.contains("www.") {
            print("[EnhancedContentAnalyzer]   - URL protocol detected: -10.0")
            score -= 10.0
        }

        // 하이픈이 많은 문장 (URL 일부일 가능성)
        let hyphenCount = sentence.filter { $0 == "-" }.count
        if hyphenCount >= 2 {
            print("[EnhancedContentAnalyzer]   - Multiple hyphens: -5.0")
            score -= 5.0
        }
        
        // 2. 숫자로 시작하는 제목 (1., 2., 3.) 감점
        if sentence.matches("^\\d+\\.\\s+[가-힣]+") {
            print("[EnhancedContentAnalyzer]   - Section header: -5.0")
            score -= 5.0
        }
        
        // 3. 길이 점수
        let length = sentence.count
        if length > 30 && length < 150 {
            score += 2.0
            print("[EnhancedContentAnalyzer]   - Good length: +2.0")
        } else if length < 20 {
            score -= 1.0
            print("[EnhancedContentAnalyzer]   - Too short: -1.0")
        }
        
        // 4. 키워드 점수
        let keywords = getKeywordsForType(contentType)
        let matchCount = keywords.filter { sentence.lowercased().contains($0) }.count
        if matchCount > 0 {
            let keywordScore = Double(matchCount) * 1.5
            score += keywordScore
            print("[EnhancedContentAnalyzer]   - Keywords(\(matchCount)): +\(keywordScore)")
        }
        
        // 5. 완전한 문장인지 (마침표로 끝나는지)
        if sentence.hasSuffix(".") || sentence.hasSuffix("요") || sentence.hasSuffix("다") {
            score += 0.5
            print("[EnhancedContentAnalyzer]   - Complete sentence: +0.5")
        }
        
        print("[EnhancedContentAnalyzer]   = Total score: \(score)")
        return score
    }
    
    private func getKeywordsForType(_ type: String) -> [String] {
        switch type {
        case "news": return ["사고", "발생", "피해", "news", "report"]
        case "weather": return ["날씨", "기온", "℃", "weather"]
        case "shopping": return ["주문", "배송", "원", "price", "shipping"]
        default: return []
        }
    }
    
    // MARK: - 6. 태그 생성
    private func generateTags(
        textBlocks: [[String: Any]],
        contentType: String
    ) -> [String] {
        print("[EnhancedContentAnalyzer] === Generating Tags ===")
        
        let fullText = textBlocks.compactMap { $0["text"] as? String }.joined(separator: " ")
        
        var tags: Set<String> = []
        if contentType != "general" {
            tags.insert(contentType)
        }
        
        // NLTagger 설정 강화
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .language])
        tagger.string = fullText
        
        // 언어 감지
        if let language = tagger.dominantLanguage {
            print("[EnhancedContentAnalyzer] Detected language: \(language.rawValue)")
        }
        
        var nouns: [String: Int] = [:]
        
        tagger.enumerateTags(
            in: fullText.startIndex..<fullText.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation, .omitOther]
        ) { tag, range in
            let word = String(fullText[range])
            
            // 명사 또는 고유명사
            if tag == .noun || tag == .personalName || tag == .placeName {
                print("[EnhancedContentAnalyzer] Noun candidate: '\(word)'")

                // 한글인지 확인
                let isKorean = word.range(of: "[가-힣]", options: .regularExpression) != nil
                // 영어인지 확인
                let isEnglish = word.range(of: "[a-zA-Z]", options: .regularExpression) != nil

                // URL 관련 단어 필터링
                let urlKeywords = ["developers", "apps", "toss", "www", "http", "https", "com", "io", "im", "kr", "net", "org"]
                if urlKeywords.contains(word.lowercased()) {
                    print("[EnhancedContentAnalyzer] Rejected: URL keyword '\(word)'")
                    return true
                }

                // 최소 2글자 이상
                if word.count >= 2 && !self.isStopword(word) {
                    // 대문자만으로 구성된 영어 단어 제외 (DEVELOPERS 같은거)
                    if isEnglish && word == word.uppercased() && word.count > 1 {
                        print("[EnhancedContentAnalyzer] Rejected: all caps '\(word)'")
                    // 소문자만으로 구성된 짧은 영어 단어도 주의 (url 일부일 수 있음)
                    } else if isEnglish && word == word.lowercased() && word.count <= 4 && !isKorean {
                        print("[EnhancedContentAnalyzer] Rejected: short lowercase english '\(word)'")
                    } else {
                        nouns[word, default: 0] += 1
                        print("[EnhancedContentAnalyzer] Accepted: '\(word)'")
                    }
                } else {
                    print("[EnhancedContentAnalyzer] Rejected: too short or stopword")
                }
            }
            return true
        }
        
        print("[EnhancedContentAnalyzer] Total nouns found: \(nouns.count)")
        print("[EnhancedContentAnalyzer] Nouns: \(nouns)")
        
        // 빈도순 상위 4개
        let topNouns = nouns.sorted { $0.value > $1.value }.prefix(4).map { $0.key }
        print("[EnhancedContentAnalyzer] Top nouns: \(topNouns)")
        
        tags.formUnion(topNouns)
        
        print("[EnhancedContentAnalyzer] Final tags: \(Array(tags))")
        
        return Array(tags).prefix(5).map { $0 }
    }
    
    // 불용어 확장 (URL 관련 단어 포함)
    private func isStopword(_ word: String) -> Bool {
        let stopwords: Set<String> = [
            // 한국어 불용어
            "것", "수", "등", "때문", "경우", "이", "그", "저",
            "때", "곳", "년", "월", "일", "시", "분", "더", "안", "좀",
            // 영어 불용어
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "is", "of", "to", "for",
            "with", "by", "from", "as", "be", "are", "was", "were", "been", "being",
            "have", "has", "had", "do", "does", "did", "will", "would", "could", "should",
            "this", "that", "these", "those", "it", "its", "they", "them", "their",
            // URL/기술 관련 단어 (태그로 부적합)
            "developers", "apps", "toss", "www", "http", "https", "com", "io", "im", "kr",
            "net", "org", "app", "dev", "api", "url", "web", "site", "page", "link"
        ]
        return stopwords.contains(word.lowercased())
    }
    
    // MARK: - Helper Structs
    private struct LayoutAnalysis {
        let titleRegion: [String: Any]?
        let contentSections: [[[String: Any]]]
        let totalSections: Int
    }
    
    // MARK: - Geometry Helpers
    private func createBoundingBox(from blocks: [[String: Any]]) -> [String: Any]? {
        guard !blocks.isEmpty else { return nil }
        
        let tops = blocks.compactMap { $0["top"] as? Double }
        let lefts = blocks.compactMap { $0["left"] as? Double }
        let rights = blocks.compactMap { block -> Double? in
            guard let left = block["left"] as? Double,
                  let width = block["width"] as? Double else { return nil }
            return left + width
        }
        let bottoms = blocks.compactMap { block -> Double? in
            guard let top = block["top"] as? Double,
                  let height = block["height"] as? Double else { return nil }
            return top + height
        }
        
        guard let minTop = tops.min(),
              let minLeft = lefts.min(),
              let maxRight = rights.max(),
              let maxBottom = bottoms.max() else {
            return nil
        }
        
        return [
            "top": minTop,
            "left": minLeft,
            "width": maxRight - minLeft,
            "height": maxBottom - minTop
        ]
    }
    
    private func isBlockInRegion(_ block: [String: Any], _ region: [String: Any]) -> Bool {
        guard let blockTop = block["top"] as? Double,
              let blockLeft = block["left"] as? Double,
              let regionTop = region["top"] as? Double,
              let regionLeft = region["left"] as? Double,
              let regionWidth = region["width"] as? Double,
              let regionHeight = region["height"] as? Double else {
            return false
        }
        
        let blockCenterX = blockLeft + ((block["width"] as? Double ?? 0) / 2)
        let blockCenterY = blockTop + ((block["height"] as? Double ?? 0) / 2)
        
        return blockCenterX >= regionLeft &&
               blockCenterX <= regionLeft + regionWidth &&
               blockCenterY >= regionTop &&
               blockCenterY <= regionTop + regionHeight
    }
    
    private func isInRegion(_ section: [[String: Any]], _ region: [String: Any]?) -> Bool {
        guard let region = region else { return false }
        return section.contains { isBlockInRegion($0, region) }
    }
    
    private func boxesIntersect(_ box1: [String: Any], _ box2: [String: Any]) -> Bool {
        guard let t1 = box1["top"] as? Double,
              let l1 = box1["left"] as? Double,
              let w1 = box1["width"] as? Double,
              let h1 = box1["height"] as? Double,
              let t2 = box2["top"] as? Double,
              let l2 = box2["left"] as? Double,
              let w2 = box2["width"] as? Double,
              let h2 = box2["height"] as? Double else {
            return false
        }
        
        let r1 = l1 + w1
        let b1 = t1 + h1
        let r2 = l2 + w2
        let b2 = t2 + h2
        
        // 반대 조건: 교차하지 않는 경우
        // 하나라도 교차하지 않으면 false
        if r1 < l2 || r2 < l1 || b1 < t2 || b2 < t1 {
            return false
        }
        return true
    }
}

// MARK: - 온디바이스 번역 서비스
class OnDeviceTranslator {
    static let shared = OnDeviceTranslator()

    private let languageRecognizer = NLLanguageRecognizer()

    init() {
        print("🌐 OnDeviceTranslator 초기화")
    }

    /// OS 언어 가져오기 (예: "ko", "en", "ja")
    func getSystemLanguage() -> String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let langCode = String(preferredLanguage.prefix(2))
        print("[Translator] System language: \(langCode)")
        return langCode
    }

    /// 텍스트 언어 감지
    func detectLanguage(text: String) -> String? {
        languageRecognizer.reset()
        languageRecognizer.processString(text)
        let detected = languageRecognizer.dominantLanguage?.rawValue
        print("[Translator] Detected language: \(detected ?? "unknown")")
        return detected
    }

    /// 번역 필요 여부 확인
    func needsTranslation(text: String) -> Bool {
        guard let detectedLang = detectLanguage(text: text) else { return false }

        let systemLang = getSystemLanguage()
        let needs = detectedLang != systemLang

        print("[Translator] Needs translation: \(needs) (detected: \(detectedLang), system: \(systemLang))")
        return needs
    }

    /// 온디바이스 번역 (iOS 17.4+에서만 작동, 이전 버전은 원문 반환)
    func translateToSystemLanguage(text: String, completion: @escaping (String) -> Void) {
        guard needsTranslation(text: text) else {
            print("[Translator] No translation needed")
            completion(text)
            return
        }

        // 번역 수행 (현재는 언어 감지만 하고 원문 반환)
        performTranslation(text: text, completion: completion)
    }

    /// 간단한 번역 시뮬레이션 (향후 Translation API 연동 예정)
    /// 현재는 원문을 반환하고, 번역이 필요한지 여부만 알림
    private func performTranslation(text: String, completion: @escaping (String) -> Void) {
        // TODO: iOS 18+ Translation API 연동
        // 현재는 언어 감지 결과만 로깅하고 원문 반환
        let detectedLang = detectLanguage(text: text) ?? "unknown"
        let systemLang = getSystemLanguage()

        print("[Translator] 📝 Translation requested")
        print("[Translator]   Source language: \(detectedLang)")
        print("[Translator]   Target language: \(systemLang)")
        print("[Translator]   ⚠️ Returning original text (Translation API integration pending)")

        // 원문 반환 (향후 번역 API 연동 시 번역된 텍스트 반환)
        completion(text)
    }

    /// 동기 번역 (텍스트가 짧은 경우 사용)
    func translateSync(text: String, timeout: TimeInterval = 5.0) -> String {
        var result = text
        let semaphore = DispatchSemaphore(value: 0)

        translateToSystemLanguage(text: text) { translated in
            result = translated
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + timeout)
        return result
    }
}

// Helper: String regex 매칭
extension String {
    func matches(_ pattern: String) -> Bool {
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}
