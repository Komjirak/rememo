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
        
        return blocks.filter { block in
            guard let text = block["text"] as? String,
                  let top = block["top"] as? Double,
                  let confidence = block["confidence"] as? Double else {
                return false
            }
            
            // 1. 신뢰도 필터
            if confidence < 0.6 { return false }
            
            // 2. 위치 필터 (상단 5%, 하단 10%)
            if top < 0.05 || top > 0.90 { return false }
            
            // 3. 길이 필터 (너무 짧으면 노이즈)
            if text.count < 2 { return false }
            
            // 4. 패턴 필터
            let noisePatterns = [
                "^\\d{1,2}:\\d{2}$",  // 시간
                "^\\d{1,3}%$",         // 배터리
                "^Back$", "^Close$", "^Menu$",  // UI 버튼
                "^AD$", "^광고$", "^Sponsored$" // 광고
            ]
            
            for pattern in noisePatterns {
                if text.range(of: pattern, options: .regularExpression) != nil {
                    return false
                }
            }
            
            return true
        }
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
        
        let fullText = textBlocks
            .compactMap { $0["text"] as? String }
            .joined(separator: " ")
        
        // NLTagger로 문장 분리
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = fullText
        
        var sentences: [(String, Double)] = []
        
        tagger.enumerateTokens(in: fullText.startIndex..<fullText.endIndex, unit: .sentence, scheme: .tokenType) { _, range in
            let sentence = String(fullText[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                let score = scoreSentence(sentence, fullText: fullText, contentType: contentType)
                sentences.append((sentence, score))
            }
            return true
        }
        
        // 상위 2-3개 문장
        let topSentences = sentences
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0.0 }
        
        return topSentences.isEmpty ? fullText.prefix(150) + "..." : topSentences.joined(separator: " ")
    }
    
    private func scoreSentence(_ sentence: String, fullText: String, contentType: String) -> Double {
        var score = 0.0
        
        // 길이 점수
        let length = sentence.count
        if length > 20 && length < 150 {
            score += 1.0
        }
        
        // 키워드 점수
        let keywords = getKeywordsForType(contentType)
        let matchCount = keywords.filter { sentence.lowercased().contains($0) }.count
        score += Double(matchCount) * 0.5
        
        // 위치 점수 (앞부분 우대)
        if fullText.hasPrefix(sentence) {
            score += 0.3
        }
        
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
        
        let fullText = textBlocks
            .compactMap { $0["text"] as? String }
            .joined(separator: " ")
        
        var tags: Set<String> = []
        
        // 1. 콘텐츠 타입
        if contentType != "general" {
            tags.insert(contentType)
        }
        
        // 2. NLTagger로 명사 추출
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = fullText
        
        var nouns: [String: Int] = [:]
        
        tagger.enumerateTags(
            in: fullText.startIndex..<fullText.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            if tag == .noun {
                let word = String(fullText[range])
                if word.count >= 2 && !isStopword(word) {
                    nouns[word, default: 0] += 1
                }
            }
            return true
        }
        
        // 빈도순 상위 4개
        let topNouns = nouns
            .sorted { $0.value > $1.value }
            .prefix(4)
            .map { $0.key }
        
        for noun in topNouns {
            tags.insert(noun)
        }
        
        return Array(tags).prefix(5).map { $0 }
    }
    
    private func isStopword(_ word: String) -> Bool {
        let stopwords: Set<String> = ["것", "수", "등", "때문", "경우", "the", "a", "an", "is", "of", "to", "in", "for"]
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
