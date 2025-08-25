import SwiftUI

#if DEBUG

// MARK: - Preview ViewModels for SearchView
extension SearchViewModel {
    static var previewIdle: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.searchHistory)
        viewModel.mode = SearchViewModel.Mode.idle
        viewModel.query = ""
        viewModel.results = []
        viewModel.recentSearches = []
        return viewModel
    }
    
    static var previewWithHistory: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.searchHistory)
        viewModel.mode = SearchViewModel.Mode.idle
        viewModel.query = ""
        viewModel.results = []
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }
    
    static var previewSearching: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.searchHistory)
        viewModel.mode = SearchViewModel.Mode.searching
        viewModel.query = "Golden Gate"
        viewModel.results = []
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }
    
    static var previewWithResults: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.searchHistory)
        viewModel.mode = SearchViewModel.Mode.results
        viewModel.query = "San Francisco"
        viewModel.results = PreviewData.articles
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }
    
    static var previewNoResults: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.searchHistory)
        viewModel.mode = SearchViewModel.Mode.results
        viewModel.query = "xyzabc123nonexistent"
        viewModel.results = []
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }
    
    static var previewNetworkError: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.searchHistory)
        viewModel.mode = SearchViewModel.Mode.error(.networkUnavailable)
        viewModel.query = "test query"
        viewModel.results = []
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }
    
    static var previewTimeoutError: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.searchHistory)
        viewModel.mode = SearchViewModel.Mode.error(.requestTimeout)
        viewModel.query = "slow query"
        viewModel.results = []
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }
    
    static var previewNoResultsError: SearchViewModel {
        let viewModel = SearchViewModel(api: PreviewMocks.apiClient, history: PreviewMocks.searchHistory)
        viewModel.mode = SearchViewModel.Mode.error(.noResults)
        viewModel.query = "nothing found"
        viewModel.results = []
        viewModel.recentSearches = PreviewData.searchHistory
        return viewModel
    }
}

#endif
