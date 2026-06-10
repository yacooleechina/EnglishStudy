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
    @Published var selectedCategoryId: String?
    @Published var currentIndex = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var hasAttemptedInitialSync = false

    private static let usernameKey = "eudic.username"

    init() {
        let savedUsername = UserDefaults.standard.string(forKey: Self.usernameKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        username = savedUsername ?? ""

        let savedAuthorization = KeychainStore.loadAuthorization()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        authorization = savedAuthorization
    }

    var client: EudicClient {
        EudicClient(authorization: authorization)
    }

    var currentWord: StudyWord? {
        guard words.indices.contains(currentIndex) else { return nil }
        return words[currentIndex]
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
            if refreshCategories {
                categories = try await client.categories()
            }
            words = try await client.allWords(categoryId: selectedCategoryId)
            currentIndex = 0
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
}
