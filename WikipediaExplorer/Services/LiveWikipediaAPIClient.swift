//  LiveWikipediaAPIClient.swift
import Foundation

/// Protocol lives in WikipediaAPIClient.swift
/// actor gives thread-safety for any mutable state
actor LiveWikipediaAPIClient: WikipediaAPIClient {
    private let session: URLSession
    private let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    // MARK: - WikipediaAPIClient

    func search(text: String, limit: Int = 20) async throws -> [Article] {
        let request = try await WikipediaEndpoint
            .search(text: text, limit: limit)
            .urlRequest(userAgent: userAgent)

        return try await fetchArticles(request)
    }

    func nearby(
        lat: Double,
        lon: Double,
        radiusMeters: Int = 10_000,
        limit: Int = 20
    ) async throws -> [Article] {
        let request = try await WikipediaEndpoint
            .nearby(lat: lat, lon: lon, radiusMeters: radiusMeters, limit: limit)
            .urlRequest(userAgent: userAgent)

        return try await fetchArticles(request)
    }

    // MARK: - Private

    private func fetchArticles(_ request: URLRequest) async throws -> [Article] {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(WikiQueryResponse.self, from: data)
        return decoded.articles
    }
}

// MARK: - Decoding

/// Narrow, file-private decoding types to keep public model clean.
private nonisolated struct WikiQueryResponse: Decodable {
    let query: Query?

    var articles: [Article] {
        guard let pages = query?.pages else { return [] }
        return pages.map { p in
            Article(
                id: p.pageid,
                title: p.title,
                fullURL: p.fullurl,
                thumbnailURL: p.thumbnail?.source,
                geo: (p.coordinates?.first).map { Geo(lat: $0.lat, lon: $0.lon) }
            )
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    nonisolated struct Query: Decodable { let pages: [Page] }

    nonisolated struct Page: Decodable {
        let pageid: Int
        let title: String
        let fullurl: URL?
        let coordinates: [Coord]?
        let thumbnail: Thumbnail?
    }

    nonisolated struct Coord: Decodable {
        let lat: Double
        let lon: Double
    }

    nonisolated struct Thumbnail: Decodable {
        let source: URL
    }
}
