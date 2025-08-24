import Foundation

enum WikipediaEndpoint {
    case search(text: String, limit: Int = 20)
    case nearby(lat: Double, lon: Double, radiusMeters: Int = 10_000, limit: Int = 20)

    private var base: String { "https://en.wikipedia.org/w/api.php" }

    func urlRequest(userAgent: String, timeout: TimeInterval = 10.0) throws -> URLRequest {
        var comps = URLComponents(string: base)!
        var items: [URLQueryItem] = [
            .init(name: "action", value: "query"),
            .init(name: "format", value: "json"),
            .init(name: "formatversion", value: "2"),
            .init(name: "prop", value: "coordinates|pageimages|info"),
            .init(name: "inprop", value: "url"),
            .init(name: "pithumbsize", value: "200")
        ]

        switch self {
        case .search(let text, let limit):
            items += [
                .init(name: "generator", value: "search"),
                .init(name: "gsrsearch", value: text),
                .init(name: "gsrlimit", value: String(limit))
            ]
        case .nearby(let lat, let lon, let radius, let limit):
            items += [
                .init(name: "generator", value: "geosearch"),
                .init(name: "ggscoord", value: "\(lat)|\(lon)"),
                .init(name: "ggsradius", value: String(radius)),
                .init(name: "ggslimit", value: String(limit))
            ]
        }

        comps.queryItems = items
        guard let url = comps.url else { throw WikipediaError.invalidResponse }

        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = timeout
        return req
    }
}
