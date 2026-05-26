import TokenCatCore

func runCatStateTests() {
    catSitsAboveLowThreshold()
    catLiesDownAtLowThreshold()
    catSleepsAtSleepThreshold()
    blockedAlwaysSleeps()
    unknownDoesNotSleep()
}

private func catSitsAboveLowThreshold() {
    let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
    expectEqual(
        CatState.statusState(for: 31, providerState: .healthy, thresholds: thresholds),
        .sitting,
        "cat sits above low threshold"
    )
}

private func catLiesDownAtLowThreshold() {
    let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
    expectEqual(
        CatState.statusState(for: 30, providerState: .low, thresholds: thresholds),
        .lyingDown,
        "cat lies down at low threshold"
    )
    expectEqual(
        CatState.statusState(for: 6, providerState: .low, thresholds: thresholds),
        .lyingDown,
        "cat lies down between sleep and low thresholds"
    )
}

private func catSleepsAtSleepThreshold() {
    let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
    expectEqual(
        CatState.statusState(for: 5, providerState: .exhausted, thresholds: thresholds),
        .sleeping,
        "cat sleeps at sleep threshold"
    )
    expectEqual(
        CatState.statusState(for: 0, providerState: .exhausted, thresholds: thresholds),
        .sleeping,
        "cat sleeps at zero percent"
    )
}

private func blockedAlwaysSleeps() {
    let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
    expectEqual(
        CatState.statusState(for: 90, providerState: .blocked, thresholds: thresholds),
        .sleeping,
        "blocked provider sleeps regardless of percent"
    )
}

private func unknownDoesNotSleep() {
    let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
    expectEqual(
        CatState.statusState(for: nil, providerState: .unknown, thresholds: thresholds),
        .sitting,
        "unknown provider does not sleep"
    )
    expectEqual(
        CatState.statusState(for: nil, providerState: .error, thresholds: thresholds),
        .sitting,
        "error provider does not sleep"
    )
}
