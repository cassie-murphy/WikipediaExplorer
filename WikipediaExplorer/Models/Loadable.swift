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
        case (.failed(let leftValue), .failed(let rightValue)):
            return leftValue == rightValue
        case (.loaded(let leftValue), .loaded(let rightValue)):
            return leftValue == rightValue
        default:
            return false
        }
    }
}
