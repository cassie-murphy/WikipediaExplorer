import SwiftUI

struct CachedAsyncImage: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    
    init(url: URL?, width: CGFloat = 60, height: CGFloat = 60) {
        self.url = url
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: width, height: height)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: height)
                            .clipped()
                            .cornerRadius(8)
                        
                    case .failure:
                        fallbackIcon
                        
                    @unknown default:
                        fallbackIcon
                    }
                }
            } else {
                // No URL provided - show fallback immediately
                fallbackIcon
            }
        }
        .animation(.easeInOut(duration: 0.2), value: url)
    }
    
    private var fallbackIcon: some View {
        Image(systemName: "photo.artframe")
            .font(.system(size: width * 0.4))
            .foregroundStyle(.secondary)
            .frame(width: width, height: height)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}
