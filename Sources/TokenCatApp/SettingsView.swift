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
                    value: $appState.thresholds.lowPercent,
                    in: 6...95
                )
            }

            LabeledContent("Sleep threshold") {
                Stepper(
                    "\(appState.thresholds.sleepPercent)%",
                    value: $appState.thresholds.sleepPercent,
                    in: 0...30
                )
            }
        }
        .padding()
        .frame(width: 360)
    }
}
