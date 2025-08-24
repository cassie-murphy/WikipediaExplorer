import SwiftUI

#if DEBUG

// MARK: - Preview Extensions
extension SearchViewModel {
    static var previewIdle: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.historyStore)
        viewModel.mode = SearchViewModel.Mode.idle
        viewModel.query = ""
        viewModel.results = []
        viewModel.recentSearches = []
        return viewModel
    }

    static var previewWithResults: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.historyStore)
        viewModel.mode = SearchViewModel.Mode.results
        viewModel.query = "San Francisco"
        viewModel.results = PreviewData.searchResults
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }

    static var previewNoResults: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.historyStore)
        viewModel.mode = SearchViewModel.Mode.results
        viewModel.query = "nonexistent query"
        viewModel.results = []
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }

    static var previewNetworkError: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.historyStore)
        viewModel.mode = SearchViewModel.Mode.error(.networkUnavailable)
        viewModel.query = "test query"
        viewModel.results = []
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }

    static var previewTimeoutError: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.historyStore)
        viewModel.mode = SearchViewModel.Mode.error(.requestTimeout)
        viewModel.query = "slow query"
        viewModel.results = []
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }

    static var previewNoResultsError: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.historyStore)
        viewModel.mode = SearchViewModel.Mode.error(.noResults)
        viewModel.query = "nothing found"
        viewModel.results = []
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }
}

// MARK: - Preview Data
extension PreviewData {
    static let searchHistory = [
        "San Francisco",
        "Golden Gate Bridge",
        "Machine Learning",
        "Swift Programming",
        "iOS Development"
    ]

    static let searchResults = [
        Article(
            id: 100,
            title: "San Francisco",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/San_Francisco"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/San_Francisco_from_the_Marin_Headlands_in_March_2019.jpg/200px-San_Francisco_from_the_Marin_Headlands_in_March_2019.jpg"),
            geo: Geo(lat: 37.7749, lon: -122.4194)
        ),
        Article(
            id: 101,
            title: "San Francisco Bay Area",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/San_Francisco_Bay_Area"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/SanFranciscoBayAreaFromSpace.jpg/200px-SanFranciscoBayAreaFromSpace.jpg"),
            geo: Geo(lat: 37.8044, lon: -122.2712)
        ),
        Article(
            id: 102,
            title: "San Francisco Giants",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/San_Francisco_Giants"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/5/58/San_Francisco_Giants_Logo.svg/200px-San_Francisco_Giants_Logo.svg.png"),
            geo: nil
        ),
        Article(
            id: 103,
            title: "University of San Francisco",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/University_of_San_Francisco"),
            thumbnailURL: nil,
            geo: Geo(lat: 37.7766, lon: -122.4502)
        ),
        Article(
            id: 104,
            title: "San Francisco International Airport",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/San_Francisco_International_Airport"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/San_Francisco_International_Airport_Logo.svg/200px-San_Francisco_International_Airport_Logo.svg.png"),
            geo: Geo(lat: 37.6213, lon: -122.3790)
        )
    ]
}

// MARK: - Preview Mocks
extension PreviewMocks {
    static let historyStore: SearchHistoryStore = PreviewSearchHistoryStore()
}

fileprivate struct PreviewSearchHistoryStore: SearchHistoryStore {
    func load() -> [String] {
        return PreviewData.searchHistory
    }

    func record(_ term: String) { }
    func remove(at offsets: IndexSet) { }
    func clear() { }
}

#endif
