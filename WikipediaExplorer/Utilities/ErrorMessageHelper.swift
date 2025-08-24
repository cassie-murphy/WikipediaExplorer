import Foundation

struct ErrorMessageHelper {
    static func iconForErrorMessage(_ message: String) -> String {
        if message.contains("Location access denied") || message.contains("location") {
            return "location.slash"
        } else if message.contains("internet") || message.contains("network") {
            return "wifi.exclamationmark"
        } else if message.contains("timed out") || message.contains("timeout") {
            return "clock.badge.exclamationmark"
        } else {
            return "exclamationmark.triangle"
        }
    }
    
    static func recoverySuggestionForErrorMessage(_ message: String) -> String? {
        if message.contains("Location access denied") {
            return "Go to Settings > Privacy & Security > Location Services to enable location access."
        } else if message.contains("internet") || message.contains("network") {
            return "Check your internet connection and try again."
        } else if message.contains("timed out") {
            return "The request took too long. Try again in a moment."
        } else {
            return nil
        }
    }
}
