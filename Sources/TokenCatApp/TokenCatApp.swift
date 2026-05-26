import AppKit
import SwiftUI

@main
struct TokenCatApp: App {
    @State private var appState = AppState()
    @State private var hasRequestedNotificationAuthorization = false
    private let notificationService = NotificationService()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            ProviderPanelView(
                appState: appState,
                refreshAction: {
                    refresh()
                },
                openSettingsAction: {
                    openSettings()
                },
                quitAction: {
                    NSApplication.shared.terminate(nil)
                }
            )
        } label: {
            MenuBarIconView(state: appState.snapshot.catState)
                .task {
                    await refreshLoop()
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(appState: appState)
        }
    }

    @MainActor
    private func refresh() {
        Task { @MainActor in
            let events = await appState.refresh()
            guard appState.notificationsEnabled else {
                return
            }

            guard !events.isEmpty else {
                return
            }

            if !hasRequestedNotificationAuthorization {
                await notificationService.requestAuthorization()
                hasRequestedNotificationAuthorization = true
            }

            for (provider, event) in events {
                await notificationService.send(provider: provider, event: event)
            }
        }
    }

    @MainActor
    private func refreshLoop() async {
        refresh()

        while !Task.isCancelled {
            let interval = appState.refreshIntervalSeconds
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

            guard !Task.isCancelled else {
                return
            }

            refresh()
        }
    }
}
