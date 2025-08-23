public enum Loadable<Value>: Sendable where Value: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}

extension Loadable: Equatable where Value: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        case (.loaded(let a), .loaded(let b)):
            return a == b
        default:
            return false
        }
    }
}
