import SwiftUI
import MapKit
import CoreLocation

#if DEBUG

// MARK: - Preview ViewModels for NearbyView
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
        viewModel.state = Loadable<[Article]>.failed(.locationDenied)
        return viewModel
    }

    static var previewNetworkError: NearbyViewModel {
        let viewModel = NearbyViewModel(api: PreviewMocks.apiClient, location: PreviewMocks.locationProvider)
        viewModel.state = Loadable<[Article]>.failed(.networkUnavailable)
        return viewModel
    }

    static var previewEmptyResults: NearbyViewModel {
        let viewModel = NearbyViewModel(api: PreviewMocks.apiClient, location: PreviewMocks.locationProvider)
        viewModel.state = Loadable<[Article]>.loaded([])
        return viewModel
    }

    static var previewWithArticles: NearbyViewModel {
        let viewModel = NearbyViewModel(api: PreviewMocks.apiClient, location: PreviewMocks.locationProvider)
        viewModel.state = Loadable<[Article]>.loaded(PreviewData.articlesWithGeo)
        viewModel.mapCenter = CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783)
        viewModel.lastFetchedCenter = CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783)
        return viewModel
    }
}
#endif
