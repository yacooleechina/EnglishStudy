import Foundation

struct EudicClient {
    var authorization: String
    var language: String = "en"

    private let baseURL = URL(string: "https://api.frdic.com/api/open/v1")!
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration)
    }()

    func categories() async throws -> [WordbookCategory] {
        let request = try makeRequest(
            path: "studylist/category",
            queryItems: [URLQueryItem(name: "language", value: language)]
        )
        let envelope = try await decode(EudicEnvelope<[WordbookCategory]>.self, from: request)
        return envelope.data ?? []
    }

    func words(categoryId: String? = nil, page: Int = 0, pageSize: Int = 100) async throws -> [StudyWord] {
        var query = [
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize))
        ]
        if let categoryId, !categoryId.isEmpty {
            query.append(URLQueryItem(name: "category_id", value: categoryId))
        }
        let request = try makeRequest(path: "studylist/words", queryItems: query)
        let envelope = try await decode(EudicEnvelope<[StudyWord]>.self, from: request)
        return envelope.data ?? []
    }

    func allWords(categoryId: String? = nil, pageSize: Int = 100) async throws -> [StudyWord] {
        var page = 0
        var allWords: [StudyWord] = []
        var seenWordIds = Set<String>()
        var previousPageIds: [String]?

        while true {
            let pageWords = try await words(
                categoryId: categoryId,
                page: page,
                pageSize: pageSize
            )
            let pageIds = pageWords.map(\.id)

            guard !pageWords.isEmpty, pageIds != previousPageIds else {
                break
            }

            let enrichedPageWords = await fillMissingExplanations(in: pageWords)
            for word in enrichedPageWords where seenWordIds.insert(word.id).inserted {
                allWords.append(word)
            }

            guard pageWords.count == pageSize else {
                break
            }

            previousPageIds = pageIds
            page += 1
        }

        return allWords
    }

    func word(_ word: String) async throws -> StudyWord? {
        let request = try makeRequest(
            path: "studylist/word",
            queryItems: [
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "word", value: word)
            ]
        )
        if let item = try? await decode(StudyWord.self, from: request) {
            return item
        }
        let envelope = try await decode(EudicEnvelope<StudyWord>.self, from: request)
        return envelope.data
    }

    private func fillMissingExplanations(in words: [StudyWord]) async -> [StudyWord] {
        var enrichedWords = words
        let missingIndices = words.indices.filter { words[$0].needsExplanation }
        let batchSize = 4

        for batchStart in stride(from: 0, to: missingIndices.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, missingIndices.count)
            let batchIndices = Array(missingIndices[batchStart..<batchEnd])

            let details = await withTaskGroup(
                of: (Int, StudyWord?).self,
                returning: [(Int, StudyWord?)].self
            ) { group in
                for index in batchIndices {
                    let wordText = words[index].word
                    group.addTask {
                        let detail = try? await self.word(wordText)
                        return (index, detail)
                    }
                }

                var results: [(Int, StudyWord?)] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }

            for (index, detail) in details {
                if let detail {
                    enrichedWords[index] = enrichedWords[index].mergingDetails(from: detail)
                }
            }
        }

        return enrichedWords
    }

    private func makeRequest(path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        let normalizedAuthorization = authorization.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedAuthorization.isEmpty else {
            throw EudicError.missingAuthorization
        }
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw EudicError.invalidURL }
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 20
        )
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue(normalizedAuthorization, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func decode<Value: Decodable>(_ type: Value.Type, from request: URLRequest) async throws -> Value {
        let (data, response) = try await Self.session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw EudicError.invalidResponse }
        guard 200..<300 ~= httpResponse.statusCode else {
            let body = String(decoding: data, as: UTF8.self)
            throw EudicError.server(status: httpResponse.statusCode, body: body)
        }
        return try JSONDecoder().decode(type, from: data)
    }
}

enum EudicError: LocalizedError {
    case missingAuthorization
    case invalidURL
    case invalidResponse
    case server(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .missingAuthorization:
            return "请先填写欧路 OpenAPI Authorization。"
        case .invalidURL:
            return "欧路 API 地址无效。"
        case .invalidResponse:
            return "欧路 API 返回无效响应。"
        case .server(let status, let body):
            return "欧路 API 返回 \(status)：\(body)"
        }
    }
}
