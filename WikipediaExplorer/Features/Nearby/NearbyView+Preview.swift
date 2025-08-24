import SwiftUI
import MapKit
import CoreLocation

#if DEBUG

// MARK: - Preview Extensions
extension NearbyViewModel {
    static var previewIdle: NearbyViewModel {
        let viewModel = NearbyViewModel(api: PreviewMocks.apiClient, location: PreviewMocks.locationProvider)
        viewModel.state = Loadable<[Article]>.idle
        return viewModel
    }
    
    static var previewLoading: NearbyViewModel {
        let viewModel = NearbyViewModel(api: PreviewMocks.apiClient, location: PreviewMocks.locationProvider)
        viewModel.state = Loadable<[Article]>.loading
        return viewModel
    }
    
    static var previewLocationError: NearbyViewModel {
        let viewModel = NearbyViewModel(api: PreviewMocks.apiClient, location: PreviewMocks.locationProvider)
        viewModel.state = Loadable<[Article]>.failed("Location access denied. Please enable in Settings.")
        return viewModel
    }
    
    static var previewNetworkError: NearbyViewModel {
        let viewModel = NearbyViewModel(api: PreviewMocks.apiClient, location: PreviewMocks.locationProvider)
        viewModel.state = Loadable<[Article]>.failed("No internet connection available")
        return viewModel
    }
    
    static var previewEmptyResults: NearbyViewModel {
        let viewModel = NearbyViewModel(api: PreviewMocks.apiClient, location: PreviewMocks.locationProvider)
        viewModel.state = Loadable<[Article]>.loaded([])
        return viewModel
    }
    
    static var previewWithArticles: NearbyViewModel {
        let viewModel = NearbyViewModel(api: PreviewMocks.apiClient, location: PreviewMocks.locationProvider)
        viewModel.state = Loadable<[Article]>.loaded(PreviewData.sanFranciscoArticles)
        
        // Set up map to show San Francisco
        viewModel.mapPosition = MapCameraPosition.region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        )
        viewModel.mapCenter = CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783)
        viewModel.lastFetchedCenter = CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783)
        
        return viewModel
    }
}

// MARK: - Preview Data
struct PreviewData {
    static let sanFranciscoArticles = [
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
            title: "Lombard Street",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Lombard_Street_(San_Francisco)"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Lombard_Street.jpg/200px-Lombard_Street.jpg"),
            geo: Geo(lat: 37.8021, lon: -122.4187)
        ),
        Article(
            id: 4,
            title: "Fisherman's Wharf",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Fisherman%27s_Wharf,_San_Francisco"),
            thumbnailURL: nil,
            geo: Geo(lat: 37.8081, lon: -122.4103)
        ),
        Article(
            id: 5,
            title: "Coit Tower",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Coit_Tower"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Coit_tower.jpg/200px-Coit_tower.jpg"),
            geo: Geo(lat: 37.8024, lon: -122.4058)
        )
    ]
    
    static let newYorkArticles = [
        Article(
            id: 10,
            title: "Statue of Liberty",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Statue_of_Liberty"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Statue_of_Liberty_7.jpg/200px-Statue_of_Liberty_7.jpg"),
            geo: Geo(lat: 40.6892, lon: -74.0445)
        ),
        Article(
            id: 11,
            title: "Empire State Building",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Empire_State_Building"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Empire_State_Building_from_the_Top_of_the_Rock.jpg/200px-Empire_State_Building_from_the_Top_of_the_Rock.jpg"),
            geo: Geo(lat: 40.7484, lon: -73.9857)
        ),
        Article(
            id: 12,
            title: "Central Park",
            fullURL: URL(string: "https://en.wikipedia.org/wiki/Central_Park"),
            thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Above_Gotham.jpg/200px-Above_Gotham.jpg"),
            geo: Geo(lat: 40.7829, lon: -73.9654)
        )
    ]
}

// MARK: - Preview Mocks
struct PreviewMocks {
    static let apiClient: WikipediaAPIClient = PreviewWikipediaAPIClient()
    static let locationProvider: LocationProviderProtocol = PreviewLocationProvider()
}

fileprivate struct PreviewWikipediaAPIClient: WikipediaAPIClient {
    func search(text: String, limit: Int) async throws -> [Article] {
        return []
    }
    
    func nearby(lat: Double, lon: Double, radiusMeters: Int, limit: Int) async throws -> [Article] {
        return []
    }
}

fileprivate final class PreviewLocationProvider: LocationProviderProtocol {
    @MainActor
    func requestCurrentLocation() async throws -> CLLocation {
        // Return a default San Francisco location for previews
        return CLLocation(latitude: 37.7749, longitude: -122.4194)
    }
}

#endif
