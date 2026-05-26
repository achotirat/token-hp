import AppKit
import SwiftUI
import TokenCatCore

@main
@MainActor
final class TokenCatApplication: NSObject, NSApplicationDelegate {
    private static var retainedDelegate: TokenCatApplication?

    private let appState = AppState()
    private let notificationService = NotificationService()

    private var hasRequestedNotificationAuthorization = false
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?
    private var refreshTask: Task<Void, Never>?

    static func main() {
        let delegate = TokenCatApplication()
        retainedDelegate = delegate

        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        startRefreshLoop()
        refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTask?.cancel()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureStatusButton(item.button)
        statusItem = item
    }

    private func configureStatusButton(_ button: NSStatusBarButton?) {
        guard let button else {
            return
        }

        button.title = statusTitle(for: appState.snapshot.catState)
        button.target = self
        button.action = #selector(togglePopover)
        button.toolTip = "Token Cat"
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 360)
        popover.contentViewController = NSHostingController(
            rootView: ProviderPanelView(
                appState: appState,
                refreshAction: { [weak self] in
                    self?.refresh()
                },
                openSettingsAction: { [weak self] in
                    self?.openSettings()
                },
                quitAction: {
                    NSApplication.shared.terminate(nil)
                }
            )
        )
        self.popover = popover
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func openSettings() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Token Cat Settings"
        window.contentView = NSHostingView(rootView: SettingsView(appState: appState))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    private func startRefreshLoop() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else {
                    return
                }

                let interval = appState.refreshIntervalSeconds
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

                guard !Task.isCancelled else {
                    return
                }

                refresh()
            }
        }
    }

    private func refresh() {
        Task { @MainActor in
            let events = await appState.refresh()
            configureStatusButton(statusItem?.button)

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

    private func statusTitle(for state: CatState) -> String {
        switch state {
        case .sitting:
            return "Token Cat"
        case .lyingDown:
            return "Cat low"
        case .sleeping:
            return "Cat Zz"
        }
    }
}
