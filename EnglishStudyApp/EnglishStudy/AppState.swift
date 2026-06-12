import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: Self.usernameKey)
        }
    }
    @Published var authorization: String
    @Published var categories: [WordbookCategory] = []
    @Published var words: [StudyWord] = []
    @Published private(set) var archivedWords: [StudyWord] = []
    @Published var selectedCategoryId: String?
    @Published var currentIndex = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var hasAttemptedInitialSync = false
    private var successCounts: [String: Int] = [:]
    private var pendingArchiveIds = Set<String>()

    private static let usernameKey = "eudic.username"
    private static let archiveCategoryName = "已归档单词"
    private static let archivedWordsKey = "study.archivedWords"
    private static let successCountsKey = "study.successCounts"
    private static let pendingArchiveIdsKey = "study.pendingArchiveIds"
    private static let archiveThreshold = 3

    init() {
        let savedUsername = UserDefaults.standard.string(forKey: Self.usernameKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        username = savedUsername ?? ""

        let savedAuthorization = KeychainStore.loadAuthorization()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        authorization = savedAuthorization

        if let data = UserDefaults.standard.data(forKey: Self.archivedWordsKey),
           let savedWords = try? JSONDecoder().decode([StudyWord].self, from: data) {
            archivedWords = savedWords
        }
        if let data = UserDefaults.standard.data(forKey: Self.successCountsKey),
           let savedCounts = try? JSONDecoder().decode([String: Int].self, from: data) {
            successCounts = savedCounts
        }
        if let savedIds = UserDefaults.standard.stringArray(forKey: Self.pendingArchiveIdsKey) {
            pendingArchiveIds = Set(savedIds)
        }
    }

    var client: EudicClient {
        EudicClient(authorization: authorization)
    }

    var currentWord: StudyWord? {
        guard words.indices.contains(currentIndex) else { return nil }
        return words[currentIndex]
    }

    var practiceCategories: [WordbookCategory] {
        categories.filter { $0.name != Self.archiveCategoryName }
    }

    func saveAuthorization() {
        do {
            let normalizedAuthorization = authorization.trimmingCharacters(in: .whitespacesAndNewlines)
            authorization = normalizedAuthorization
            try KeychainStore.saveAuthorization(normalizedAuthorization)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sync(refreshCategories: Bool = true) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var archiveSyncWarning: String?
            if refreshCategories {
                categories = try await client.categories()
            }

            if !pendingArchiveIds.isEmpty {
                archiveSyncWarning = await retryPendingArchives()
            }

            if let archiveCategory = categories.first(where: { $0.name == Self.archiveCategoryName }) {
                let remoteArchivedWords = try await client.allWords(categoryId: archiveCategory.id)
                mergeArchivedWords(remoteArchivedWords)
            }

            let syncedWords = try await client.allWords(categoryId: selectedCategoryId)
            let archivedIds = Set(archivedWords.map(\.id))
            words = syncedWords.filter { !archivedIds.contains($0.id) }
            currentIndex = 0
            errorMessage = archiveSyncWarning
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func syncOnLaunch() async {
        guard !hasAttemptedInitialSync, !authorization.isEmpty else { return }
        hasAttemptedInitialSync = true
        await sync()
    }

    func nextWord() {
        guard !words.isEmpty else { return }
        currentIndex = (currentIndex + 1) % words.count
    }

    func successfulChecks(for item: StudyWord) -> Int {
        successCounts[item.id, default: 0]
    }

    func recordCorrectCheck(for item: StudyWord) async -> Bool {
        if archivedWords.contains(where: { $0.id == item.id }) {
            return true
        }

        let newCount = min(Self.archiveThreshold, successfulChecks(for: item) + 1)
        successCounts[item.id] = newCount
        saveProgress()

        guard newCount >= Self.archiveThreshold else {
            return false
        }

        archiveLocally(item)

        do {
            let archiveCategory = try await ensureArchiveCategory()
            try await client.archive(item, categoryId: archiveCategory.id)
            pendingArchiveIds.remove(item.id)
            saveProgress()
        } catch {
            pendingArchiveIds.insert(item.id)
            saveProgress()
            errorMessage = "单词已在本机归档，但同步到欧路失败：\(error.localizedDescription)"
        }
        return true
    }

    private func archiveLocally(_ item: StudyWord) {
        if !archivedWords.contains(where: { $0.id == item.id }) {
            archivedWords.insert(item, at: 0)
        }

        if let index = words.firstIndex(where: { $0.id == item.id }) {
            words.remove(at: index)
            if words.isEmpty {
                currentIndex = 0
            } else if currentIndex >= words.count {
                currentIndex = 0
            }
        }
        saveProgress()
    }

    private func mergeArchivedWords(_ remoteWords: [StudyWord]) {
        var archivedById = Dictionary(uniqueKeysWithValues: archivedWords.map { ($0.id, $0) })
        for item in remoteWords {
            archivedById[item.id] = item
            successCounts[item.id] = Self.archiveThreshold
            pendingArchiveIds.remove(item.id)
        }
        archivedWords = archivedById.values.sorted {
            ($0.addTime ?? "") > ($1.addTime ?? "")
        }
        saveProgress()
    }

    private func ensureArchiveCategory() async throws -> WordbookCategory {
        if let category = categories.first(where: { $0.name == Self.archiveCategoryName }) {
            return category
        }
        let category = try await client.createCategory(name: Self.archiveCategoryName)
        categories.append(category)
        return category
    }

    private func retryPendingArchives() async -> String? {
        do {
            let archiveCategory = try await ensureArchiveCategory()
            for item in archivedWords where pendingArchiveIds.contains(item.id) {
                try await client.archive(item, categoryId: archiveCategory.id)
                pendingArchiveIds.remove(item.id)
                saveProgress()
            }
            return nil
        } catch {
            return "部分归档单词暂未同步到欧路，将在下次同步时重试：\(error.localizedDescription)"
        }
    }

    private func saveProgress() {
        if let data = try? JSONEncoder().encode(archivedWords) {
            UserDefaults.standard.set(data, forKey: Self.archivedWordsKey)
        }
        if let data = try? JSONEncoder().encode(successCounts) {
            UserDefaults.standard.set(data, forKey: Self.successCountsKey)
        }
        UserDefaults.standard.set(Array(pendingArchiveIds), forKey: Self.pendingArchiveIdsKey)
    }
}
