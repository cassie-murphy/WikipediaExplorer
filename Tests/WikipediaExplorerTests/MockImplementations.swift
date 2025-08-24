import SwiftUI
import CoreLocation
@testable import WikipediaExplorer

// MARK: - Mock API Client
@MainActor
final class MockWikipediaAPIClient: WikipediaAPIClient {
    // Configuration
    var searchResult: [Article] = []
    var nearbyResult: [Article] = []
    var shouldThrowError: WikipediaError?
    var searchDelay: TimeInterval = 0
    var nearbyDelay: TimeInterval = 0

    // Call tracking
    private(set) var searchCallCount = 0
    private(set) var nearbyCallCount = 0
    private(set) var lastSearchText: String?
    private(set) var lastSearchLimit: Int?
    private(set) var lastNearbyLat: Double?
    private(set) var lastNearbyLon: Double?
    private(set) var lastNearbyRadius: Int?
    private(set) var lastNearbyLimit: Int?

    func search(text: String, limit: Int) async throws -> [Article] {
        searchCallCount += 1
        lastSearchText = text
        lastSearchLimit = limit

        if searchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(searchDelay * 1_000_000_000))
        }

        if let error = shouldThrowError {
            throw error
        }

        return searchResult
    }

    func nearby(lat: Double, lon: Double, radiusMeters: Int, limit: Int) async throws -> [Article] {
        nearbyCallCount += 1
        lastNearbyLat = lat
        lastNearbyLon = lon
        lastNearbyRadius = radiusMeters
        lastNearbyLimit = limit

        if nearbyDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(nearbyDelay * 1_000_000_000))
        }

        if let error = shouldThrowError {
            throw error
        }

        return nearbyResult
    }

    // Test helpers
    func reset() {
        searchCallCount = 0
        nearbyCallCount = 0
        lastSearchText = nil
        lastSearchLimit = nil
        lastNearbyLat = nil
        lastNearbyLon = nil
        lastNearbyRadius = nil
        lastNearbyLimit = nil
        shouldThrowError = nil
        searchDelay = 0
        nearbyDelay = 0
        searchResult = []
        nearbyResult = []
    }
}

// MARK: - Mock Search History Store
final class MockSearchHistoryStore: SearchHistoryStore, @unchecked Sendable {
    // Storage - protected by actor isolation
    private var _items: [String] = []

    // Call tracking - protected by actor isolation
    private var _loadCallCount = 0
    private var _recordCalls: [String] = []
    private var _removeCalls: [IndexSet] = []
    private var _clearCallCount = 0

    // Thread-safe accessors
    var items: [String] {
        return _items
    }

    var loadCallCount: Int {
        return _loadCallCount
    }

    var recordCalls: [String] {
        return _recordCalls
    }

    var removeCalls: [IndexSet] {
        return _removeCalls
    }

    var clearCallCount: Int {
        return _clearCallCount
    }

    func load() -> [String] {
        _loadCallCount += 1
        return _items
    }

    func record(_ term: String) {
        _recordCalls.append(term)
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Remove existing instance (case insensitive)
        _items.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }

        // Add to front
        _items.insert(trimmed, at: 0)

        // Limit to 10 items
        if _items.count > 10 {
            _items = Array(_items.prefix(10))
        }
    }

    func remove(at offsets: IndexSet) {
        _removeCalls.append(offsets)
        _items.remove(atOffsets: offsets)
    }

    func clear() {
        _clearCallCount += 1
        _items.removeAll()
    }

    // Test helpers
    func reset() {
        _items = []
        _loadCallCount = 0
        _recordCalls = []
        _removeCalls = []
        _clearCallCount = 0
    }

    func preloadItems(_ searchTerms: [String]) {
        _items = searchTerms
    }
}

// MARK: - Mock Location Provider
@MainActor
final class MockLocationProvider: LocationProviderProtocol {
    // Configuration
    var mockLocation: CLLocation?
    var mockError: Error?
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    var delay: TimeInterval = 0

    // Call tracking
    private(set) var requestLocationCallCount = 0

