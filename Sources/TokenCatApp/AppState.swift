import Foundation
import Observation
import TokenCatCore

@Observable
@MainActor
final class AppState {
    var thresholds = CatThresholds()
    var refreshIntervalSeconds: Double = 300
    var notificationsEnabled = true
    var snapshot = StatusSnapshot(statuses: [], worstProvider: nil, catState: .sitting)
    var expandedProvider: ProviderID?

    private let adapters: [any ProviderAdapter]
    private var notificationStateMachine = NotificationStateMachine()

    init(adapters: [any ProviderAdapter] = [ClaudeAdapter(), CodexAdapter()]) {
        self.adapters = adapters
    }

    func refresh() async -> [(ProviderStatus, NotificationEvent)] {
        var statuses: [ProviderStatus] = []

        for adapter in adapters {
            let status = await adapter.refresh()
            statuses.append(status)
        }

        snapshot = StatusReducer.reduce(statuses: statuses, thresholds: thresholds)

        return statuses.compactMap { status in
            let catState = CatState.statusState(
                for: status.percentRemaining,
                providerState: status.state,
                thresholds: thresholds
            )

            guard let event = notificationStateMachine.record(provider: status.id, newCatState: catState) else {
                return nil
            }

            return (status, event)
        }
    }

    func toggleExpandedProvider(_ provider: ProviderID) {
        expandedProvider = expandedProvider == provider ? nil : provider
    }
}
