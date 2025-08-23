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
                            }
                            .onDelete(perform: viewModel.removeRecent)
                            Button(role: .destructive) { viewModel.clearRecents() } label: {
                                Text("Clear Recent Searches")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    /// Search Results section
                    Section {
                        ForEach(viewModel.results) { article in
                            NavigationLink(value: article) {
                                ArticleRowView(article: article)
                            }
                        }
                    }
                }
                .overlay {
                    switch viewModel.mode {
                    case .idle:
                        ContentUnavailableView("Search Wikipedia", systemImage: "text.magnifyingglass",
                                               description: Text("Type to find articles"))
                    case .searching:
                        ProgressView("Searching…")
                    case .results:
                        EmptyView()
                    case .error(let msg):
                        ContentUnavailableView("Error", systemImage: "exclamationmark.triangle",
                                               description: Text(msg))
                    }
                }
            }
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search articles"
            )
            .searchSuggestions {
                if viewModel.query.isEmpty {
                    if viewModel.recentSearches.isEmpty {
                        Text("No recent searches")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.recentSearches, id: \.self) { term in
                            Button(term) { viewModel.selectRecent(term) }
                        }
                        Button(role: .destructive) { viewModel.clearRecents() } label: {
                            Text("Clear Recent Searches")
                        }
                    }
                }
            }
            .onChange(of: viewModel.query) { viewModel.onQueryChanged() }
            .navigationTitle("Search")
            .navigationDestination(for: Article.self) { article in
                if let url = article.fullURL {
                    ArticleDetailView(url: url, title: article.title)
                } else {
                    ContentUnavailableView("Unavailable", systemImage: "link.slash",
                                           description: Text("This article does not have a URL."))
                }
            }
        }
    }
}
