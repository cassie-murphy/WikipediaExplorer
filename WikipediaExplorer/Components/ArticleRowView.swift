import SwiftUI

struct ArticleRowView: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: article.thumbnailURL) { phase in
                switch phase {
                case .empty:
                    ProgressView().frame(width: 60, height: 60)
                case .success(let image):
                    image.resizable().scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                case .failure:
                    Image(systemName: "photo").frame(width: 60, height: 60)
                @unknown default:
                    EmptyView().frame(width: 60, height: 60)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title).font(.headline).lineLimit(2)
                if let geo = article.geo {
                    Text(String(format: "Lat: %.4f  Lon: %.4f", geo.lat, geo.lon))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
