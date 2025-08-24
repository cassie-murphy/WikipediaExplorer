import Foundation

actor LiveWikipediaAPIClient: WikipediaAPIClient {
    private let session: URLSession
    private let userAgent: String
    private let timeout: TimeInterval = 10.0

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    func search(text: String, limit: Int = 20) async throws -> [Article] {
        let request = try await WikipediaEndpoint
            .search(text: text, limit: limit)
            .urlRequest(userAgent: userAgent, timeout: timeout)

        let articles = try await fetchArticles(request)

        // Return specific error if no results found
        if articles.isEmpty {
            throw WikipediaError.noResults
        }

        return articles
    }

    func nearby(
        lat: Double,
        lon: Double,
        radiusMeters: Int = 10_000,
        limit: Int = 20
    ) async throws -> [Article] {
        let request = try await WikipediaEndpoint
            .nearby(lat: lat, lon: lon, radiusMeters: radiusMeters, limit: limit)
            .urlRequest(userAgent: userAgent, timeout: timeout)

        let articles = try await fetchArticles(request)

        // Return specific error if no results found
        if articles.isEmpty {
            throw WikipediaError.noResults
        }

        return articles
    }

    // MARK: - Private
    private func fetchArticles(_ request: URLRequest) async throws -> [Article] {
        do {
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw WikipediaError.invalidResponse
            }

            // Handle different HTTP status codes
            switch http.statusCode {
            case 200:
                break // Success
            case 400...499:
                throw WikipediaError.invalidResponse
            case 500...599:
                throw WikipediaError.serverError(http.statusCode)
            default:
                throw WikipediaError.serverError(http.statusCode)
            }

            // Attempt to decode the response
            do {
                let decoded = try JSONDecoder().decode(WikiQueryResponse.self, from: data)
                return decoded.articles
            } catch {
                throw WikipediaError.decodingError
            }

        } catch let error as WikipediaError {
            throw error
        } catch {
            throw await WikipediaError.from(error)
        }
    }
}

// MARK: - Decoding
private nonisolated struct WikiQueryResponse: Decodable {
    let query: Query?

    var articles: [Article] {
        guard let pages = query?.pages else { return [] }
        return pages.map { page in
            Article(
                id: page.pageid,
                title: page.title,
                fullURL: page.fullurl,
                thumbnailURL: page.thumbnail?.source,
                geo: (page.coordinates?.first).map { Geo(lat: $0.lat, lon: $0.lon) }
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
