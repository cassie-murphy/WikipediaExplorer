public enum Loadable<Value>: Sendable where Value: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(WikipediaError)
}

extension Loadable: Equatable where Value: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.failed(let leftError), .failed(let rightError)):
            return leftError == rightError
        case (.loaded(let leftValue), .loaded(let rightValue)):
            return leftValue == rightValue
        default:
            return false
        }
    }
}
