import SwiftUI

struct RootView: View {
    let api: WikipediaAPIClient
    let location: LocationProvider

    var body: some View {
        TabView {
            SearchView(viewModel: SearchViewModel(api: api))
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            NearbyView(viewModel: NearbyViewModel(api: api, location: location))
                .tabItem { Label("Nearby", systemImage: "mappin.and.ellipse") }
        }
    }
}
