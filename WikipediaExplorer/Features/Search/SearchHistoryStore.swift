import SwiftUI

protocol SearchHistoryStore: Sendable {
    func load() -> [String]
    func record(_ term: String)
    func remove(at offsets: IndexSet)
    func clear()
}

struct UserDefaultsSearchHistoryStore: SearchHistoryStore {
    private let key = "recentSearches"
    private let maxCount = 10
    private let defaults: UserDefaults = .standard

    func load() -> [String] {
        (defaults.array(forKey: key) as? [String]) ?? []
    }

    func record(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var items = load()
        items.removeAll { $0.compare(trimmed, options: .caseInsensitive) == .orderedSame }
        items.insert(trimmed, at: 0)
        if items.count > maxCount { items.removeLast(items.count - maxCount) }
        defaults.set(items, forKey: key)
    }

    func remove(at offsets: IndexSet) {
        var items = load()
        items.remove(atOffsets: offsets)
        defaults.set(items, forKey: key)
    }

    func clear() {
        defaults.set([], forKey: key)
    }
}
