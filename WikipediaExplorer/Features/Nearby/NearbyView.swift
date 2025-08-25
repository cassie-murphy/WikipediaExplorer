import SwiftUI
import MapKit
import CoreLocation

struct NearbyView: View {
    @State var viewModel: NearbyViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map takes up available space
                if !viewModel.isLocationBlocked {
                    NearbyMapView(
                        mapCameraPosition: $viewModel.mapCameraPosition,
                        isUserTrackingMode: $viewModel.isUserTrackingMode,
                        selectedMapArticle: $viewModel.selectedMapArticle,
                        showingSearchButton: $viewModel.showingSearchButton,
                        articles: viewModel.articles,
                        onMapMoved: viewModel.handleMapMoved,
                        onSearchArea: viewModel.handleSearchArea
                    )
                    .frame(maxHeight: .infinity)
                }
                
                // Bottom content based on state
                bottomContent
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nearby")
                        .font(.headline)
                }
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
            .onAppear {
                viewModel.onAppear()
            }
        }
    }
    
    // MARK: - Bottom Content
    @ViewBuilder
    private var bottomContent: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
            
        case .loading:
            NearbyLoadingView()
            
        case .failed(let error):
            if error.requiresFullScreen {
                // Full screen error for location issues
                Spacer()
                NearbyErrorView(
                    error: error,
                    onRetry: viewModel.retry
                )
                Spacer()
            } else {
                // Bottom error view for API/network errors
                NearbyErrorView(
                    error: error,
                    onRetry: viewModel.retry
                )
            }
            
        case .loaded(let articles):
            if articles.isEmpty {
                NearbyEmptyView(showSearchButton: $viewModel.showingSearchButton)
            } else {
                ArticleListView.nearby(
                    articles: articles,
                    onRefresh: viewModel.retry
                )
            }
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
