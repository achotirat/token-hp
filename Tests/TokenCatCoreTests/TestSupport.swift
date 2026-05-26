func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    if actual != expected {
        fatalError("Expectation failed: \(message). Expected \(expected), got \(actual)")
    }
}

func expectNil<T>(_ actual: T?, _ message: String) {
    if actual != nil {
        fatalError("Expectation failed: \(message). Expected nil, got \(String(describing: actual))")
    }
}
