import SwiftUI

struct ArticleRowView: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CachedAsyncImage(url: article.thumbnailURL, width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let geo = article.geo {
                    Text(String(format: "Lat: %.4f  Lon: %.4f", geo.lat, geo.lon))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
