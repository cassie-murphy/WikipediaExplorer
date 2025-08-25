import SwiftUI
import MapKit
import CoreLocation

struct NearbyMapView: View {
    @Binding var mapCameraPosition: MapCameraPosition
    @Binding var isUserTrackingMode: Bool
    @Binding var selectedMapArticle: Article?
    @Binding var showingSearchButton: Bool
    
    let articles: [Article]
    let onMapMoved: (CLLocationCoordinate2D) -> Void
    let onSearchArea: (CLLocationCoordinate2D) -> Void
    
    @State private var currentMapCenter: CLLocationCoordinate2D?
    
    var body: some View {
        Map(position: $mapCameraPosition, interactionModes: .all, selection: $selectedMapArticle) {
            UserAnnotation()
            
            // Article annotations
            ForEach(getArticlesWithGeo()) { item in
                Marker(item.article.title, coordinate: CLLocationCoordinate2D(
                    latitude: item.geo.lat,
                    longitude: item.geo.lon
                ))
                .tint(.red)
                .tag(item.article)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            let newCenter = context.camera.centerCoordinate
            currentMapCenter = newCenter
            
            // Only process if user manually moved the map
            if !isUserTrackingMode {
                onMapMoved(newCenter)
            }
            
            // User has moved the map manually
            isUserTrackingMode = false
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 12) {
                // Selected article callout
                if let article = selectedMapArticle {
                    ArticleCallout(article: article)
                }
                
                // Search area button
                if showingSearchButton {
                    SearchAreaButton {
                        if let center = currentMapCenter {
                            onSearchArea(center)
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }
    
    private func getArticlesWithGeo() -> [ArticleWithGeo] {
        articles.compactMap { article in
            guard let geo = article.geo, article.fullURL != nil else { return nil }
            return ArticleWithGeo(article: article, geo: geo)
        }
    }
}

// MARK: - Supporting Components

private struct ArticleCallout: View {
    let article: Article
    
    var body: some View {
        HStack(spacing: 12) {
            if let thumbnail = article.thumbnailURL {
                CachedAsyncImage(url: thumbnail, width: 50, height: 50)
            } else {
                Image(systemName: "doc.text")
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let geo = article.geo {
                    Text(String(format: "%.4f, %.4f", geo.lat, geo.lon))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            NavigationLink(value: article) {
                Image(systemName: "chevron.right.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

private struct SearchAreaButton: View {
    let onSearch: () -> Void
    
    var body: some View {
        Button(action: onSearch) {
            Label("Search This Area", systemImage: "magnifyingglass")
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview("Map with Selected Article") {
    NearbyMapView(
        mapCameraPosition: .constant(.region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))),
        isUserTrackingMode: .constant(true),
        selectedMapArticle: .constant(PreviewData.singleArticle),
        showingSearchButton: .constant(false),
        articles: PreviewData.articlesWithGeo,
        onMapMoved: { _ in },
        onSearchArea: { _ in }
    )
}
