import SwiftUI

@main
struct WikipediaExplorerApp: App {
    private let api: WikipediaAPIClient = LiveWikipediaAPIClient(
        userAgent: "WikipediaExplorer/1.0 (contact: cassie.murphy@cmdevlabs.com)"
    )
    private let location = LocationProvider()

    var body: some Scene {
        WindowGroup {
            RootView(api: api, location: location)
        }
    }
}
