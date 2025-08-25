import Foundation

public enum WikipediaError: Error, LocalizedError, Equatable {
    case networkUnavailable
    case invalidResponse
    case noResults
    case locationDenied
    case locationRestricted
    case locationUnavailable
    case requestTimeout
    case serverError(Int)
    case decodingError
    case unknown(String)
    
    // MARK: - Error Categories
    
    public enum ErrorCategory {
        case location
        case network
        case noContent
        case unknown
    }
    
    public var category: ErrorCategory {
        switch self {
        case .locationDenied, .locationRestricted:
            return .location
        case .networkUnavailable, .requestTimeout, .serverError, .invalidResponse, .locationUnavailable, .decodingError:
            return .network
        case .noResults:
            return .noContent
        case .unknown:
            return .unknown
        }
    }
    
    public var requiresFullScreen: Bool {
        category == .location
    }

    // MARK: - Error Descriptions
    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection available"
        case .invalidResponse:
            return "Invalid response from Wikipedia"
        case .noResults:
            return "No articles found"
        case .locationDenied:
            return "Location access denied. Please enable in Settings."
        case .locationRestricted:
            return "Location access restricted"
        case .locationUnavailable:
            return "Unable to determine location"
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .decodingError:
            return "Unable to process response"
        case .unknown(let message):
            return message
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .locationDenied:
            return "Go to Settings > Privacy & Security > Location Services to enable location access."
        case .locationRestricted:
            return "Location services are restricted on this device."
        case .requestTimeout, .serverError, .invalidResponse:
            return "Try again in a few moments."
        case .noResults:
            return "Try different search terms or location."
        case .locationUnavailable:
            return "Make sure location services are enabled and try again."
        default:
            return "Please try again."
        }
    }

    public var shouldShowRetry: Bool {
        switch self {
        case .networkUnavailable, .requestTimeout, .serverError, .invalidResponse, .locationUnavailable:
            return true
        case .locationDenied, .locationRestricted, .noResults, .decodingError, .unknown:
            return false
        }
    }

    public var iconName: String {
        switch category {
        case .location:
            return "location.slash"
        case .network:
            switch self {
            case .networkUnavailable:
                return "wifi.exclamationmark"
            case .requestTimeout:
                return "clock.badge.exclamationmark"
            default:
                return "exclamationmark.triangle"
            }
        case .noContent:
            return "magnifyingglass"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Error Conversion
extension WikipediaError {
    public static func from(_ error: Error) -> WikipediaError {
        if let wikipediaError = error as? WikipediaError {
            return wikipediaError
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .requestTimeout
            case .badServerResponse:
                return .invalidResponse
            default:
                return .unknown(urlError.localizedDescription)
            }
        }

        if let locationError = error as? LocationError {
            switch locationError {
            case .denied:
                return .locationDenied
            case .restricted:
                return .locationRestricted
            case .unableToDetermine:
                return .locationUnavailable
            }
        }

        return .unknown(error.localizedDescription)
    }
}
