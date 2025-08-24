import Testing
import Foundation
@testable import WikipediaExplorer

@MainActor
struct SearchViewModelTests {
    
    private var mockAPI: MockWikipediaAPIClient!
    private var mockHistory: MockSearchHistoryStore!
    private var viewModel: SearchViewModel!
    
    init() async {
        mockAPI = MockWikipediaAPIClient()
        mockHistory = MockSearchHistoryStore()
        viewModel = SearchViewModel(api: mockAPI!, history: mockHistory!)
    }
    
    // MARK: - Search Functionality Tests
    
    @Test func testSearchWithValidQuery() async throws {
        // Arrange
        mockAPI.searchResult = TestData.sanFranciscoArticles
        
        // Act
        viewModel.query = "San Francisco"
        viewModel.onQueryChanged()
        
        // Wait for debounce + processing
        try await Task.sleep(nanoseconds: 400_000_000)
        
        #expect(viewModel.mode == .results)
        #expect(viewModel.results.count == 3)
        #expect(viewModel.results[0].title == "Golden Gate Bridge")
        #expect(mockAPI.searchCallCount == 1)
        #expect(mockAPI.lastSearchText == "San Francisco")
        #expect(mockHistory.recordCalls.contains("San Francisco"))
    }
    
    @Test func testSearchWithEmptyQuery() async throws {
        // Arrange
        viewModel.query = "test"
        viewModel.results = TestData.singleArticle
        viewModel.mode = .results
        
        // Act
        viewModel.query = ""
        viewModel.onQueryChanged()
        
        // Wait a moment
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        #expect(viewModel.mode == .idle)
        #expect(viewModel.results.isEmpty)
        #expect(mockAPI.searchCallCount == 0) // Should not call API for empty query
    }
    
    @Test func testSearchWithWhitespaceQuery() async throws {
        // Act
        viewModel.query = "   \n\t   "
        viewModel.onQueryChanged()

        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.mode == .idle)
        #expect(viewModel.results.isEmpty)
        #expect(mockAPI.searchCallCount == 0)
    }
    
    @Test func testSearchDebouncing() async throws {
        // Arrange
        mockAPI.searchResult = TestData.singleArticle
        
        // Act - Rapid fire queries
        viewModel.query = "S"
        viewModel.onQueryChanged()
        
        try await Task.sleep(nanoseconds: 100_000_000) // Less than debounce time
        
        viewModel.query = "Sa"
        viewModel.onQueryChanged()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        viewModel.query = "San"
        viewModel.onQueryChanged()
        
        // Wait for final debounce to complete
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Assert - Only final query should execute
        #expect(mockAPI.searchCallCount == 1)
        #expect(mockAPI.lastSearchText == "San")
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testSearchWithNetworkError() async throws {
        // Arrange
        mockAPI.shouldThrowError = WikipediaError.networkUnavailable
        
        // Act
        viewModel.query = "test"
        viewModel.onQueryChanged()
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Assert
        if case .error(let error) = viewModel.mode {
            #expect(error == WikipediaError.networkUnavailable)
            #expect(error.shouldShowRetry == true)
            #expect(error.errorDescription?.contains("internet") == true)
        } else {
            Issue.record("Expected error mode")
        }
        #expect(viewModel.results.isEmpty)
    }
    
    @Test func testSearchWithNoResults() async throws {
        // Arrange
        mockAPI.shouldThrowError = WikipediaError.noResults
        
        // Act
        viewModel.query = "nonexistent"
        viewModel.onQueryChanged()
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Assert
        if case .error(let error) = viewModel.mode {
            #expect(error == WikipediaError.noResults)
            #expect(error.shouldShowRetry == false)
        } else {
            Issue.record("Expected error mode with no results")
        }
    }
    
    @Test func testSearchRetry() async throws {
        // Arrange
        mockAPI.shouldThrowError = WikipediaError.networkUnavailable
        viewModel.query = "test"
        viewModel.onQueryChanged()
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Verify error state
        #expect(viewModel.mode == .error(WikipediaError.networkUnavailable))
        
        // Fix the error and retry
        mockAPI.shouldThrowError = nil
        mockAPI.searchResult = TestData.singleArticle
        
        // Act
        viewModel.retrySearch()
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Assert
        #expect(viewModel.mode == .results)
        #expect(viewModel.results.count == 1)
        #expect(mockAPI.searchCallCount == 2)
    }
    
    // MARK: - Search History Tests
    
    @Test func testSearchHistoryLoading() async throws {
        // Arrange
        mockHistory.reset()
        let testHistory = ["Previous Search", "Another Search"]
        mockHistory.preloadItems(testHistory)
        
        // Act
        viewModel.recentSearches = mockHistory.load()
        
        // Assert
        #expect(viewModel.recentSearches.count == 2)
        #expect(viewModel.recentSearches[0] == "Previous Search")
        #expect(mockHistory.loadCallCount == 1)
    }
    
    @Test func testSelectRecentSearch() async throws {
        // Arrange
        mockHistory.preloadItems(["Previous Search"])
        mockAPI.searchResult = TestData.singleArticle
        viewModel.recentSearches = mockHistory.load()
        
        // Act
        viewModel.selectRecent("Previous Search")
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Assert
        #expect(viewModel.query == "Previous Search")
        #expect(viewModel.mode == .results)
        #expect(mockAPI.searchCallCount == 1)
        #expect(mockAPI.lastSearchText == "Previous Search")
    }
    
    @Test func testRemoveRecentSearch() async throws {
        // Arrange
        mockHistory.preloadItems(["First", "Second", "Third"])
        viewModel.recentSearches = mockHistory.load()
        
        // Act
        viewModel.removeRecent(at: IndexSet([1])) // Remove "Second"
        
        // Assert
        #expect(mockHistory.removeCalls.count == 1)
        #expect(mockHistory.removeCalls[0] == IndexSet([1]))
        #expect(viewModel.recentSearches.count == 2)
        #expect(!viewModel.recentSearches.contains("Second"))
    }
    
    @Test func testClearRecentSearches() async throws {
        // Arrange
        mockHistory.preloadItems(["First", "Second"])
        viewModel.recentSearches = mockHistory.load()
        
        // Act
        viewModel.clearRecents()
        
        // Assert
        #expect(mockHistory.clearCallCount == 1)
        #expect(viewModel.recentSearches.isEmpty)
    }
    
    @Test func testRecordSearchHistory() async throws {
        // Arrange
        mockAPI.searchResult = TestData.singleArticle
        
        // Act
        viewModel.query = "New Search Term"
        viewModel.onQueryChanged()
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Assert
        #expect(mockHistory.recordCalls.contains("New Search Term"))
    }
    
    // MARK: - State Management Tests
    
    @Test func testInitialState() async throws {
        // Assert
        #expect(viewModel.mode == .idle)
        #expect(viewModel.query.isEmpty)
        #expect(viewModel.results.isEmpty)
    }
    
    @Test func testSearchingState() async throws {
        // Arrange
        mockAPI.searchDelay = 0.1 // Add delay to catch searching state
        mockAPI.searchResult = TestData.singleArticle
        
        // Act
        viewModel.query = "test"
        viewModel.onQueryChanged()
        
        // Wait for debounce but before API completion
        try await Task.sleep(nanoseconds: 380_000_000)
        
        // Assert - Should be in searching state
        #expect(viewModel.mode == .searching)
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Assert - Should now be in results state
        #expect(viewModel.mode == .results)
    }
}
