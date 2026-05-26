import AppKit
import SwiftUI

@main
struct TokenCatApp: App {
    @State private var appState = AppState()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            ProviderPanelView(
                appState: appState,
                refreshAction: {
                    Task { _ = await appState.refresh() }
                },
                openSettingsAction: {
                    openSettings()
                },
                quitAction: {
                    NSApplication.shared.terminate(nil)
                }
            )
            .task {
                _ = await appState.refresh()
            }
        } label: {
            MenuBarIconView(state: appState.snapshot.catState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(appState: appState)
        }
    }
}
