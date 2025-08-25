import SwiftUI

struct NearbyEmptyView: View {
    @Binding var showSearchButton: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("No Articles Found")
                .font(.headline)
            
            Text("No Wikipedia articles in this area")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Search Different Area") {
                withAnimation {
                    showSearchButton = true
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding()
        .background(Color("AppBackgroundColor"))
    }
}

#Preview {
    NearbyEmptyView(showSearchButton: .constant(false))
}
