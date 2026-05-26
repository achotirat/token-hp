import Testing
@testable import TokenCatCore

@Test func catSitsAboveLowThreshold() {
    let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
    #expect(CatState.statusState(for: 31, providerState: .healthy, thresholds: thresholds) == .sitting)
}

@Test func catLiesDownAtLowThreshold() {
    let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
    #expect(CatState.statusState(for: 30, providerState: .low, thresholds: thresholds) == .lyingDown)
    #expect(CatState.statusState(for: 6, providerState: .low, thresholds: thresholds) == .lyingDown)
}

@Test func catSleepsAtSleepThreshold() {
    let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
    #expect(CatState.statusState(for: 5, providerState: .exhausted, thresholds: thresholds) == .sleeping)
    #expect(CatState.statusState(for: 0, providerState: .exhausted, thresholds: thresholds) == .sleeping)
}

@Test func blockedAlwaysSleeps() {
    let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
    #expect(CatState.statusState(for: 90, providerState: .blocked, thresholds: thresholds) == .sleeping)
}

@Test func unknownDoesNotSleep() {
    let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
    #expect(CatState.statusState(for: nil, providerState: .unknown, thresholds: thresholds) == .sitting)
    #expect(CatState.statusState(for: nil, providerState: .error, thresholds: thresholds) == .sitting)
}
