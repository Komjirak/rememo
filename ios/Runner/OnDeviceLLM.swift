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

    // MARK: - 도메인 감지 (Semantic Analysis with NLEmbedding)

    private func detectDomain(from paragraphs: [String]) -> ContentDomain {
        let fullText = paragraphs.prefix(10).joined(separator: "\n").lowercased()
        
        // 1. Regex/Keyword Fast Path (기존 로직 유지 - 확실한 신호)
        if fullText.range(of: "[0-9,]+원|\\$[0-9,]+", options: .regularExpression) != nil {
            if fullText.contains("주문") || fullText.contains("결제") || fullText.contains("shipping") {
                return .shopping
            }
        }
        if fullText.contains("@") && (fullText.contains("post") || fullText.contains("likes")) {
            return .sns
        }
        
        // 2. Semantic Embedding Check (NLEmbedding)
        // 용량 0MB 증가: iOS 내장 임베딩 사용
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            return .generic // 임베딩 로드 실패시 일반 처리
        }
        
        // 문서의 핵심 키워드 추출 (간단한 빈도수/명사 추출)
        let keywords = extractKeyNouns(from: fullText)
        if keywords.isEmpty { return .generic }
        
        // 도메인별 대표 단어와 거리 계산
        let shoppingDistance = averageDistance(from: keywords, to: ["shopping", "price", "buy", "product", "cart"], in: embedding)
        let snsDistance = averageDistance(from: keywords, to: ["social", "post", "comment", "like", "share", "friend"], in: embedding)
        let financeDistance = averageDistance(from: keywords, to: ["receipt", "money", "bank", "card", "payment"], in: embedding)
        
        print("   - Semantic Distances: Shop=\(shoppingDistance), SNS=\(snsDistance), Fin=\(financeDistance)")
        
        let minDistance = min(shoppingDistance, snsDistance, financeDistance)
        
        if minDistance < 0.8 { // 임계값 (작을수록 관련성 높음, 0~2 범위)
            if minDistance == shoppingDistance { return .shopping }
            if minDistance == snsDistance { return .sns }
            if minDistance == financeDistance { return .receipt }
        }
        
        // Article check (length based)
        let avgLength = paragraphs.reduce(0) { $0 + $1.count } / max(1, paragraphs.count)
        if avgLength > 80 { return .article }
        
        return .generic
    }
    
    private func extractKeyNouns(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        var nouns: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, range in
            if tag == .noun {
                nouns.append(String(text[range]).lowercased())
            }
            return true
        }
        // 빈도수 높은 상위 5개 정도만 사용하면 좋지만, 여기선 전체 중 일부만 랜덤/순서대로 사용
        return Array(nouns.prefix(10))
    }
    
    private func averageDistance(from textWords: [String], to targetWords: [String], in embedding: NLEmbedding) -> Double {
        var totalDist: Double = 0
        var count: Int = 0
        
        for target in targetWords {
            for word in textWords {
                // Determine distance
                // Note: The compiler indicates this returns a non-optional Double in this context
                let dist = embedding.distance(between: target, and: word)
                
                // NLDistance.greatestFiniteMagnitude usually indicates 'not found' / infinite distance
                if dist < NLDistance.greatestFiniteMagnitude {
                     totalDist += dist
                     count += 1
                }
            }
        }
        return count > 0 ? totalDist / Double(count) : 2.0 // Max distance
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
        
        let lower = sentence.lowercased()
        
        // 1. Keyword Bonus (Legacy)
        let keywords = ["important", "summary", "conclusion", "total", "price", "order", "중요", "요약", "결론", "합계", "가격", "주문"]
        for key in keywords { if lower.contains(key) { score += 20 } }
        
        // 2. Semantic Similarity Bonus (iOS 13+ NLEmbedding)
        // 문장이 "important information"이나 "summary"와 의미적으로 가까운지 확인
        if #available(iOS 13.0, *), 
           let embedding = NLEmbedding.sentenceEmbedding(for: .english), // 문장 임베딩은 영어 위주 지원
           language == .english {
            // Compiler indicates non-optional return
            let dist = embedding.distance(between: lower, and: "this is an important summary of the content")
            
            // dist는 0(완전일치) ~ 2(완전불일치). 0.8 이하면 꽤 관련 있음
            if dist < 0.6 { score += 30 }
            else if dist < 0.8 { score += 15 }
        }
        
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
            contentType: contentType,
            title: title
        )
        
        // 6. 태그 생성
        let tags = generateTags(
            textBlocks: filteredBlocks,
            contentType: contentType
        )
        
        // 7. 인사이트 추출 (NEW!)
        let insights = extractInsights(
            from: filteredBlocks,
            contentType: contentType
        )

        return [
            "title": title,
            "summary": summary,
            "tags": tags,
            "contentType": contentType,
            "refinedText": generateRefinedText(from: filteredBlocks),  // ✨ NEW
            "insights": insights  // ✨ NEW
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
            
            // 4. 패턴 기반 필터 (확장됨)
            let noisePatterns = [
                "^\\d{1,2}:\\d{2}$",              // 시간
                "^\\d{1,3}%$",                     // 배터리
                "^Back$", "^Close$", "^Share$", "^Delete$", "^Done$", "^Cancel$",  // UI 버튼
                "^AD$", "^Sponsored$",            // 광고
                "^https?://.*",                    // URL 프로토콜
                "^www\\..*",                       // www로 시작
                ".*\\.(com|io|net|org|kr|co\\.kr).*",  // 도메인 포함
                "[a-z]+-[a-z]+-[a-z]+\\.",        // 케밥케이스 URL
                "^\\d+\\.$",                       // 섹션 번호만
                "^[A-Z]{2,}$",                     // 대문자만
                "^\\d+$",                          // 숫자만
                "판매.*페이지",                    // 광고성 텍스트
                "해당.*링크",                      // 광고성 텍스트
                "^\\d+\\)$",                       // ✨ NEW: 번호만 (924))
                "^blog$",                          // ✨ NEW: blog 단독
                "^post$",                          // ✨ NEW: post 단독
                "^\\d+@\\d+",                      // ✨ NEW: 00126@19 같은 패턴
                "^[A-Z]\\s",                    // ✨ NEW: "E " 같은 단일 알파벳
            ]
            
            for pattern in noisePatterns {
                if text.range(of: pattern, options: .regularExpression) != nil {
                    print("[EnhancedContentAnalyzer] ❌ FILTERED: Pattern matched (\(pattern))")
                    return false
                }
            }

            // ✨ 추가 필터: UI 관련 키워드 포함 체크
            let uiKeywords = [
                "Menu", "메뉴", "닫기", "열기", "편집", "요약", "번역",
                "즐겨찾기", "삭제", "이동", "공유", "클립", "글쓰기",
                "바로가기", "카테고리", "폰트", "크기", "조정",
                "Search", "검색",              // ✨ NEW
                "matters",                     // ✨ NEW (사이트 이름)
                "출처:", "이미지 출처",         // ✨ NEW (메타데이터)
            ]
            
            for keyword in uiKeywords {
                if text.contains(keyword) {
                    print("[EnhancedContentAnalyzer] ❌ FILTERED: UI keyword (\(keyword))")
                    return false
                }
            }

            // ✨ 추가 필터: NAVER, Corp 등 푸터 텍스트
            if text.contains("NAVER") || text.contains("Corp.") || 
               text.contains("©") || text.contains("PC버전") {
                print("[EnhancedContentAnalyzer] ❌ FILTERED: Footer/Copyright")
                return false
            }

            // ✨ 추가 필터: 너무 많은 단어가 붙어있으면 UI 요소
            let words = text.components(separatedBy: " ")
            if words.count > 5 && text.count < 100 {
                // "이웃목록 클립만들기 글쓰기 My Menu 닫기 내 체" 같은 것
                let hasMultipleUIWords = words.filter { word in
                    uiKeywords.contains { word.contains($0) }
                }.count >= 3
                
                if hasMultipleUIWords {
                    print("[EnhancedContentAnalyzer] ❌ FILTERED: Multiple UI keywords")
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
            ("news", ["사고", "정전", "피해", "발생", "경찰", "소방", "news", "report", "기자", "일보", "뉴스", "times", "herald"]),
            ("weather", ["날씨", "기온", "예보", "강수", "℃", "weather"]),
            ("shopping", ["주문", "배송", "결제", "원", "price", "won", "shipping", "order", "쿠팡", "coupang", "store", "shop", "장바구니", "구매", "할인", "sale", "sold out", "품절", "카트", "cart"]),  // ✨ 확장
            ("education", ["대학", "학교", "교육", "학생", "교수", "학습", "university", "college", "education"]),  // ✨ NEW
            ("history", ["역사", "설립", "출범", "년", "당시", "과거", "history", "founded"]),  // ✨ NEW
            ("place", ["map", "지도", "place", "location", "영업", "리뷰", "별점", "맛집", "길찾기", "주소", "navi", "네이버지도", "카카오맵"]),
            ("tech", ["api", "코드", "개발", "programming", "code", "software", "github", "stack overflow"]),
            ("sns", ["instagram", "twitter", "threads", "facebook", "post", "like", "share", "follow", "comment", "좋아요", "팔로우", "댓글", "feed", "timeline"])
        ]
        
        var scores: [String: Int] = [:]
        
        for (type, keywords) in patterns {
            let score = keywords.reduce(0) { count, keyword in
                count + (fullText.contains(keyword) ? 1 : 0)
            }
            scores[type] = score
        }
        
        // ✨ NEW: shopping은 최소 2개 이상 매칭되어야 함 (오탐 방지)
        if let shoppingScore = scores["shopping"], shoppingScore < 2 {
            scores["shopping"] = 0
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
        
        // 폴백 1: 타이틀 패턴 매칭 (레이아웃 없을 때)
        let candidates = textBlocks.prefix(5)
        for block in candidates {
            if let text = block["text"] as? String {
                let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                // 제목 패턴: 적당한 길이 + 문장부호 없음 + 특정 키워드(TOP, Insight 등)
                if cleaned.count > 5 && cleaned.count < 60 && !cleaned.hasSuffix(".") {
                    if cleaned.range(of: "(TOP|Insight|Summary|Best|Key|Guide|Review|vs|Top\\d+)", options: .regularExpression) != nil {
                         return cleanTitle(cleaned)
                    }
                    // 한글 제목 패턴 (조사로 끝나지 않음 등 - 간단히 길이만 체크)
                }
            }
        }
        
        // 폴백 2: 첫 섹션 or 첫 줄
        if let firstSection = layout.contentSections.first {
            let text = firstSection
                .compactMap { $0["text"] as? String }
                .joined(separator: " ")
            // 첫 줄이 너무 길지 않으면 제목으로 사용
            if text.count < 60 {
                return cleanTitle(text)
            }
        }
        
        // 최후의 수단: 첫 번째 유효 블록
        if let first = textBlocks.first(where: { ($0["text"] as? String)?.count ?? 0 > 5 }),
           let text = first["text"] as? String {
            return cleanTitle(text)
        }
        
        return "New Memory"
    }
    
    private func cleanTitle(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ✨ NEW: 단일 알파벳 제거 (E, A 등)
        cleaned = cleaned.replacingOccurrences(
            of: "^[A-Z]\\s+",
            with: "",
            options: .regularExpression
        )
        
        // ✨ NEW: 숫자) 패턴 제거
        cleaned = cleaned.replacingOccurrences(
            of: "^\\d+\\)\\s*",
            with: "",
            options: .regularExpression
        )
        
        // ✨ NEW: blog, post 단독 단어 제거
        cleaned = cleaned.replacingOccurrences(
            of: "^(blog|post)\\s+",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // URL 제거 (기존)
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
        contentType: String,
        title: String
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
        
        var result = topSentences.map { $0.0 }.joined(separator: " ")
        print("[EnhancedContentAnalyzer] Final summary: \(result)")
        
        if result.isEmpty {
             result = String(fullText.prefix(150)) + "..."
        }
        
        // Content Type Specific Templates
        if !title.isEmpty && title != "New Memory" {
            switch contentType {
            case "place":
                // 맛집/장소 템플릿
                return "해당 링크는 '\(title)'의 위치 및 정보를 담고 있습니다.\n\n" + result
                
            case "shopping":
                // 쇼핑 템플릿 (가격 정보 추출 시도)
                var priceInfo = ""
                if let priceMatch = fullText.range(of: "[0-9,]+(원|\\$)", options: .regularExpression) {
                    let price = String(fullText[priceMatch])
                    priceInfo = " (가격: \(price))"
                }
                return "해당 링크는 '\(title)' 판매 페이지입니다.\(priceInfo)\n\n" + result
                
            case "news", "tech":
                // 뉴스/테크 템플릿
                return "해당 링크는 '\(title)' 내용을 설명한 글로, 주요 인사이트를 전달하고 있습니다.\n\n" + result
                
            case "sns":
                // SNS 템플릿
                return "해당 링크는 '\(title)' 내용을 설명한 글로, 주요 인사이트를 전달하고 있습니다.\n\n" + result
                
            default:
                break
            }
        }
        
        return result
        
        return result
    }
    
    private func scoreSentence(_ sentence: String, fullText: String, contentType: String) -> Double {
        var score = 0.0

        print("[EnhancedContentAnalyzer] Scoring: '\(sentence.prefix(50))...'")

        let trimmed = sentence.trimmingCharacters(in: .whitespaces)
        
        // ✨ NEW: 노이즈 패턴들 (큰 감점)
        let noisePatterns = [
            "Search",           // UI 요소
            "matters",          // 사이트 이름
            "이미지 출처",       // 메타데이터
            "출처:",
            "유튜브",
            "블로그",
            "\\.\\.\\.$",       // "..." 으로 끝남
        ]
        
        for pattern in noisePatterns {
            if trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                print("[EnhancedContentAnalyzer]   - Noise pattern '\(pattern)': -15.0")
                score -= 15.0
            }
        }

        // ✨ NEW: 문장이 숫자나 노이즈로 시작하면 큰 감점
        if trimmed.range(of: "^\\d+\\)", options: .regularExpression) != nil {
            // "924) blog..." 같은 것
            print("[EnhancedContentAnalyzer]   - Starts with number: -10.0")
            score -= 10.0
        }
        
        if trimmed.lowercased().hasPrefix("blog ") || trimmed.lowercased().hasPrefix("post ") {
            print("[EnhancedContentAnalyzer]   - Starts with 'blog/post': -5.0")
            score -= 5.0
        }

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

    // MARK: - Extract Insights (NEW!)

    private func extractInsights(
        from blocks: [[String: Any]],
        contentType: String
    ) -> [String] {
        var insights: [String] = []
        
        let fullText = blocks
            .compactMap { $0["text"] as? String }
            .joined(separator: " ")
        
        // 1. 가격 정보
        if let prices = extractMatches(
            from: fullText,
            pattern: "(\\d{1,3}(,\\d{3})*원|\\$\\d+(\\.\\d{2})?|€\\d+)",
            limit: 3
        ) {
            insights.append(contentsOf: prices)
        }
        
        // 2. 날짜 정보
        let datePatterns = [
            "\\d{4}[-\\/\\.]\\d{1,2}[-\\/\\.]\\d{1,2}",  // 2026-01-26
            "\\d{1,2}월\\s*\\d{1,2}일",                   // 1월 26일
        ]
        
        for pattern in datePatterns {
            if let dates = extractMatches(from: fullText, pattern: pattern, limit: 2) {
                insights.append(contentsOf: dates)
            }
        }
        
        // 3. 주문번호/모델번호
        if let codes = extractMatches(
            from: fullText,
            pattern: "(주문번호|모델번호|상품번호|운송장)[\\s:：]*([A-Z0-9\\-]{5,})",
            limit: 2
        ) {
            insights.append(contentsOf: codes)
        }
        
        // 4. 배송 정보
        if fullText.contains("배송") || fullText.contains("도착") {
            if let delivery = extractMatches(
                from: fullText,
                pattern: ".{0,30}(배송|도착|예정).{0,30}",
                limit: 1
            ) {
                insights.append(contentsOf: delivery)
            }
        }
        
        // 5. 콘텐츠 타입별 추가 정보
        switch contentType {
        case "shopping":
            // 할인율
            if let discount = extractMatches(
                from: fullText,
                pattern: "\\d+%\\s*(할인|OFF|DC)",
                limit: 1
            ) {
                insights.append(contentsOf: discount)
            }
        case "travel":
            // 시간 정보
            if let time = extractMatches(
                from: fullText,
                pattern: "(체크인|체크아웃)[\\s:：]*\\d{1,2}:\\d{2}",
                limit: 2
            ) {
                insights.append(contentsOf: time)
            }
        default:
            break
        }
        
        return Array(insights.prefix(5))
    }



    // Helper: 정규식 매칭 추출
    private func extractMatches(
        from text: String,
        pattern: String,
        limit: Int
    ) -> [String]? {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return nil
        }
        
        let matches = regex.matches(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        )
        
        var results: [String] = []
        for match in matches.prefix(limit) {
            if let range = Range(match.range, in: text) {
                let matched = String(text[range])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !results.contains(matched) && matched.count > 1 {
                    results.append(matched)
                }
            }
        }
        
        return results.isEmpty ? nil : results
    }

    // MARK: - Generate Refined Text

    private func generateRefinedText(from blocks: [[String: Any]]) -> String {
        // Y 좌표로 정렬
        let sorted = blocks.sorted { (b1, b2) -> Bool in
            let y1 = b1["top"] as? Double ?? 0
            let y2 = b2["top"] as? Double ?? 0
            return y1 < y2
        }
        
        var paragraphs: [String] = []
        var currentParagraph: [String] = []
        var lastY: Double = 0
        
        for block in sorted {
            guard let text = block["text"] as? String,
                  let y = block["top"] as? Double,
                  let height = block["height"] as? Double else {
                continue
            }
            
            let gap = y - lastY
            let threshold = height * 1.5
            
            // 간격이 크면 새 문단
            if !currentParagraph.isEmpty && gap > threshold {
                let paragraph = currentParagraph
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !paragraph.isEmpty {
                    paragraphs.append(paragraph)
                }
                currentParagraph = []
            }
            
            currentParagraph.append(text)
            lastY = y + height
        }
        
        // 마지막 문단
        if !currentParagraph.isEmpty {
            let paragraph = currentParagraph
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !paragraph.isEmpty {
                paragraphs.append(paragraph)
            }
        }
        
        return paragraphs.joined(separator: "\n\n")
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
