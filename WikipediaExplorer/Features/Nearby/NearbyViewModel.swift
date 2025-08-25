import SwiftUI
import CoreLocation
import MapKit

@Observable
final class NearbyViewModel {
    private let api: WikipediaAPIClient
    private let location: LocationProviderProtocol
    
    // State
    var state: Loadable<[Article]> = .idle
    var mapCameraPosition = MapCameraPosition.userLocation(fallback: .automatic)
    var isUserTrackingMode = true
    var selectedMapArticle: Article?
    var showingSearchButton = false
    
    // Map tracking
    var mapCenter: CLLocationCoordinate2D?
    var lastFetchedCenter: CLLocationCoordinate2D?
    var userLocation: CLLocationCoordinate2D?
    
    // Distance threshold in meters to show search button
    private let searchButtonThreshold: CLLocationDistance = 500
    
    init(api: WikipediaAPIClient, location: LocationProviderProtocol) {
        self.api = api
        self.location = location
    }
    
    // MARK: - Computed Properties
    var articles: [Article] {
        if case .loaded(let articles) = state {
            return articles
        }
        return []
    }
    
    var isLocationBlocked: Bool {
        if case .failed(let error) = state {
            return error.requiresFullScreen
        }
        return false
    }
    
    var shouldShowSearchButton: Bool {
        guard let center = mapCenter else { return false }
        
        // Don't show if we haven't fetched anything yet
        guard let last = lastFetchedCenter else { return true }
        
        // Show if user has moved the map significantly
        return distanceMeters(center, last) > searchButtonThreshold
    }
    
    // MARK: - Public Methods
    func onAppear() {
        if case .idle = state {
            fetchNearby()
        }
    }
    
    func fetchNearby() {
        Task {
            await MainActor.run { self.state = .loading }
            
            do {
                let loc = try await location.requestCurrentLocation()
                self.userLocation = loc.coordinate
                
                // Store the center immediately after getting location, before API call
                await MainActor.run {
                    self.lastFetchedCenter = loc.coordinate
                    self.mapCenter = loc.coordinate
                }
                
                let articles = try await api.nearby(
                    lat: loc.coordinate.latitude,
                    lon: loc.coordinate.longitude,
                    radiusMeters: 10_000,
                    limit: 30
                )
                
                await MainActor.run {
                    self.state = .loaded(articles)
                    self.adjustMapToShowArticles(articles)
                    self.showingSearchButton = false
                }
                
            } catch {
                let wikipediaError = WikipediaError.from(error)
                await MainActor.run {
                    self.state = .failed(wikipediaError)
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
                    self.adjustMapToShowArticles(articles)
                    self.showingSearchButton = false
                }
                
            } catch {
                let wikipediaError = WikipediaError.from(error)
                await MainActor.run {
                    self.state = .failed(wikipediaError)
                }
            }
        }
    }
    
    func retry() {
        // If we have a last fetched center, use it; otherwise fetch from user location
        if let center = lastFetchedCenter {
            fetchNearby(at: center)
        } else {
            fetchNearby()
        }
    }
    
    // MARK: - Map Event Handlers
    func handleMapMoved(_ coordinate: CLLocationCoordinate2D) {
        mapCenter = coordinate
        
        // Show search button if moved significantly
        if shouldShowSearchButton {
            withAnimation {
                showingSearchButton = true
            }
        }
    }
    
    func handleSearchArea(_ coordinate: CLLocationCoordinate2D) {
        fetchNearby(at: coordinate)
        withAnimation {
            showingSearchButton = false
        }
    }
    
    func handleSearchButtonFromEmpty() {
        withAnimation {
            showingSearchButton = true
        }
    }
    
    // MARK: - Map Helpers
    func getArticlesWithGeo(from articles: [Article]) -> [ArticleWithGeo] {
        return articles.compactMap { article in
            guard let geo = article.geo, article.fullURL != nil else { return nil }
            return ArticleWithGeo(article: article, geo: geo)
        }
    }
    
    private func adjustMapToShowArticles(_ articles: [Article]) {
        let items = getArticlesWithGeo(from: articles)
        guard !items.isEmpty else { return }
        
        // Calculate the region that encompasses all articles
        let coordinates = items.map { CLLocationCoordinate2D(latitude: $0.geo.lat, longitude: $0.geo.lon) }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Add padding to the span to ensure all pins are visible
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.02, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.02, (maxLon - minLon) * 1.5)
        )
        
        withAnimation {
            mapCameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
        
        lastFetchedCenter = center
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
