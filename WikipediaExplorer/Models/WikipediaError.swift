import Foundation

enum WikipediaError: Error, LocalizedError, Equatable {
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
    
    var errorDescription: String? {
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
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .locationDenied:
            return "Go to Settings > Privacy & Security > Location Services to enable location access."
        case .requestTimeout, .serverError, .invalidResponse:
            return "Try again in a few moments."
        case .noResults:
            return "Try different search terms."
        default:
            return "Please try again."
        }
    }
    
    var shouldShowRetry: Bool {
        switch self {
        case .networkUnavailable, .requestTimeout, .serverError, .invalidResponse, .locationUnavailable:
            return true
        case .locationDenied, .locationRestricted:
            return false
        case .noResults, .decodingError, .unknown:
            return false
        }
    }
}

/// Extension for converting common errors
extension WikipediaError {
    static func from(_ error: Error) -> WikipediaError {
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