    func requestCurrentLocation() async throws -> CLLocation {
        requestLocationCallCount += 1

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if let error = mockError {
            throw error
        }

        guard let location = mockLocation else {
            throw WikipediaError.locationUnavailable as Error
        }

        return location
    }

    // Test helpers
    func reset() {
        mockLocation = nil
        mockError = nil
        authorizationStatus = .authorizedWhenInUse
        delay = 0
        requestLocationCallCount = 0
    }

    func setMockLocation(latitude: Double, longitude: Double) {
        mockLocation = CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Test Fixtures
extension Article {
    static func fixture(
        id: Int = 1,
        title: String = "Test Article",
        fullURL: URL? = URL(string: "https://en.wikipedia.org/wiki/Test_Article"),
        thumbnailURL: URL? = URL(string: "https://example.com/thumb.jpg"),
        geo: Geo? = Geo(lat: 37.7749, lon: -122.4194)
    ) -> Article {
        Article(
            id: id,
            title: title,
            fullURL: fullURL,
            thumbnailURL: thumbnailURL,
            geo: geo
        )
    }
}

extension Geo {
    static func fixture(lat: Double = 37.7749, lon: Double = -122.4194) -> Geo {
        Geo(lat: lat, lon: lon)
    }
}

extension CLLocation {
    static func fixture(
        latitude: Double = 37.7749,
        longitude: Double = -122.4194
    ) -> CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Sample Data Collections
struct TestData {
    static let sanFranciscoArticles = [
        Article.fixture(
            id: 1,
            title: "Golden Gate Bridge",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Golden_Gate_Bridge"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/GG-ftpoint-bridge-2.jpg/200px-GG-ftpoint-bridge-2.jpg"),
            geo: Geo(lat: 37.8199, lon: -122.4783)
        ),
        Article.fixture(
            id: 2,
            title: "Alcatraz Island",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Alcatraz_Island"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Alcatraz_Island_photo_D_Ramey_Logan.jpg/200px-Alcatraz_Island_photo_D_Ramey_Logan.jpg"),
            geo: Geo(lat: 37.8267, lon: -122.4230)
        ),
        Article.fixture(
            id: 3,
            title: "San Francisco",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/San_Francisco"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/San_Francisco_from_the_Marin_Headlands_in_March_2019.jpg/200px-San_Francisco_from_the_Marin_Headlands_in_March_2019.jpg"),
            geo: Geo(lat: 37.7749, lon: -122.4194)
        )
    ]

    static let searchHistory = [
        "San Francisco",
        "Golden Gate Bridge",
        "California",
        "Machine Learning",
        "Swift Programming"
    ]

    static let emptyResults: [Article] = []

    static let singleArticle = [
        Article.fixture(
            id: 100,
            title: "Single Test Article",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Single_Test_Article"),
            thumbnailURL: nil,
            geo: nil
        )
    ]

    static let articlesWithoutGeo = [
        Article.fixture(
            id: 200,
            title: "Article Without Location",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Article_Without_Location"),
            thumbnailURL: nil,
            geo: nil
        ),
        Article.fixture(
            id: 201,
            title: "Another Article Without Location",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Another_Article_Without_Location"),
            thumbnailURL: URL(string: "https://example.com/thumb2.jpg"),
            geo: nil
        )
    ]

    static let mixedArticles = sanFranciscoArticles + articlesWithoutGeo
}

// MARK: - Error Test Cases
extension WikipediaError {
    static var testCases: [WikipediaError] {
        [
            .networkUnavailable,
            .invalidResponse,
            .noResults,
            .locationDenied,
            .locationRestricted,
            .locationUnavailable,
            .requestTimeout,
            .serverError(500),
            .serverError(404),
            .decodingError,
            .unknown("Test error message")
        ]
    }

    static var retryableErrors: [WikipediaError] {
        [
            .networkUnavailable,
            .requestTimeout,
            .serverError(500),
            .locationUnavailable,
            .invalidResponse
        ]
    }

    static var nonRetryableErrors: [WikipediaError] {
        [
            .locationDenied,
            .locationRestricted,
            .noResults,
            .decodingError
        ]
    }
}
