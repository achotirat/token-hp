import Foundation
import Observation
import TokenCatCore

@Observable
@MainActor
final class AppState {
    var thresholds = CatThresholds()
    var refreshIntervalSeconds: Double = 300
    var notificationsEnabled = true
    var claudeEnabled = true
    var codexEnabled = true
    var snapshot = StatusSnapshot(statuses: [], worstProvider: nil, catState: .sitting)
    var expandedProvider: ProviderID?

    private let adapters: [any ProviderAdapter]
    private let settingsStore: SettingsStore
    private var notificationStateMachine = NotificationStateMachine()
    private var refreshGeneration = 0

    var enabledProviderIDs: Set<ProviderID> {
        var ids = Set<ProviderID>()
        if claudeEnabled {
            ids.insert(.claude)
        }
        if codexEnabled {
            ids.insert(.codex)
        }
        return ids
    }

    init(
        adapters: [any ProviderAdapter] = [ClaudeAdapter(), CodexAdapter()],
        settingsStore: SettingsStore = SettingsStore()
    ) {
        self.adapters = adapters
        self.settingsStore = settingsStore

        let settings = settingsStore.load()
        thresholds = settings.thresholds
        refreshIntervalSeconds = settings.refreshIntervalSeconds
        notificationsEnabled = settings.notificationsEnabled
        claudeEnabled = settings.claudeEnabled
        codexEnabled = settings.codexEnabled
    }

    func refresh() async -> [(ProviderStatus, NotificationEvent)] {
        refreshGeneration += 1
        let generation = refreshGeneration

        let enabledProviderIDs = enabledProviderIDs
        guard !enabledProviderIDs.isEmpty else {
            snapshot = StatusReducer.reduce(statuses: [], thresholds: thresholds)
            return []
        }

        var statuses: [ProviderStatus] = []

        for adapter in adapters where enabledProviderIDs.contains(adapter.id) {
            let status = await adapter.refresh()
            statuses.append(status)
        }

        guard generation == refreshGeneration else {
            return []
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

    func setNotificationsEnabled(_ isEnabled: Bool) {
        notificationsEnabled = isEnabled
        settingsStore.saveNotificationsEnabled(isEnabled)
    }

    func setRefreshIntervalSeconds(_ seconds: Double) {
        refreshIntervalSeconds = seconds
        settingsStore.saveRefreshIntervalSeconds(seconds)
    }

    func setLowThreshold(_ lowPercent: Int) {
        thresholds.lowPercent = max(lowPercent, thresholds.sleepPercent + 1)
        settingsStore.saveThresholds(thresholds)
        settingsDidChange()
    }

    func setSleepThreshold(_ sleepPercent: Int) {
        thresholds.sleepPercent = min(sleepPercent, thresholds.lowPercent - 1)
        settingsStore.saveThresholds(thresholds)
        settingsDidChange()
    }

    func setProvider(_ provider: ProviderID, enabled isEnabled: Bool) {
        switch provider {
        case .claude:
            claudeEnabled = isEnabled
            settingsStore.saveClaudeEnabled(isEnabled)
        case .codex:
            codexEnabled = isEnabled
            settingsStore.saveCodexEnabled(isEnabled)
        }

        refreshGeneration += 1
        settingsDidChange()
    }

    func settingsDidChange() {
        let enabledProviderIDs = enabledProviderIDs
        let statuses = snapshot.statuses.filter { enabledProviderIDs.contains($0.id) }

        if let expandedProvider, !enabledProviderIDs.contains(expandedProvider) {
            self.expandedProvider = nil
        }

        snapshot = StatusReducer.reduce(statuses: statuses, thresholds: thresholds)
    }
}

struct SettingsStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> TokenCatSettings {
        let defaultThresholds = CatThresholds()
        let storedLowPercent = defaults.object(forKey: Key.lowPercent) as? Int ?? defaultThresholds.lowPercent
        let storedSleepPercent = defaults.object(forKey: Key.sleepPercent) as? Int ?? defaultThresholds.sleepPercent
        let sleepPercent = max(0, min(storedSleepPercent, 94))
        let lowPercent = max(sleepPercent + 1, min(storedLowPercent, 95))
        let thresholds = CatThresholds(
            lowPercent: lowPercent,
            sleepPercent: sleepPercent
        )

        return TokenCatSettings(
            notificationsEnabled: defaults.object(forKey: Key.notificationsEnabled) as? Bool ?? true,
            refreshIntervalSeconds: defaults.object(forKey: Key.refreshIntervalSeconds) as? Double ?? 300,
            thresholds: thresholds,
            claudeEnabled: defaults.object(forKey: Key.claudeEnabled) as? Bool ?? true,
            codexEnabled: defaults.object(forKey: Key.codexEnabled) as? Bool ?? true
        )
    }

    func saveNotificationsEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: Key.notificationsEnabled)
    }

    func saveRefreshIntervalSeconds(_ seconds: Double) {
        defaults.set(seconds, forKey: Key.refreshIntervalSeconds)
    }

    func saveThresholds(_ thresholds: CatThresholds) {
        defaults.set(thresholds.lowPercent, forKey: Key.lowPercent)
        defaults.set(thresholds.sleepPercent, forKey: Key.sleepPercent)
    }

    func saveClaudeEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: Key.claudeEnabled)
    }

    func saveCodexEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: Key.codexEnabled)
    }

    private enum Key {
        static let notificationsEnabled = "TokenCat.notificationsEnabled"
        static let refreshIntervalSeconds = "TokenCat.refreshIntervalSeconds"
        static let lowPercent = "TokenCat.thresholds.lowPercent"
        static let sleepPercent = "TokenCat.thresholds.sleepPercent"
        static let claudeEnabled = "TokenCat.providers.claude.enabled"
        static let codexEnabled = "TokenCat.providers.codex.enabled"
    }
}

struct TokenCatSettings {
    var notificationsEnabled: Bool
    var refreshIntervalSeconds: Double
    var thresholds: CatThresholds
    var claudeEnabled: Bool
    var codexEnabled: Bool
}
