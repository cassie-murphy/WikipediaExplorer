import SwiftUI
import CoreLocation

@Observable
final class NearbyViewModel {
   private let api: WikipediaAPIClient
   private let location: LocationProvider

   var state: Loadable<[Article]> = .idle

   init(api: WikipediaAPIClient, location: LocationProvider) {
       self.api = api
       self.location = location
   }

   func fetchNearby() {
       Task {
           await MainActor.run { self.state = .loading }
           do {
               let loc = try await location.requestCurrentLocation()
               let items = try await api.nearby(lat: loc.coordinate.latitude,
                                                lon: loc.coordinate.longitude,
                                                radiusMeters: 10_000,
                                                limit: 30)
               await MainActor.run { self.state = .loaded(items) }
           } catch {
               await MainActor.run { self.state = .failed("Location or fetch failed. Check permissions and try again.") }
           }
       }
   }
    /// Fetch nearby articles centered at an explicit coordinate (used by "Search This Area")
    func fetchNearby(at center: CLLocationCoordinate2D,
                     radiusMeters: Int = 10_000,
                     limit: Int = 30) {
        Task {
            await MainActor.run { self.state = .loading }
            do {
                let items = try await api.nearby(
                    lat: center.latitude,
                    lon: center.longitude,
                    radiusMeters: radiusMeters,
                    limit: limit
                )
                await MainActor.run { self.state = .loaded(items) }
            } catch {
                await MainActor.run {
                    self.state = .failed("Couldn't load this area. Please try again.")
                }
            }
        }
    }
}
