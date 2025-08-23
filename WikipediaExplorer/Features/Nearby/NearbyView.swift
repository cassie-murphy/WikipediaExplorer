import SwiftUI
import MapKit
import CoreLocation

private struct ArticleWithGeo: Identifiable {
    let article: Article
    let geo: Geo
    var id: Int { article.id }
}

struct NearbyView: View {
    @State var viewModel: NearbyViewModel
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )
    @State private var mapCenter: CLLocationCoordinate2D?
    @State private var lastFetchedCenter: CLLocationCoordinate2D?

    private func distanceMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.state {
                case .idle:
                    ContentUnavailableView(
                        "Nearby Wikipedia",
                        systemImage: "location",
                        description: Text("Find articles near your current location")
                    )
                    Button("Fetch Nearby") { 
                        viewModel.fetchNearby() 
                    }
                    .buttonStyle(.borderedProminent)

                case .loading:
                    ProgressView("Getting your location…")

                case .failed(let message):
                    ContentUnavailableView(
                        "Couldn’t Load",
                        systemImage: "wifi.exclamationmark",
                        description: Text(message)
                    )
                    Button("Try Again") { 
                        viewModel.fetchNearby() 
                    }

                case .loaded(let articles):
                    mapView(with: articles)
                        .frame(height: 300)
                    
                    articleList(articles)
                }
            }
            .navigationTitle("Nearby")
            .task(id: viewModel.state) {
                handleStateChange()
            }
            .navigationDestination(for: Article.self) { article in
                if let url = article.fullURL {
                    ArticleDetailView(url: url, title: article.title)
                } else {
                    ContentUnavailableView(
                        "Unavailable",
                        systemImage: "link.slash",
                        description: Text("This article does not have a URL.")
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func mapView(with articles: [Article]) -> some View {
        Map(position: $mapPosition) {
            let items: [ArticleWithGeo] = articles.compactMap { article in
                guard let geo = article.geo, article.fullURL != nil else { return nil }
                return ArticleWithGeo(article: article, geo: geo)
            }
            
            ForEach(items) { item in
                Annotation(item.article.title, coordinate: CLLocationCoordinate2D(
                    latitude: item.geo.lat,
                    longitude: item.geo.lon
                )) {
                    NavigationLink(value: item.article) {
                        Image(systemName: "mappin.circle")
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onChange(of: mapPosition) { _, newValue in
            if let region = mapPosition.region {
                mapCenter = region.center
            }
        }
        .overlay(alignment: .top) {
            searchAreaButtonIfAppropriate()
        }
    }
    
    @ViewBuilder
    private func searchAreaButtonIfAppropriate() -> some View {
        if shouldShowSearchButton,
           let center = mapCenter {
            Button {
                lastFetchedCenter = center
                viewModel.fetchNearby(at: center)
            } label: {
                Label("Search This Area", systemImage: "magnifyingglass.circle.fill")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
    }
    
    private var shouldShowSearchButton: Bool {
        guard let center = mapCenter else { return false }
        
        let thresholdMeters: CLLocationDistance = 1_000
        if let last = lastFetchedCenter {
            return distanceMeters(center, last) > thresholdMeters
        } else {
            return true
        }
    }
    
    private func articleList(_ articles: [Article]) -> some View {
        List {
            ForEach(articles) { article in
                NavigationLink(value: article) {
                    ArticleRowView(article: article)
                }
            }
        }
    }
    
    private func handleStateChange() {
        switch viewModel.state {
        case .idle:
            viewModel.fetchNearby()
        case .loaded(let articles):
            if let first = articles.first?.geo {
                let region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: first.lat, longitude: first.lon),
                    span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
                )
                mapPosition = .region(region)
                lastFetchedCenter = CLLocationCoordinate2D(latitude: first.lat, longitude: first.lon)
            }
        default:
            break
        }
    }
}
