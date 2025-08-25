import SwiftUI

/// Reusable article list component that can be used in both Nearby and Search views
struct ArticleListView: View {
    let articles: [Article]
    let headerContent: HeaderContent?
    let showDivider: Bool
    let listHeight: CGFloat?
    
    enum HeaderContent {
        case nearby(count: Int, onRefresh: () -> Void)
        case search // Search view doesn't need a header since it has the search bar
    }
    
    init(
        articles: [Article],
        headerContent: HeaderContent? = nil,
        showDivider: Bool = true,
        listHeight: CGFloat? = nil
    ) {
        self.articles = articles
        self.headerContent = headerContent
        self.showDivider = showDivider
        self.listHeight = listHeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Optional header
            if let headerContent = headerContent {
                switch headerContent {
                case .nearby(let count, let onRefresh):
                    HStack {
                        Text("\(count) articles found")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Refresh", action: onRefresh)
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.secondarySystemBackground))
                    
                case .search:
                    EmptyView()
                }
                
                if showDivider {
                    Divider()
                }
            }
            
            // Article list
            List(articles) { article in
                NavigationLink(value: article) {
                    ArticleRowView(article: article)
                }
            }
            .listStyle(.plain)
            .frame(height: listHeight)
        }
        .background(Color("AppBackgroundColor"))
    }
}

// Convenience initializers for specific use cases
extension ArticleListView {
    /// Nearby view configuration with header and fixed height
    static func nearby(articles: [Article], onRefresh: @escaping () -> Void) -> ArticleListView {
        ArticleListView(
            articles: articles,
            headerContent: .nearby(count: articles.count, onRefresh: onRefresh),
            showDivider: true,
            listHeight: 300
        )
    }
    
    /// Search view configuration without header, flexible height
    static func search(articles: [Article]) -> ArticleListView {
        ArticleListView(
            articles: articles,
            headerContent: nil,
            showDivider: false,
            listHeight: nil
        )
    }
}

// MARK: - Previews

#Preview("Nearby List with Articles") {
    ArticleListView.nearby(
        articles: PreviewData.articlesWithGeo,
        onRefresh: { print("Refresh tapped") }
    )
}

#Preview("Search List") {
    ArticleListView.search(
        articles: PreviewData.articles
    )
}

#Preview("Empty List") {
    ArticleListView.nearby(
        articles: [],
        onRefresh: { print("Refresh tapped") }
    )
}
