import SwiftUI

struct NearbyLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading nearby articles...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color("AppBackgroundColor"))
    }
}
