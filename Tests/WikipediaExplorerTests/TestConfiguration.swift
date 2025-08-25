import Testing
import CoreLocation
@testable import WikipediaExplorer

// MARK: - Test Configuration

struct TestConfiguration {
    static let defaultTimeout: TimeInterval = 1.0
    static let shortTimeout: TimeInterval = 0.1
    static let debounceTestTimeout: TimeInterval = 0.5
}

// MARK: - Test Utilities

struct TestUtils {
    /// Wait for async operations with a reasonable timeout
    static func waitForAsync(timeout: TimeInterval = TestConfiguration.defaultTimeout) async throws {
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }

    /// Wait for debounce operations specifically
    static func waitForDebounce() async throws {
        try await Task.sleep(nanoseconds: 400_000_000) // 400ms - slightly more than 350ms debounce
    }

    /// Wait for short async operations
    static func waitShort() async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }
}

// MARK: - Test Base Classes
@MainActor
class ViewModelTestCase {
    var mockAPI: MockWikipediaAPIClient!

    func setUp() async {
        mockAPI = MockWikipediaAPIClient()
    }

    func tearDown() async {
        mockAPI?.reset()
    }
}

// MARK: - Loadable Test Helpers
extension Loadable where Value == [Article] {
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    var loadedValue: [Article]? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var failedError: WikipediaError? {
        if case .failed(let error) = self { return error }
        return nil
    }
}

// MARK: - Article Test Helpers

extension Array where Element == Article {
    var titles: [String] {
        return map { $0.title }
    }

    var withGeo: [Article] {
        return filter { $0.geo != nil }
    }

    var withoutGeo: [Article] {
        return filter { $0.geo == nil }
    }

    var withThumbnails: [Article] {
        return filter { $0.thumbnailURL != nil }
    }
}

// MARK: - Location Test Helpers

extension CLLocationCoordinate2D {
    static let sanFrancisco = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    static let newYork = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    static let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
    static let tokyo = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }
}

// MARK: - Test Data Builders

struct ArticleBuilder {
    private var id: Int = 1
    private var title: String = "Test Article"
    private var fullURL: URL? = URL(string: "https://en.wikipedia.org/wiki/Test_Article")
    private var thumbnailURL: URL?
    private var geo: Geo?

    func withId(_ id: Int) -> ArticleBuilder {
        var builder = self
        builder.id = id
        return builder
    }

    func withTitle(_ title: String) -> ArticleBuilder {
        var builder = self
        builder.title = title
        builder.fullURL = URL(string: "https://en.wikipedia.org/wiki/\(title.replacingOccurrences(of: " ", with: "_"))")
        return builder
    }

    func withThumbnail(_ url: String? = "https://example.com/thumb.jpg") -> ArticleBuilder {
        var builder = self
        builder.thumbnailURL = url != nil ? URL(string: url!) : nil
        return builder
    }

    func withGeo(lat: Double, lon: Double) -> ArticleBuilder {
        var builder = self
        builder.geo = Geo(lat: lat, lon: lon)
        return builder
    }

    func withoutURL() -> ArticleBuilder {
        var builder = self
        builder.fullURL = nil
        return builder
    }

    func build() -> Article {
        return Article(
            id: id,
            title: title,
            fullURL: fullURL,
            thumbnailURL: thumbnailURL,
            geo: geo
        )
    }

    static func create() -> ArticleBuilder {
        return ArticleBuilder()
    }
}

// MARK: - Performance Test Helpers

struct PerformanceTestHelper {
    static func measureAsync<T>(_ operation: () async throws -> T) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return (result, duration)
    }

    static func expectPerformance<T>(
        _ operation: () async throws -> T,
        toBeFasterThan threshold: TimeInterval,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async rethrows -> T {
        let (result, duration) = try await measureAsync(operation)

        if duration > threshold {
            Issue.record("Operation took \(duration)s, expected < \(threshold)s",
                        sourceLocation: sourceLocation)
        }

        return result
    }
}

// MARK: - Mock Network Conditions

extension MockWikipediaAPIClient {
    func simulateSlowNetwork(delay: TimeInterval = 2.0) {
        self.searchDelay = delay
        self.nearbyDelay = delay
    }

    func simulateFlawkyNetwork(failureRate: Double = 0.3) {
        if Double.random(in: 0...1) < failureRate {
            self.shouldThrowError = WikipediaError.networkUnavailable
        } else {
            self.shouldThrowError = nil
        }
    }

    func simulateServerError(statusCode: Int = 500) {
        self.shouldThrowError = WikipediaError.serverError(statusCode)
    }
}

extension MockLocationProvider {
    func simulateSlowGPS(delay: TimeInterval = 1.0) {
        self.delay = delay
    }

    func simulateDeniedPermissions() {
        self.mockError = WikipediaError.locationDenied as Error
    }

    func simulateInaccurateLocation(accuracy: CLLocationDistance = 1000) {
        if let current = mockLocation {
            // Add some random offset to simulate inaccuracy
            let latOffset = Double.random(in: -0.01...0.01)
            let lonOffset = Double.random(in: -0.01...0.01)
            mockLocation = CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: current.coordinate.latitude + latOffset,
                    longitude: current.coordinate.longitude + lonOffset
                ),
                altitude: current.altitude,
                horizontalAccuracy: accuracy,
                verticalAccuracy: current.verticalAccuracy,
                timestamp: current.timestamp
            )
        }
    }
}
