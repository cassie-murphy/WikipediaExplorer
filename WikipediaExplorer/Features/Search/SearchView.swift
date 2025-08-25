import SwiftUI

struct SearchView: View {
    @State var viewModel: SearchViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                // Main content based on mode
                switch viewModel.mode {
                case .idle:
                    if viewModel.query.isEmpty {
                        idleContent
                    } else {
                        ContentUnavailableView(
                            "Search Wikipedia",
                            systemImage: "text.magnifyingglass",
                            description: Text("Type to find articles")
                        )
                    }
                    
                case .searching:
                    Spacer()
                    ProgressView("Searching…")
                    Spacer()
                    
                case .results:
                    if viewModel.results.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("No articles found for '\(viewModel.query)'")
                        )
                    } else {
                        ArticleListView.search(articles: viewModel.results)
                    }
                    
                case .error(let error):
                    errorContent(error: error)
                }
            }
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search articles"
            )
            .onSubmit(of: .search) {
                // Commit search when user taps search button on keyboard
                viewModel.commitSearch()
            }
            .onChange(of: viewModel.query) {
                viewModel.onQueryChanged()
            }
            .navigationTitle("Search")
            .navigationDestination(for: Article.self) { article in
                if let url = article.fullURL {
                    ArticleDetailView(url: url, title: article.title)
                        .onAppear {
                            // Commit search when user navigates to an article
                            viewModel.commitSearch()
                        }
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
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var idleContent: some View {
        if viewModel.recentSearches.isEmpty {
            ContentUnavailableView(
                "Search Wikipedia",
                systemImage: "text.magnifyingglass",
                description: Text("Type to find articles")
            )
        } else {
            List {
                Section("Recent") {
                    ForEach(viewModel.recentSearches, id: \.self) { term in
                        Button(term) {
                            viewModel.selectRecent(term)
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete(perform: viewModel.removeRecent)
                    
                    Button(role: .destructive) {
                        viewModel.clearRecents()
                    } label: {
                        Text("Clear Recent Searches")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    @ViewBuilder
    private func errorContent(error: WikipediaError) -> some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Search Failed",
                systemImage: error.iconName,
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

// MARK: - Previews

#Preview("Idle - No History") {
    SearchView(viewModel: .previewIdle)
}

#Preview("Idle - With History") {
    SearchView(viewModel: .previewWithHistory)
}

#Preview("Searching") {
    SearchView(viewModel: .previewSearching)
}

#Preview("Results") {
    SearchView(viewModel: .previewWithResults)
}

#Preview("No Results") {
    SearchView(viewModel: .previewNoResults)
}

#Preview("Error - Network") {
    SearchView(viewModel: .previewNetworkError)
}

#Preview("Error - Timeout") {
    SearchView(viewModel: .previewTimeoutError)
}
