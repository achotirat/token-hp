public struct StatusSnapshot: Equatable, Sendable {
    public var statuses: [ProviderStatus]
    public var worstProvider: ProviderStatus?
    public var catState: CatState

    public init(statuses: [ProviderStatus], worstProvider: ProviderStatus?, catState: CatState) {
        self.statuses = statuses
        self.worstProvider = worstProvider
        self.catState = catState
    }
}

public enum StatusReducer {
    public static func reduce(statuses: [ProviderStatus], thresholds: CatThresholds) -> StatusSnapshot {
        let worst = statuses.max { lhs, rhs in
            severity(lhs, thresholds: thresholds) < severity(rhs, thresholds: thresholds)
        }

        let catState = worst.map {
            CatState.statusState(
                for: $0.percentRemaining,
                providerState: $0.state,
                thresholds: thresholds
            )
        } ?? .sitting

        return StatusSnapshot(statuses: statuses, worstProvider: worst, catState: catState)
    }

    private static func severity(_ status: ProviderStatus, thresholds: CatThresholds) -> Int {
        switch CatState.statusState(
            for: status.percentRemaining,
            providerState: status.state,
            thresholds: thresholds
        ) {
        case .sleeping:
            return 300 + inversePercent(status.percentRemaining)
        case .lyingDown:
            return 200 + inversePercent(status.percentRemaining)
        case .sitting:
            if status.state == .unknown || status.state == .error {
                return 0
            }
            return 100 + inversePercent(status.percentRemaining)
        }
    }

    private static func inversePercent(_ percent: Int?) -> Int {
        100 - max(0, min(percent ?? 100, 100))
    }
}
