import Foundation

protocol WikipediaAPIClient: Sendable {
    func search(text: String, limit: Int) async throws -> [Article]
    func nearby(lat: Double, lon: Double, radiusMeters: Int, limit: Int) async throws -> [Article]
}
