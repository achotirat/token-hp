import SwiftUI
import TokenCatCore

struct ProviderPanelView: View {
    @Bindable var appState: AppState
    let refreshAction: () -> Void
    let openSettingsAction: () -> Void
    let quitAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if appState.snapshot.statuses.isEmpty {
                Text("Refreshing providers...")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ForEach(appState.snapshot.statuses, id: \.id) { status in
                    let isExpanded = appState.expandedProvider == status.id

                    Button {
                        appState.toggleExpandedProvider(status.id)
                    } label: {
                        ProviderCardView(
                            status: status,
                            isExpanded: isExpanded
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
                    .accessibilityHint(isExpanded ? "Hide provider details" : "Show provider details")
                }
            }

            Divider()

            HStack(spacing: 8) {
                Button("Refresh", action: refreshAction)
                Button("Settings", action: openSettingsAction)
                Spacer()
                Button("Quit", action: quitAction)
            }
        }
        .padding(14)
        .frame(width: 320)
    }

    private var header: some View {
        HStack(spacing: 10) {
            MenuBarIconView(state: appState.snapshot.catState)
                .frame(width: 36, height: 24)

            Text("Token Cat")
                .font(.headline)

            Spacer()
        }
    }
}

private struct ProviderCardView: View {
    let status: ProviderStatus
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(status.displayName)
                    .font(.headline)

                Spacer()

                Text(percentText)
                    .font(.system(size: status.percentRemaining == nil ? 18 : 26, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            ProgressView(value: Double(status.percentRemaining ?? 0), total: 100)
                .tint(progressTint)

            Text(summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !isExpanded, let errorMessage = status.errorMessage {
                Text("Error: \(errorMessage)")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    detailRow("Source", status.sourceDescription)
                    detailRow("Confidence", status.confidence.rawValue.capitalized)
                    detailRow("Last Refresh", status.lastRefresh.formatted(date: .omitted, time: .shortened))
                    if let errorMessage = status.errorMessage {
                        detailRow("Error", errorMessage)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private var percentText: String {
        guard let percent = status.percentRemaining else {
            return "Unknown"
        }

        return "\(percent)%"
    }

    private var progressTint: Color {
        switch status.state {
        case .healthy:
            return .green
        case .low:
            return .orange
        case .exhausted, .blocked, .error:
            return .red
        case .unknown:
            return .secondary
        }
    }

    private var summaryText: String {
        let reset = status.resetDescription ?? "reset unknown"
        return "\(reset) - \(status.state.rawValue.capitalized)"
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .fontWeight(.semibold)
            Text(value)
                .multilineTextAlignment(.leading)
        }
    }
}
