import Foundation

public struct ClaudeAdapter: ProviderAdapter {
    public let id: ProviderID = .claude
    public let displayName = "Claude"

    public init() {}

    public func refresh() async -> ProviderStatus {
        return ProviderStatus(
            id: id,
            displayName: displayName,
            percentRemaining: nil,
            resetDescription: nil,
            state: .unknown,
            sourceDescription: "Local Claude usage detection is not configured yet.",
            confidence: .unknown,
            lastRefresh: Date()
        )
    }
}

public struct CodexAdapter: ProviderAdapter {
    public let id: ProviderID = .codex
    public let displayName = "Codex"

    private let sessionsRoot: URL
    private let now: @Sendable () -> Date

    public init(
        sessionsRoot: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/sessions", isDirectory: true),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.sessionsRoot = sessionsRoot
        self.now = now
    }

    public func refresh() async -> ProviderStatus {
        guard let event = latestRateLimitEvent() else {
            return ProviderStatus(
                id: id,
                displayName: displayName,
                percentRemaining: nil,
                resetDescription: nil,
                state: .unknown,
                sourceDescription: "No local Codex rate limit events found in ~/.codex/sessions.",
                confidence: .unknown,
                lastRefresh: now()
            )
        }

        let remaining = max(0, min(100, Int((100 - event.usedPercent).rounded())))

        return ProviderStatus(
            id: id,
            displayName: displayName,
            percentRemaining: remaining,
            resetDescription: resetDescription(resetsAt: event.resetsAt),
            state: providerState(remainingPercent: remaining),
            sourceDescription: "Latest local Codex session rate limit event",
            confidence: .high,
            lastRefresh: now()
        )
    }

    private func latestRateLimitEvent() -> CodexRateLimitEvent? {
        guard let enumerator = FileManager.default.enumerator(
            at: sessionsRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var latestEvent: CodexRateLimitEvent?

        for case let fileURL as URL in enumerator where fileURL.pathExtension == "jsonl" {
            guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }

            for line in contents.split(whereSeparator: \.isNewline) {
                guard let event = parseRateLimitEvent(String(line)) else {
                    continue
                }

                if latestEvent == nil || event.timestamp > latestEvent!.timestamp {
                    latestEvent = event
                }
            }
        }

        return latestEvent
    }

    private func parseRateLimitEvent(_ line: String) -> CodexRateLimitEvent? {
        guard let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let timestampText = object["timestamp"] as? String,
              let timestamp = parseISO8601Date(timestampText),
              let payload = object["payload"] as? [String: Any],
              payload["type"] as? String == "token_count",
              let rateLimits = payload["rate_limits"] as? [String: Any],
              let primary = rateLimits["primary"] as? [String: Any],
              let usedPercent = doubleValue(primary["used_percent"]),
              let resetsAt = doubleValue(primary["resets_at"]) else {
            return nil
        }

        return CodexRateLimitEvent(
            timestamp: timestamp,
            usedPercent: usedPercent,
            resetsAt: Date(timeIntervalSince1970: resetsAt)
        )
    }

    private func resetDescription(resetsAt: Date) -> String {
        let seconds = max(0, Int(resetsAt.timeIntervalSince(now())))
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60

        if hours > 0 {
            return "resets in \(hours)h \(minutes)m"
        }

        return "resets in \(minutes)m"
    }

    private func providerState(remainingPercent: Int) -> ProviderState {
        if remainingPercent <= 5 {
            return .exhausted
        }

        if remainingPercent <= 30 {
            return .low
        }

        return .healthy
    }

    private func parseISO8601Date(_ text: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: text) {
            return date
        }

        let wholeSecondFormatter = ISO8601DateFormatter()
        wholeSecondFormatter.formatOptions = [.withInternetDateTime]
        return wholeSecondFormatter.date(from: text)
    }

    private func doubleValue(_ value: Any?) -> Double? {
        switch value {
        case let value as Double:
            return value
        case let value as Int:
            return Double(value)
        case let value as NSNumber:
            return value.doubleValue
        default:
            return nil
        }
    }
}

private struct CodexRateLimitEvent {
    var timestamp: Date
    var usedPercent: Double
    var resetsAt: Date
}
