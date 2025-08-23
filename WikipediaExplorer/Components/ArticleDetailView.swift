import SwiftUI

#if canImport(WebKit)
import WebKit
#endif

struct ArticleDetailView: View {
    let url: URL
    let title: String?

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                WebView(url: url)
            } else {
                LegacyWebView(url: url)
            }
        }
        .navigationTitle(title ?? "Article")
        .navigationBarTitleDisplayMode(.inline)
    }
}


