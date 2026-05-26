import AppKit
import SwiftUI

@main
struct TokenCatApp: App {
    @State private var appState = AppState()
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
            .task {
                await notificationService.requestAuthorization()
                refresh()
            }
        } label: {
            MenuBarIconView(state: appState.snapshot.catState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(appState: appState)
        }
    }

    private func refresh() {
        Task {
            let events = await appState.refresh()
            guard appState.notificationsEnabled else {
                return
            }

            for (provider, event) in events {
                await notificationService.send(provider: provider, event: event)
            }
        }
    }
}
