import SwiftUI

struct SearchView: View {
    @State var viewModel: SearchViewModel

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    /// Recent searches section shown when input field is empty
                    if viewModel.query.isEmpty, !viewModel.recentSearches.isEmpty {
                        Section("Recent") {
                            ForEach(viewModel.recentSearches, id: \.self) { term in
                                Button(term) { viewModel.selectRecent(term) }
                                    .foregroundStyle(.primary)
                            }
                            .onDelete(perform: viewModel.removeRecent)
                            Button(role: .destructive) { viewModel.clearRecents() } label: {
                                Text("Clear Recent Searches")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }

                    /// Search Results section
                    if !viewModel.results.isEmpty {
                        Section {
                            ForEach(viewModel.results) { article in
                                NavigationLink(value: article) {
                                    ArticleRowView(article: article)
                                }
                            }
                        }
                    }
                }
                .refreshable {
                    if !viewModel.query.isEmpty {
                        viewModel.retrySearch()
                    }
                }
                .overlay {
                    overlayContent
                }
            }
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search articles"
            )
            .searchSuggestions {
                searchSuggestions
            }
            .onChange(of: viewModel.query) {
                viewModel.onQueryChanged()
            }
            .navigationTitle("Search")
            .navigationDestination(for: Article.self) { article in
                if let url = article.fullURL {
                    ArticleDetailView(url: url, title: article.title)
                } else {
                    ContentUnavailableView(
                        "Unavailable",
                        systemImage: "link.slash",
                        description: Text("This article does not have a URL.")
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch viewModel.mode {
        case .idle:
            if viewModel.query.isEmpty {
                ContentUnavailableView(
                    "Search Wikipedia",
                    systemImage: "text.magnifyingglass",
                    description: Text("Type to find articles")
                )
            }

        case .searching:
            ProgressView("Searching…")

        case .results:
            if viewModel.results.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No articles found for '\(viewModel.query)'")
                )
            }

        case .error(let error):
            VStack(spacing: 16) {
                ContentUnavailableView(
                    "Search Failed",
                    systemImage: errorIcon(for: error),
                    description: Text(error.errorDescription ?? "Unknown error")
                )

                if error.shouldShowRetry {
                    Button("Try Again") {
                        viewModel.retrySearch()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private var searchSuggestions: some View {
        if viewModel.query.isEmpty {
            if viewModel.recentSearches.isEmpty {
                Text("No recent searches")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.recentSearches, id: \.self) { term in
                    Button(term) {
                        viewModel.selectRecent(term)
                    }
                }
                Button(role: .destructive) {
                    viewModel.clearRecents()
                } label: {
                    Text("Clear Recent Searches")
                }
            }
        }
    }

    private func errorIcon(for error: WikipediaError) -> String {
        switch error {
        case .networkUnavailable:
            return "wifi.exclamationmark"
        case .noResults:
            return "magnifyingglass"
        case .requestTimeout:
            return "clock.badge.exclamationmark"
        default:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Previews
#Preview("Results") { SearchView(viewModel: .previewWithResults) }
#Preview("Idle - No History") { SearchView(viewModel: .previewIdle) }
#Preview("No Results Found") { SearchView(viewModel: .previewNoResults) }
#Preview("Error - Network") { SearchView(viewModel: .previewNetworkError) }
#Preview("Error - Timeout") { SearchView(viewModel: .previewTimeoutError) }
#Preview("Error - No Results") { SearchView(viewModel: .previewNoResultsError) }
