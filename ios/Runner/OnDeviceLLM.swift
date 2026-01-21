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

    private func enhancedNLPAnalysis(title: String?, paragraphs: [String], keyPoints: [String], language: NLLanguage?) -> [String: Any] {
        // 1. 스마트 제목 생성
        // 기존 제목이 "New Memory"거나 없으면 새로 생성
        var finalTitle = title ?? "New Memory"
        if finalTitle.isEmpty || finalTitle == "New Memory" || finalTitle == "Web Link" {
            finalTitle = generateSmartTitle(from: paragraphs, language: language)
        }

        // 2. 핵심 요약 생성 (문맥 + 위치 기반)
        let summary = generateContextualSummary(paragraphs: paragraphs, language: language)

        // 3. 핵심 인사이트 추출 (개체명 + 패턴 기반)
        var insights = keyPoints.prefix(4).map { String($0) }
        // 기존 keyPoints가 부족하면 추가 추출
        if insights.count < 3 {
             let extracted = extractKeyInsights(from: paragraphs, language: language)
             // 중복 제거 후 병합
             for item in extracted {
                 if !insights.contains(item) && insights.count < 4 {
                     insights.append(item)
                 }
             }
        }

        return [
            "title": finalTitle,
            "summary": summary,
            "keyInsights": insights
        ]
    }

    // MARK: - 스마트 제목 생성 (강화)

    /// NLP 기반 스마트 제목 생성 - 핵심 내용 중심
    private func generateSmartTitle(from paragraphs: [String], language: NLLanguage?) -> String {
        guard !paragraphs.isEmpty else { return "New Memory" }

        // 1순위: 첫 번째 문단이 짧고 명사 위주라면 제목일 가능성 높음
        if let first = paragraphs.first {
            if isLikelyTitle(first, language: language) {
                return truncateToTitle(first, maxLength: 40)
            }
        }
        
        // 2순위: 상위 3개 문단 중에서 가장 제목스러운 후보 찾기
        // (길이, 대문자 비율, 명사 비율 등으로 점수화)
        let candidates = paragraphs.prefix(5)
        var bestCandidate = (text: "", score: -1.0)
        
        for para in candidates {
            let score = scoreTitleCandidate(para, language: language)
            if score > bestCandidate.score {
                bestCandidate = (para, score)
            }
        }
        
        if bestCandidate.score > 10 { // 최소 임계점
             return truncateToTitle(bestCandidate.text, maxLength: 40)
        }

        // 3순위: NLP로 핵심 명사구(Keyword) 추출
        let keyPhrase = extractKeyPhrase(from: paragraphs, language: language)
        if !keyPhrase.isEmpty && keyPhrase.count >= 3 {
            return truncateToTitle(keyPhrase, maxLength: 35).capitalized
        }

        return "New Memory"
    }
    
    /// 텍스트가 제목처럼 보이는지 판단
    private func isLikelyTitle(_ text: String, language: NLLanguage?) -> Bool {
        let count = text.count
        // 너무 짧거나 길면 제목 아님
        if count < 3 || count > 60 { return false }
        
        // URL 등은 제외
        if text.contains("http") || text.contains("www.") { return false }
        
        // 문장 부호(. ! ?)로 끝나면 보통 문장임 (제목 아님)
        let lastChar = text.last
        if lastChar == "." || lastChar == "!" || lastChar == "?" { return false }
        
        return true
    }

    /// 제목 후보 점수 계산 (개선됨)
    private func scoreTitleCandidate(_ text: String, language: NLLanguage?) -> Double {
        var score: Double = 0
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. 길이 점수 (짧고 간결한 것이 좋음, 5~30자)
        let length = cleaned.count
        if length >= 5 && length <= 35 {
            score += 20
        } else if length > 35 && length <= 60 {
            score += 10
        } else {
            score -= 10 // 너무 길거나 짧음
        }

        // 2. 불용어/노이즈 체크
        if isUINoiseText(cleaned) { return -100 }
        
        // 3. 언어적 특성 분석 (명사 비율)
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = cleaned
        var nounCount = 0
        var wordCount = 0
        
        tagger.enumerateTags(in: cleaned.startIndex..<cleaned.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
            wordCount += 1
            if tag == .noun || tag == .personalName || tag == .organizationName || tag == .placeName {
                nounCount += 1
            }
            return true
        }
        
        if wordCount > 0 {
            let nounRatio = Double(nounCount) / Double(wordCount)
            if nounRatio > 0.6 { score += 15 } // 명사 위주면 제목일 확률 높음
        }
        
        // 4. 날짜/금액 패턴 (영수증 제목 등)
        if cleaned.range(of: "\\d{4}[-.]\\d{2}", options: .regularExpression) != nil { // 2024.01 형태
            score += 5
        }
        
        return score
    }

    /// 핵심 명사구 추출
    private func extractKeyPhrase(from paragraphs: [String], language: NLLanguage?) -> String {
        let allText = paragraphs.prefix(3).joined(separator: " ")
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = allText

        var counts: [String: Int] = [:]

        tagger.enumerateTags(in: allText.startIndex..<allText.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange in
            let word = String(allText[tokenRange])
            if word.count < 2 { return true }
            
            // 명사 또는 고유명사만 카운트
            if tag == .noun || tag == .personalName || tag == .organizationName || tag == .placeName {
                 counts[word, default: 0] += 1
            }
            return true
        }
        
        // 가장 많이 등장한 명사 (빈도수 기반)
        if let topWord = counts.sorted(by: { $0.value > $1.value }).first {
             return topWord.key
        }

        return ""
    }

    /// UI 노이즈 텍스트인지 확인
    private func isUINoiseText(_ text: String) -> Bool {
        let lower = text.lowercased()
        
        // 시간 (00:00), 배터리 (100%), 수치 등
        if text.range(of: "^\\d{1,2}:\\d{2}", options: .regularExpression) != nil { return true }
        if text.range(of: "^\\d{1,3}%$", options: .regularExpression) != nil { return true }
        
        // UI 키워드 목록
        let uiKeywords = ["back", "settings", "menu", "home", "edit", "share", "cancel", "done", "search",
                          "뒤로", "설정", "메뉴", "홈", "편집", "공유", "취소", "완료", "검색", "좋아요", "댓글"]
        
        if uiKeywords.contains(lower) { return true }
        
        return false
    }

    /// 제목 길이로 자르기
    private func truncateToTitle(_ text: String, maxLength: Int) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= maxLength { return cleaned }
        return String(cleaned.prefix(maxLength - 3)) + "..."
    }

    // MARK: - 문맥 기반 요약 생성

    /// 문맥을 파악하여 핵심 내용을 요약
    private func generateContextualSummary(paragraphs: [String], language: NLLanguage?) -> String {
        guard !paragraphs.isEmpty else { return "No text detected." }
        
        // 문단이 하나뿐이면 그 자체가 요약
        if paragraphs.count == 1 {
            return truncateSummary(paragraphs[0])
        }

        var candidates: [(text: String, score: Double)] = []
        
        // 각 문단(또는 긴 문장)에 대해 중요도 점수 계산
        // 앞쪽 문단에 가중치 부여 (두괄식 문서를 가정)
        for (index, para) in paragraphs.prefix(8).enumerated() {
            // 문단 내에서 문장 분리
            let sentences = splitIntoSentences(para)
            
            for sentence in sentences {
                let baseScore = scoreSentence(sentence, language: language)
                // 위치 가중치: 첫 문단(0)은 1.5배, 그 뒤는 점차 감소
                let positionMultiplier = max(1.0, 1.5 - (Double(index) * 0.1))
                let finalScore = baseScore * positionMultiplier
                
                candidates.append((sentence, finalScore))
            }
        }
        
        // 점수 순 정렬
        candidates.sort { $0.score > $1.score }
        
        // 상위 2개 문장 선택 및 원래 순서대로 정렬 (흐름 유지)
        // (원래 순서를 찾기 위해 index를 같이 저장했어야 하나, 간단히 상위 문장 연결로 처리)
        let topSentences = candidates.prefix(2).map { $0.text }
        
        // 중복 내용 제거 (포함 관계 확인)
        var finalSentences: [String] = []
        for s in topSentences {
             if !finalSentences.contains(where: { $0.contains(s) || s.contains($0) }) {
                 finalSentences.append(s)
             }
        }
        
        let combined = finalSentences.joined(separator: " ")
        if combined.isEmpty {
             return truncateSummary(paragraphs.first ?? "")
        }
        return truncateSummary(combined)
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        // 간단한 정규식 기반 문장 분리
        // (완벽하지 않으나 온디바이스 성능 고려)
        return text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 10 } // 너무 짧은 문장 제외
    }

    private func truncateSummary(_ text: String) -> String {
        if text.count > 150 {
            return String(text.prefix(147)) + "..."
        }
        return text
    }

    /// 문장 중요도 점수 계산
    private func scoreSentence(_ sentence: String, language: NLLanguage?) -> Double {
        var score: Double = 0
        let count = sentence.count
        
        // 1. 길이 점수 (적당한 길이 정보량 20~100자)
        if count >= 20 && count <= 100 {
            score += 10
        } else if count < 10 {
            return 0 // 너무 짧으면 무시
        }

        // 2. 키워드 포함 여부 (중요, 결론, 요약, 합계 등)
        let keywords = ["important", "summary", "conclusion", "total", "note", "중요", "요약", "결론", "합계", "참고"]
        let lower = sentence.lowercased()
        for key in keywords {
            if lower.contains(key) { score += 20 }
        }
        
        // 3. 개체명 인식 (Entity Recognition) - 구체적인 정보가 있는 문장 우대
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = sentence
        var entityCount = 0
        
        tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
             if tag == .noun || tag == .verb { entityCount += 1 } // 명사/동사가 많으면 정보량이 많음
             return true
        }
        // 고유 명사 체크 (이름, 장소, 조직)
        tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .nameType, options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
            if tag != nil { entityCount += 2 } // 고유명사는 더 높은 가중치
            return true
        }
        
        score += Double(entityCount)
        
        // 4. 감점 요소 (URL, 질문 등)
        if lower.contains("http") { score -= 10 }
        if lower.contains("?") { score -= 5 } // 질문보다는 평서문 선호

        return score
    }

    // MARK: - 핵심 인사이트 추출

    /// NLP 기반 핵심 인사이트(Key Insight) 추출
    private func extractKeyInsights(from paragraphs: [String], language: NLLanguage?) -> [String] {
        var insights: [String] = []
        
        // 1. 불렛 포인트/번호 매기기 감지 (목록형 정보는 핵심일 확률 높음)
        for para in paragraphs {
            let trimmed = para.trimmingCharacters(in: .whitespaces)
            // "-", "•", "1." 등으로 시작하는 라인
            if trimmed.range(of: "^[-•*#] |^\\d+\\.", options: .regularExpression) != nil {
                 if trimmed.count > 5 && trimmed.count < 80 {
                     insights.append(trimmed)
                 }
            }
        }
        if insights.count >= 3 { return Array(insights.prefix(4)) }

        // 2. 개체명(Entity) 기반 추출 (날짜, 금액, 장소)
        // 전체 텍스트에서 중요한 단편 정보 추출
        let allText = paragraphs.prefix(10).joined(separator: "\n")
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = allText
        
        // 금액 추출 (Regex) - "$123" or "10,000원"
        if let match = allText.range(of: "[\\$₩]\\d+([,\\.]\\d+)?|\\d+([,\\.]\\d+)?원", options: .regularExpression) {
            let amount = String(allText[match])
            if !insights.contains(where: { $0.contains(amount) }) {
                 insights.append("Amount: \(amount)")
            }
        }
        
        // 날짜 추출 (Regex) - 간단한 연-월-일
        if let match = allText.range(of: "\\d{4}[-./]\\d{1,2}[-./]\\d{1,2}", options: .regularExpression) {
             let date = String(allText[match])
             if !insights.contains(where: { $0.contains(date) }) {
                 insights.append("Date: \(date)")
             }
        }
        
        // 3. 점수가 높은 짧은 문장 추가
        if insights.count < 4 {
             var sentenceCandidates: [(String, Double)] = []
             for para in paragraphs.prefix(5) {
                 for s in splitIntoSentences(para) {
                     if s.count < 60 { // 짧고 강렬한 문장 선호
                         sentenceCandidates.append((s, scoreSentence(s, language: language)))
                     }
                 }
             }
             sentenceCandidates.sort{ $0.1 > $1.1 }
             
             for (cand, _) in sentenceCandidates {
                 if !insights.contains(cand) {
                     insights.append(cand)
                 }
                 if insights.count >= 4 { break }
             }
        }

        return Array(insights.prefix(4))
    }
}

