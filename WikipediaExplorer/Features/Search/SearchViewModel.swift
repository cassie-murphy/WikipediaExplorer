import SwiftUI

@Observable
final class SearchViewModel {
    enum Mode: Equatable { case idle, searching, results, error(String) }

    private let wikipediaAPIClient: WikipediaAPIClient
    private var searchTask: Task<Void, Never>?
    private let history: SearchHistoryStore
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
        searchTask?.cancel()
        let trimmedSearchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSearchQuery.isEmpty {
            Task { await MainActor.run { self.mode = .idle; self.results = [] } }
            return
        }

        mode = .searching
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000) // debounce
            guard !Task.isCancelled else { return }
            do {
                let items = try await wikipediaAPIClient.search(text: trimmedSearchQuery, limit: 20)     // actor hop to api
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.results = items
                    self.mode = .results
                    self.history.record(trimmedSearchQuery)
                    self.recentSearches = self.history.load()
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { self.mode = .error("Search failed. Please try again.") }
            }
        }
    }

    // MARK: - Recent search intents

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
