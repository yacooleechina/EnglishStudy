import Foundation

enum BuiltinVocabularyBook: String, CaseIterable, Identifiable {
    case highSchool
    case cet4
    case cet6
    case toefl

    var id: String { "builtin:\(rawValue)" }

    var title: String {
        switch self {
        case .highSchool: return "高中词汇"
        case .cet4: return "大学英语四级"
        case .cet6: return "大学英语六级"
        case .toefl: return "托福词汇"
        }
    }

    var shortTitle: String {
        switch self {
        case .highSchool: return "高中"
        case .cet4: return "四级"
        case .cet6: return "六级"
        case .toefl: return "托福"
        }
    }

    var resourceName: String {
        switch self {
        case .highSchool: return "high-school"
        case .cet4: return "cet4"
        case .cet6: return "cet6"
        case .toefl: return "toefl"
        }
    }

    var systemImage: String {
        switch self {
        case .highSchool: return "graduationcap"
        case .cet4: return "4.circle"
        case .cet6: return "6.circle"
        case .toefl: return "globe.americas"
        }
    }

    var category: WordbookCategory {
        WordbookCategory(id: id, name: title, language: "en")
    }

    static func book(forCategoryId id: String?) -> BuiltinVocabularyBook? {
        guard let id else { return nil }
        return allCases.first { $0.id == id }
    }
}

enum VocabularyBookStore {
    private static var cache: [BuiltinVocabularyBook: [StudyWord]] = [:]

    static func words(for book: BuiltinVocabularyBook) throws -> [StudyWord] {
        if let cached = cache[book] {
            return cached
        }
        guard let url = Bundle.main.url(
            forResource: book.resourceName,
            withExtension: "json"
        ) else {
            throw VocabularyBookError.missingResource(book.title)
        }
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let words = try JSONDecoder().decode([StudyWord].self, from: data)
        cache[book] = words
        return words
    }

    static func count(for book: BuiltinVocabularyBook) -> Int {
        (try? words(for: book).count) ?? 0
    }
}

enum VocabularyBookError: LocalizedError {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let title):
            return "找不到“\(title)”的内置词书文件。"
        }
    }
}
