public enum CatState: String, Equatable, Sendable {
    case sitting
    case lyingDown
    case sleeping

    public static func statusState(
        for percentRemaining: Int?,
        providerState: ProviderState,
        thresholds: CatThresholds
    ) -> CatState {
        switch providerState {
        case .blocked, .exhausted:
            return .sleeping
        case .unknown, .error:
            return .sitting
        case .healthy, .low:
            guard let percentRemaining else {
                return .sitting
            }

            if percentRemaining <= thresholds.sleepPercent {
                return .sleeping
            }

            if percentRemaining <= thresholds.lowPercent {
                return .lyingDown
            }

            return .sitting
        }
    }
}

public struct CatThresholds: Equatable, Sendable {
    public var lowPercent: Int
    public var sleepPercent: Int

    public init(lowPercent: Int = 30, sleepPercent: Int = 5) {
        self.lowPercent = lowPercent
        self.sleepPercent = sleepPercent
    }
}
