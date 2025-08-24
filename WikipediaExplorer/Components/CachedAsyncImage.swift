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
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: width, height: height)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .cornerRadius(8)

            case .failure:
                Image(systemName: "photo")
                    .foregroundColor(.gray)
                    .frame(width: width, height: height)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

            @unknown default:
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: width, height: height)
                    .cornerRadius(8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: url)
    }
}
