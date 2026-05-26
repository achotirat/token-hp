import Foundation
import TokenCatCore
import UserNotifications

struct NotificationService {
    func requestAuthorization() async {
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            // Authorization failure should not stop quota display.
        }
    }

    func send(provider: ProviderStatus, event: NotificationEvent) async {
        let content = UNMutableNotificationContent()
        content.title = title(provider: provider, event: event)
        content.body = body(provider: provider, event: event)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(provider.id.rawValue)-\(event)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Notification delivery failure should not stop quota display.
        }
    }

    private func title(provider: ProviderStatus, event: NotificationEvent) -> String {
        switch event {
        case .low:
            return "\(provider.displayName) is running low"
        case .exhausted:
            return "\(provider.displayName) is almost out"
        }
    }

    private func body(provider: ProviderStatus, event: NotificationEvent) -> String {
        let percent = provider.percentRemaining.map { "\($0)%" } ?? "unknown remaining"
        let reset = provider.resetDescription ?? "reset time unknown"

        switch event {
        case .low:
            return "\(provider.displayName) has \(percent). \(reset)."
        case .exhausted:
            return "\(provider.displayName) has reached the sleep threshold. \(reset)."
        }
    }
}
