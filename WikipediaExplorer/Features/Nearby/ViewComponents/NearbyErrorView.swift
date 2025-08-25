import SwiftUI

struct NearbyErrorView: View {
    let error: WikipediaError
    let onRetry: () -> Void
    
    var body: some View {
        if error.requiresFullScreen {
            // Full screen error for location issues
            ContentUnavailableView(
                "Location Access Required",
                systemImage: error.iconName,
                description: Text(error.errorDescription ?? "Unknown error")
            )
            .overlay(alignment: .bottom) {
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        } else {
            // Compact error for API/network issues
            VStack(spacing: 16) {
                Image(systemName: error.iconName)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                
                Text("Unable to Load Articles")
                    .font(.headline)
                
                Text(error.errorDescription ?? "Unknown error")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                if error.shouldShowRetry {
                    Button("Try Again", action: onRetry)
                        .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .padding()
            .background(Color("AppBackgroundColor"))
        }
    }
}

// MARK: - Previews

#Preview("Network Error") {
    NearbyErrorView(
        error: .networkUnavailable,
        onRetry: { print("Retry tapped") }
    )
}

#Preview("API Error") {
    NearbyErrorView(
        error: .serverError(500),
        onRetry: { print("Retry tapped") }
    )
}

#Preview("Location Denied - Full Screen") {
    NearbyErrorView(
        error: .locationDenied,
        onRetry: { print("Retry tapped") }
    )
}

#Preview("Location Restricted - Full Screen") {
    NearbyErrorView(
        error: .locationRestricted,
        onRetry: { print("Retry tapped") }
    )
}

#Preview("No Results") {
    NearbyErrorView(
        error: .noResults,
        onRetry: { print("Retry tapped") }
    )
}
