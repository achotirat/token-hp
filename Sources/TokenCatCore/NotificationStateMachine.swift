public enum NotificationEvent: Equatable, Sendable {
    case low
    case exhausted
}

public struct NotificationStateMachine: Sendable {
    private var previousStates: [ProviderID: CatState]

    public init(previousStates: [ProviderID: CatState] = [:]) {
        self.previousStates = previousStates
    }

    public mutating func record(provider: ProviderID, newCatState: CatState) -> NotificationEvent? {
        let previous = previousStates[provider] ?? .sitting
        previousStates[provider] = newCatState

        switch (previous, newCatState) {
        case (.sitting, .lyingDown):
            return .low
        case (.sitting, .sleeping), (.lyingDown, .sleeping):
            return .exhausted
        default:
            return nil
        }
    }
}
