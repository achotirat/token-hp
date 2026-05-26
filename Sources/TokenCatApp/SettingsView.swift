import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Toggle("Enable notifications", isOn: $appState.notificationsEnabled)

            LabeledContent("Refresh interval") {
                Stepper(
                    "\(Int(appState.refreshIntervalSeconds)) seconds",
                    value: $appState.refreshIntervalSeconds,
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

    private var lowThreshold: Binding<Int> {
        Binding(
            get: {
                appState.thresholds.lowPercent
            },
            set: { newValue in
                appState.thresholds.lowPercent = max(newValue, appState.thresholds.sleepPercent + 1)
            }
        )
    }

    private var sleepThreshold: Binding<Int> {
        Binding(
            get: {
                appState.thresholds.sleepPercent
            },
            set: { newValue in
                appState.thresholds.sleepPercent = min(newValue, appState.thresholds.lowPercent - 1)
            }
        )
    }
}
