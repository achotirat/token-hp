import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Toggle("Enable notifications", isOn: notificationsEnabled)

            Section("Providers") {
                Toggle("Claude", isOn: claudeEnabled)
                Toggle("Codex", isOn: codexEnabled)
            }

            LabeledContent("Refresh interval") {
                Stepper(
                    "\(Int(appState.refreshIntervalSeconds)) seconds",
                    value: refreshIntervalSeconds,
                    in: 60...1800,
                    step: 60
                )
            }

            LabeledContent("Low threshold") {
                Stepper(
                    "\(appState.thresholds.lowPercent)%",
                    value: lowThreshold,
                    in: (appState.thresholds.sleepPercent + 1)...95
                )
            }

            LabeledContent("Sleep threshold") {
                Stepper(
                    "\(appState.thresholds.sleepPercent)%",
                    value: sleepThreshold,
                    in: 0...(appState.thresholds.lowPercent - 1)
                )
            }
        }
        .padding()
        .frame(width: 360)
    }

    private var notificationsEnabled: Binding<Bool> {
        Binding(
            get: {
                appState.notificationsEnabled
            },
            set: { newValue in
                appState.setNotificationsEnabled(newValue)
            }
        )
    }

    private var refreshIntervalSeconds: Binding<Double> {
        Binding(
            get: {
                appState.refreshIntervalSeconds
            },
            set: { newValue in
                appState.setRefreshIntervalSeconds(newValue)
            }
        )
    }

    private var claudeEnabled: Binding<Bool> {
        Binding(
            get: {
                appState.claudeEnabled
            },
            set: { newValue in
                appState.setProvider(.claude, enabled: newValue)
            }
        )
    }

    private var codexEnabled: Binding<Bool> {
        Binding(
            get: {
                appState.codexEnabled
            },
            set: { newValue in
                appState.setProvider(.codex, enabled: newValue)
            }
        )
    }

    private var lowThreshold: Binding<Int> {
        Binding(
            get: {
                appState.thresholds.lowPercent
            },
            set: { newValue in
                appState.setLowThreshold(newValue)
            }
        )
    }

    private var sleepThreshold: Binding<Int> {
        Binding(
            get: {
                appState.thresholds.sleepPercent
            },
            set: { newValue in
                appState.setSleepThreshold(newValue)
            }
        )
    }
}
