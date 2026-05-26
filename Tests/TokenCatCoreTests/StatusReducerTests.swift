import Foundation
import TokenCatCore

private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

private func status(
    id: ProviderID,
    percent: Int?,
    state: ProviderState
) -> ProviderStatus {
    ProviderStatus(
        id: id,
        displayName: id.rawValue.capitalized,
        percentRemaining: percent,
        resetDescription: "resets soon",
        state: state,
        sourceDescription: "test",
        confidence: .high,
        lastRefresh: fixedDate
    )
}

func runStatusReducerTests() {
    worstProviderChoosesSleepingStateOverLowPercentHealthyProvider()
    worstProviderChoosesLowestKnownPercent()
    unknownDoesNotBeatKnownHealthyProvider()
}

private func worstProviderChoosesSleepingStateOverLowPercentHealthyProvider() {
    let statuses = [
        status(id: .claude, percent: 90, state: .healthy),
        status(id: .codex, percent: 2, state: .exhausted)
    ]

    let snapshot = StatusReducer.reduce(statuses: statuses, thresholds: CatThresholds())

    expectEqual(snapshot.worstProvider?.id, .codex)
    expectEqual(snapshot.catState, .sleeping)
}

private func worstProviderChoosesLowestKnownPercent() {
    let statuses = [
        status(id: .claude, percent: 72, state: .healthy),
        status(id: .codex, percent: 18, state: .low)
    ]

    let snapshot = StatusReducer.reduce(statuses: statuses, thresholds: CatThresholds())

    expectEqual(snapshot.worstProvider?.id, .codex)
    expectEqual(snapshot.catState, .lyingDown)
}

private func unknownDoesNotBeatKnownHealthyProvider() {
    let statuses = [
        status(id: .claude, percent: nil, state: .unknown),
        status(id: .codex, percent: 80, state: .healthy)
    ]

    let snapshot = StatusReducer.reduce(statuses: statuses, thresholds: CatThresholds())

    expectEqual(snapshot.worstProvider?.id, .codex)
    expectEqual(snapshot.catState, .sitting)
}
