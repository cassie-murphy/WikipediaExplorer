import Testing
import CoreLocation
@testable import WikipediaExplorer

@MainActor
struct NearbyViewModelTests {
    
    private var mockAPI: MockWikipediaAPIClient!
    private var mockLocation: MockLocationProvider!
    private var viewModel: NearbyViewModel!
    
    init() async {
        mockAPI = MockWikipediaAPIClient()
        mockLocation = MockLocationProvider()
        viewModel = NearbyViewModel(api: mockAPI!, location: mockLocation!)
    }
    
    // MARK: - Location-Based Fetch Tests
    
    @Test func testFetchNearbySuccess() async throws {
        // Arrange
        mockLocation.setMockLocation(latitude: 37.7749, longitude: -122.4194)
        mockAPI.nearbyResult = TestData.sanFranciscoArticles
        
        // Act
        viewModel.fetchNearby()
        
        // Wait for operation to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .loaded(let articles) = viewModel.state {
            #expect(articles.count == 3)
            #expect(articles[0].title == "Golden Gate Bridge")
        } else {
            Issue.record("Expected loaded state")
        }
        
        #expect(mockLocation.requestLocationCallCount == 1)
        #expect(mockAPI.nearbyCallCount == 1)
        #expect(mockAPI.lastNearbyLat == 37.7749)
        #expect(mockAPI.lastNearbyLon == -122.4194)
    }
    
    @Test func testFetchNearbyLocationDenied() async throws {
        // Arrange
        mockLocation.mockError = WikipediaError.locationDenied as Error
        
        // Act
        viewModel.fetchNearby()
        
        // Wait for operation to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .failed(let message) = viewModel.state {
            #expect(message.contains("Location access denied"))
        } else {
            Issue.record("Expected failed state")
        }
        
        #expect(mockAPI.nearbyCallCount == 0) // Should not call API without location
    }
    
    @Test func testFetchNearbyLocationUnavailable() async throws {
        // Arrange
        mockLocation.mockError = WikipediaError.locationUnavailable as Error
        
        // Act
        viewModel.fetchNearby()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .failed(let message) = viewModel.state {
            #expect(message.contains("Unable to determine location") || message.contains("location"))
        } else {
            Issue.record("Expected failed state")
        }
    }
    
    @Test func testFetchNearbyNetworkError() async throws {
        // Arrange
        mockLocation.setMockLocation(latitude: 37.7749, longitude: -122.4194)
        mockAPI.shouldThrowError = WikipediaError.networkUnavailable
        
        // Act
        viewModel.fetchNearby()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .failed(let message) = viewModel.state {
            #expect(message.contains("internet") || message.contains("network"))
        } else {
            Issue.record("Expected failed state")
        }
    }
    
    // MARK: - Coordinate-Based Fetch Tests
    
    @Test func testFetchNearbyWithCoordinates() async throws {
        // Arrange
        let testCoordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060) // NYC
        mockAPI.nearbyResult = TestData.singleArticle
        
        // Act
        viewModel.fetchNearby(at: testCoordinate)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .loaded(let articles) = viewModel.state {
            #expect(articles.count == 1)
            #expect(articles[0].title == "Single Test Article")
        } else {
            Issue.record("Expected loaded state")
        }
        
        #expect(mockLocation.requestLocationCallCount == 0) // Should not request location
        #expect(mockAPI.nearbyCallCount == 1)
        #expect(mockAPI.lastNearbyLat == 40.7128)
        #expect(mockAPI.lastNearbyLon == -74.0060)
        #expect(viewModel.lastFetchedCenter?.latitude == 40.7128)
        #expect(viewModel.lastFetchedCenter?.longitude == -74.0060)
    }
    
    @Test func testFetchNearbyWithCustomParameters() async throws {
        // Arrange
        let testCoordinate = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278) // London
        mockAPI.nearbyResult = TestData.sanFranciscoArticles
        
        // Act
        viewModel.fetchNearby(at: testCoordinate, radiusMeters: 5000, limit: 15)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        #expect(mockAPI.lastNearbyRadius == 5000)
        #expect(mockAPI.lastNearbyLimit == 15)
    }
    
    // MARK: - State Management Tests
    
    @Test func testInitialState() async throws {
        // Assert
        if case .idle = viewModel.state {
            // Success
        } else {
            Issue.record("Expected idle state initially")
        }
    }
    
    @Test func testLoadingState() async throws {
        // Arrange
        mockLocation.delay = 0.1
        mockLocation.setMockLocation(latitude: 37.7749, longitude: -122.4194)
        mockAPI.nearbyResult = TestData.singleArticle
        
        // Act
        viewModel.fetchNearby()
        
        // Wait briefly - should be in loading state
        try await Task.sleep(nanoseconds: 50_000_000)
        
        // Assert
        if case .loading = viewModel.state {
            // Success
        } else {
            Issue.record("Expected loading state")
        }
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 150_000_000)
        
        // Assert final state
        if case .loaded = viewModel.state {
            // Success
        } else {
            Issue.record("Expected loaded state after completion")
        }
    }
    
    @Test func testRetryFunctionality() async throws {
        // Arrange
        mockAPI.shouldThrowError = WikipediaError.networkUnavailable
        viewModel.fetchNearby()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify error state
        if case .failed = viewModel.state {
            // Expected
        } else {
            Issue.record("Expected failed state")
        }
        
        // Fix the error
        mockAPI.shouldThrowError = nil
        mockLocation.setMockLocation(latitude: 37.7749, longitude: -122.4194)
        mockAPI.nearbyResult = TestData.singleArticle
        
        // Act
        viewModel.retry()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .loaded(let articles) = viewModel.state {
            #expect(articles.count == 1)
        } else {
            Issue.record("Expected loaded state after retry")
        }
        
        #expect(mockLocation.requestLocationCallCount == 2) // Original + retry
    }
    
    // MARK: - Map Logic Tests
    
    @Test func testShouldShowSearchButtonWithoutCenter() async throws {
        // Arrange
        viewModel.mapCenter = nil
        
        // Assert
        #expect(viewModel.shouldShowSearchButton() == false)
    }
    
    @Test func testShouldShowSearchButtonWithoutPreviousFetch() async throws {
        // Arrange
        viewModel.mapCenter = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        viewModel.lastFetchedCenter = nil
        
        // Assert
        #expect(viewModel.shouldShowSearchButton() == true)
    }
    
    @Test func testShouldShowSearchButtonWithinThreshold() async throws {
        // Arrange
        let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let nearbyCenter = CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195) // Very close
        
        viewModel.mapCenter = center
        viewModel.lastFetchedCenter = nearbyCenter
        
        // Assert - Should be false because centers are very close (< 1km apart)
        #expect(viewModel.shouldShowSearchButton() == false)
    }
    
    @Test func testShouldShowSearchButtonBeyondThreshold() async throws {
        // Arrange
        let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // SF
        let distantCenter = CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783) // Golden Gate Bridge
        
        viewModel.mapCenter = center
        viewModel.lastFetchedCenter = distantCenter
        
        // Assert - Should be true because centers are far apart (> 1km)
        #expect(viewModel.shouldShowSearchButton() == true)
    }
    
    @Test func testGetArticlesWithGeo() async throws {
        // Arrange
        let mixedArticles = TestData.mixedArticles // Contains articles with and without geo
        
        // Act
        let geoArticles = viewModel.getArticlesWithGeo(from: mixedArticles)
        
        // Assert
        #expect(geoArticles.count == 3) // Only SF articles have geo coordinates
        #expect(geoArticles.allSatisfy { $0.article.geo != nil })
        #expect(geoArticles.allSatisfy { $0.article.fullURL != nil })
    }
}
