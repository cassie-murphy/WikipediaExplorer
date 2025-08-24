import CoreLocation

// MARK: - Protocol
protocol LocationProviderProtocol: AnyObject {
    @MainActor
    func requestCurrentLocation() async throws -> CLLocation
}

// MARK: - Implementation
enum LocationError: Error {
    case denied
    case restricted
    case unableToDetermine
}

final class LocationProvider: NSObject, CLLocationManagerDelegate, LocationProviderProtocol {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private let timeoutDuration: TimeInterval = 15.0
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    @MainActor
    func requestCurrentLocation() async throws -> CLLocation {
        // Clean up any existing request
        cleanup()
        
        // Check authorization status
        switch manager.authorizationStatus {
        case .notDetermined:
            return try await requestLocationWithAuthorization()
        case .denied:
            throw WikipediaError.locationDenied
        case .restricted:
            throw WikipediaError.locationRestricted
        case .authorizedWhenInUse, .authorizedAlways:
            return try await performLocationRequest()
        @unknown default:
            throw WikipediaError.locationUnavailable
        }
    }
    
    // MARK: - Private Methods
    private func requestLocationWithAuthorization() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.startTimeout()
            manager.requestWhenInUseAuthorization()
            // Location request will be triggered in authorization callback
        }
    }

    private func performLocationRequest() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.startTimeout()
            manager.requestLocation()
        }
    }

    private func startTimeout() {
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self!.timeoutDuration * 1_000_000_000))
            await MainActor.run {
                self?.handleTimeout()
            }
        }
    }

    private func handleTimeout() {
        guard let continuation = locationContinuation else { return }
        cleanup()
        continuation.resume(throwing: WikipediaError.requestTimeout)
    }

    private func cleanup() {
        timeoutTask?.cancel()
        timeoutTask = nil
        locationContinuation = nil
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let continuation = locationContinuation else { return }
        cleanup()
        
        if let location = locations.first {
            continuation.resume(returning: location)
        } else {
            continuation.resume(throwing: WikipediaError.locationUnavailable)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let continuation = locationContinuation else { return }
        cleanup()
        continuation.resume(throwing: WikipediaError.from(error))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard locationContinuation != nil else { return }
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied:
            guard let continuation = locationContinuation else { return }
            cleanup()
            continuation.resume(throwing: WikipediaError.locationDenied)
        case .restricted:
            guard let continuation = locationContinuation else { return }
            cleanup()
            continuation.resume(throwing: WikipediaError.locationRestricted)
        case .notDetermined:
            break // Wait for user decision
        @unknown default:
            guard let continuation = locationContinuation else { return }
            cleanup()
            continuation.resume(throwing: WikipediaError.locationUnavailable)
        }
    }
}
