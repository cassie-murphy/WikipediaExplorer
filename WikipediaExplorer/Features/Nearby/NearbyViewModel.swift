import SwiftUI
import CoreLocation
import MapKit

@Observable
final class NearbyViewModel {
    private let api: WikipediaAPIClient
    private let location: LocationProviderProtocol

    var state: Loadable<[Article]> = .idle
    var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )
    var mapCenter: CLLocationCoordinate2D?
    var lastFetchedCenter: CLLocationCoordinate2D?

    init(api: WikipediaAPIClient, location: LocationProviderProtocol) {
        self.api = api
        self.location = location
    }

    func fetchNearby() {
        Task {
            await MainActor.run { self.state = .loading }

            do {
                let loc = try await location.requestCurrentLocation()
                let articles = try await api.nearby(
                    lat: loc.coordinate.latitude,
                    lon: loc.coordinate.longitude,
                    radiusMeters: 10_000,
                    limit: 30
                )

                await MainActor.run {
                    self.state = .loaded(articles)
                    self.updateMapForArticles(articles)
                }

            } catch {
                let wikipediaError = WikipediaError.from(error)
                await MainActor.run {
                    self.state = .failed(wikipediaError.errorDescription ?? "Unknown error")
                }
            }
        }
    }

    func fetchNearby(at center: CLLocationCoordinate2D,
                     radiusMeters: Int = 10_000,
                     limit: Int = 30) {
        Task {
            await MainActor.run { self.state = .loading }

            do {
                let articles = try await api.nearby(
                    lat: center.latitude,
                    lon: center.longitude,
                    radiusMeters: radiusMeters,
                    limit: limit
                )

                await MainActor.run {
                    self.state = .loaded(articles)
                    self.lastFetchedCenter = center
                }

            } catch {
                let wikipediaError = WikipediaError.from(error)
                await MainActor.run {
                    self.state = .failed(wikipediaError.errorDescription ?? "Unknown error")
                }
            }
        }
    }

    func retry() {
        fetchNearby()
    }

    func updateMapPosition(_ newPosition: MapCameraPosition) {
        mapPosition = newPosition
        if let region = newPosition.region {
            mapCenter = region.center
        }
    }

    func shouldShowSearchButton() -> Bool {
        guard let center = mapCenter else { return false }

        let thresholdMeters: CLLocationDistance = 1_000
        if let last = lastFetchedCenter {
            return distanceMeters(center, last) > thresholdMeters
        } else {
            return true
        }
    }

    func getArticlesWithGeo(from articles: [Article]) -> [ArticleWithGeo] {
        return articles.compactMap { article in
            guard let geo = article.geo, article.fullURL != nil else { return nil }
            return ArticleWithGeo(article: article, geo: geo)
        }
    }

    // MARK: - Private Helpers
    private func updateMapForArticles(_ articles: [Article]) {
        guard let first = articles.first?.geo else { return }

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: first.lat, longitude: first.lon),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        )
        mapPosition = .region(region)
        lastFetchedCenter = CLLocationCoordinate2D(latitude: first.lat, longitude: first.lon)
    }

    private func distanceMeters(_ first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: first.latitude, longitude: first.longitude)
            .distance(from: CLLocation(latitude: second.latitude, longitude: second.longitude))
    }
}

// MARK: - Supporting Types
struct ArticleWithGeo: Identifiable {
    let article: Article
    let geo: Geo
    var id: Int { article.id }
}
