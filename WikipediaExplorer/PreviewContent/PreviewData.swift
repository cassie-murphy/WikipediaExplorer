import Foundation
import CoreLocation

#if DEBUG

struct PreviewData {
    // Shared mock articles that can be used for any preview
    static let articles = [
        Article(
            id: 1,
            title: "Golden Gate Bridge",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Golden_Gate_Bridge"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/GG-ftpoint-bridge-2.jpg/200px-GG-ftpoint-bridge-2.jpg"),
            geo: Geo(lat: 37.8199, lon: -122.4783)
        ),
        Article(
            id: 2,
            title: "Alcatraz Island",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Alcatraz_Island"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Alcatraz_Island_photo_D_Ramey_Logan.jpg/200px-Alcatraz_Island_photo_D_Ramey_Logan.jpg"),
            geo: Geo(lat: 37.8267, lon: -122.4230)
        ),
        Article(
            id: 3,
            title: "Coit Tower",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Coit_Tower"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Coit_tower.jpg/200px-Coit_tower.jpg"),
            geo: Geo(lat: 37.8024, lon: -122.4058)
        ),
        Article(
            id: 4,
            title: "Machine Learning",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Machine_learning"),
            thumbnailURL: nil,
            geo: nil
        ),
        Article(
            id: 5,
            title: "Swift Programming Language",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Swift_(programming_language)"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Swift_logo.svg/200px-Swift_logo.svg.png"),
            geo: nil
        )
    ]
    
    // Convenience accessors for specific use cases
    static var articlesWithGeo: [Article] {
        articles.filter { $0.geo != nil }
    }
    
    static var articlesWithoutGeo: [Article] {
        articles.filter { $0.geo == nil }
    }
    
    static var singleArticle: Article {
        articles[0]
    }
    
    static var searchHistory: [String] {
        ["San Francisco", "Golden Gate Bridge", "Machine Learning", "Swift Programming"]
    }
}

// MARK: - Mock API Implementations

struct PreviewMocks {
    static let apiClient: WikipediaAPIClient = PreviewWikipediaAPIClient()
    static let locationProvider: LocationProviderProtocol = PreviewLocationProvider()
    static let searchHistory: SearchHistoryStore = PreviewSearchHistoryStore()
}

private struct PreviewWikipediaAPIClient: WikipediaAPIClient {
    func search(text: String, limit: Int) async throws -> [Article] {
        // Return all articles for search previews
        return PreviewData.articles
    }
    
    func nearby(lat: Double, lon: Double, radiusMeters: Int, limit: Int) async throws -> [Article] {
        // Return only articles with geo coordinates for nearby previews
        return PreviewData.articlesWithGeo
    }
}

@MainActor
private final class PreviewLocationProvider: LocationProviderProtocol {
    func requestCurrentLocation() async throws -> CLLocation {
        // Return a default San Francisco location for previews
        return CLLocation(latitude: 37.7749, longitude: -122.4194)
    }
}

private struct PreviewSearchHistoryStore: SearchHistoryStore {
    func load() -> [String] {
        return PreviewData.searchHistory
    }
    
    func record(_ term: String) { }
    func remove(at offsets: IndexSet) { }
    func clear() { }
}

#endif
