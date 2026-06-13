import Foundation

struct WordbookCategory: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let language: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case language
    }
}

struct StudyWord: Identifiable, Codable, Hashable {
    var id: String { word.lowercased() }
    let word: String
    let exp: String?
    let addTime: String?
    let star: Int?
    let contextLine: String?
    let categoryIds: [String]?

    enum CodingKeys: String, CodingKey {
        case word
        case exp
        case addTime = "add_time"
        case star
        case contextLine = "context_line"
        case categoryIds = "category_ids"
    }

    init(
        word: String,
        exp: String?,
        addTime: String?,
        star: Int?,
        contextLine: String?,
        categoryIds: [String]?
    ) {
        self.word = word
        self.exp = exp
        self.addTime = addTime
        self.star = star
        self.contextLine = contextLine
        self.categoryIds = categoryIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        word = try container.decode(String.self, forKey: .word)
        exp = try container.decodeIfPresent(String.self, forKey: .exp)
        addTime = try container.decodeIfPresent(String.self, forKey: .addTime)
        star = try container.decodeIfPresent(Int.self, forKey: .star)
        contextLine = try container.decodeIfPresent(String.self, forKey: .contextLine)

        if let stringIds = try? container.decodeIfPresent([String].self, forKey: .categoryIds) {
            categoryIds = stringIds
        } else if let integerIds = try? container.decodeIfPresent([Int].self, forKey: .categoryIds) {
            categoryIds = integerIds.map(String.init)
        } else {
            categoryIds = nil
        }
    }

    var needsExplanation: Bool {
        exp?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false
    }

    func mergingDetails(from detail: StudyWord) -> StudyWord {
        StudyWord(
            word: word,
            exp: detail.needsExplanation ? exp : detail.exp,
            addTime: detail.addTime ?? addTime,
            star: detail.star ?? star,
            contextLine: detail.contextLine ?? contextLine,
            categoryIds: detail.categoryIds ?? categoryIds
        )
    }

    var displayExplanation: String? {
        guard let exp, !exp.isEmpty else { return nil }
        return exp
            .replacingOccurrences(of: "<br />", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<br/>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "&nbsp;", with: " ", options: .caseInsensitive)
    }
}

struct EudicEnvelope<Value: Decodable>: Decodable {
    let data: Value?
    let message: String?
}

enum QuizGrade: String {
    case correct = "正确"
    case close = "接近"
    case incorrect = "需要复习"

    var isPassing: Bool { self == .correct || self == .close }
}

struct MeaningResult {
    let grade: QuizGrade
    let explanation: String
}

struct PronunciationResult {
    let grade: QuizGrade
    let transcript: String
    let explanation: String
}

enum PracticeKind: String, Codable, Hashable {
    case meaning
    case pronunciation
}

struct LearningProgressSection: Identifiable {
    let id: String
    let title: String
    let totalCount: Int
    let meaningWords: [StudyWord]
    let pronunciationWords: [StudyWord]
}
