import SwiftUI
import MapKit
import CoreLocation

struct NearbyView: View {
    @State var viewModel: NearbyViewModel

    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.state {
                case .idle:
                    idleStateView
                case .loading:
                    loadingStateView
                case .failed(let message):
                    errorStateView(message: message)
                case .loaded(let articles):
                    loadedStateView(articles: articles)
                }
            }
            .navigationTitle("Nearby")
            .refreshable {
                viewModel.retry()
            }
            .navigationDestination(for: Article.self) { article in
                articleDestination(article)
            }
        }
    }
    
    // MARK: - State Views
    
    @ViewBuilder
    private var idleStateView: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Nearby Wikipedia",
                systemImage: "location",
                description: Text("Find articles near your current location")
            )
            
            Button("Find Nearby Articles") {
                viewModel.fetchNearby()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    @ViewBuilder
    private var loadingStateView: some View {
        ProgressView("Getting your locationâ€¦")
    }
    
    @ViewBuilder
    private func errorStateView(message: String) -> some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Couldn't Load Nearby Articles",
                systemImage: ErrorMessageHelper.iconForErrorMessage(message),
                description: Text(message)
            )
            
            Button("Try Again") {
                viewModel.retry()
            }
            .buttonStyle(.borderedProminent)
            
            if let suggestion = ErrorMessageHelper.recoverySuggestionForErrorMessage(message) {
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private func loadedStateView(articles: [Article]) -> some View {
        if articles.isEmpty {
            emptyResultsView
        } else {
            VStack(spacing: 0) {
                mapView(with: articles)
                    .frame(height: 300)
                
                articleList(articles: articles)
            }
        }
    }
    
    @ViewBuilder
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "No Articles Nearby",
                systemImage: "mappin.slash",
                description: Text("No Wikipedia articles found in this area")
            )
            
            Button("Try Again") {
                viewModel.retry()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Content Views
    @ViewBuilder
    private func mapView(with articles: [Article]) -> some View {
        Map(position: $viewModel.mapPosition) {
            let items = viewModel.getArticlesWithGeo(from: articles)
            
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
        .onChange(of: viewModel.mapPosition) { _, newValue in
            viewModel.updateMapPosition(newValue)
        }
        .overlay(alignment: .top) {
            searchAreaButton
        }
    }
    
    @ViewBuilder
    private var searchAreaButton: some View {
        if viewModel.shouldShowSearchButton(),
           let center = viewModel.mapCenter {
            Button {
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
    
    @ViewBuilder
    private func articleList(articles: [Article]) -> some View {
        List {
            ForEach(articles) { article in
                NavigationLink(value: article) {
                    ArticleRowView(article: article)
                }
            }
        }
        .refreshable {
            viewModel.retry()
        }
    }
    
    @ViewBuilder
    private func articleDestination(_ article: Article) -> some View {
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

// MARK: - Previews
#Preview("Loaded with Articles") { NearbyView(viewModel: .previewWithArticles) }
#Preview("Empty Results") { NearbyView(viewModel: .previewEmptyResults) }
#Preview("Idle State") { NearbyView(viewModel: .previewIdle) }
#Preview("Loading State") { NearbyView(viewModel: .previewLoading) }
#Preview("Error - Location Denied") { NearbyView(viewModel: .previewLocationError) }
#Preview("Error - Network") { NearbyView(viewModel: .previewNetworkError) }
