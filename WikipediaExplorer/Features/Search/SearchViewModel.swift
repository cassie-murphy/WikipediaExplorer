import SwiftUI

@Observable
final class SearchViewModel {
    enum Mode: Equatable { case idle, searching, results, error(WikipediaError) }

    private let wikipediaAPIClient: WikipediaAPIClient
    private var searchTask: Task<Void, Never>?
    private let history: SearchHistoryStore
    private let debounceInterval: UInt64 = 350_000_000 // 350ms

    var recentSearches: [String] = []
    var query: String = ""
    var mode: Mode = .idle
    var results: [Article] = []

    init(api: WikipediaAPIClient, history: SearchHistoryStore = UserDefaultsSearchHistoryStore()) {
        self.wikipediaAPIClient = api
        self.history = history
        self.recentSearches = history.load()
    }

    func onQueryChanged() {
        // Cancel any existing search
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle empty query
        guard !trimmedQuery.isEmpty else {
            Task { @MainActor in
                self.mode = .idle
                self.results = []
            }
            return
        }

        // Start new search with debouncing
        mode = .searching
        searchTask = Task {
            do {
                // Debounce the search
                try await Task.sleep(nanoseconds: debounceInterval)
                guard !Task.isCancelled else { return }

                // Perform the search
                let articles = try await wikipediaAPIClient.search(text: trimmedQuery, limit: 20)
                guard !Task.isCancelled else { return }

                // Update UI on main actor
                await MainActor.run {
                    self.results = articles
                    self.mode = .results
                    self.history.record(trimmedQuery)
                    self.recentSearches = self.history.load()
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    let wikipediaError = WikipediaError.from(error)
                    self.mode = .error(wikipediaError)
                    self.results = []
                }
            }
        }
    }

    func retrySearch() {
        onQueryChanged()
    }

    // MARK: - Recent Search Management
    func selectRecent(_ term: String) {
        query = term
        onQueryChanged()
    }

    func removeRecent(at offsets: IndexSet) {
        history.remove(at: offsets)
        recentSearches = history.load()
    }

    func clearRecents() {
        history.clear()
        recentSearches = []
    }
}
