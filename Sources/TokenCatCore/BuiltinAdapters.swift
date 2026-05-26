import Foundation

public struct ClaudeAdapter: ProviderAdapter {
    public let id: ProviderID = .claude
    public let displayName = "Claude"

    private let telemetryURL: URL
    private let limitConfigURL: URL
    private let now: @Sendable () -> Date

    public init(
        telemetryURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/token-cat/claude-telemetry.jsonl"),
        limitConfigURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/token-cat/claude-limits.json"),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.telemetryURL = telemetryURL
        self.limitConfigURL = limitConfigURL
        self.now = now
    }

    public func refresh() async -> ProviderStatus {
        let events = telemetryEvents()
        guard !events.isEmpty else {
            return ProviderStatus(
                id: id,
                displayName: displayName,
                percentRemaining: nil,
                resetDescription: nil,
                state: .unknown,
                sourceDescription: "No local Claude Code OpenTelemetry stream found.",
                confidence: .unknown,
                lastRefresh: now()
            )
        }

        guard let limit = limitConfig() else {
            let observedTokens = events.reduce(0) { $0 + $1.tokens }
            return ProviderStatus(
                id: id,
                displayName: displayName,
                percentRemaining: nil,
                resetDescription: "\(formatted(observedTokens)) tokens observed",
                state: .unknown,
                sourceDescription: "Local Claude Code OpenTelemetry stream found, but no limit config is set.",
                confidence: .low,
                lastRefresh: now()
            )
        }

        let windowStart = now().addingTimeInterval(-Double(limit.windowMinutes * 60))
        let windowEvents = events.filter { $0.timestamp >= windowStart && $0.timestamp <= now() }
        guard !windowEvents.isEmpty else {
            return ProviderStatus(
                id: id,
                displayName: displayName,
                percentRemaining: 100,
                resetDescription: "no telemetry in current window",
                state: .healthy,
                sourceDescription: "Local Claude Code OpenTelemetry stream",
                confidence: .medium,
                lastRefresh: now()
            )
        }

        let usedTokens = windowEvents.reduce(0) { $0 + $1.tokens }
        let usedPercent = (Double(usedTokens) / Double(limit.tokenBudget)) * 100
        let remaining = max(0, min(100, Int((100 - usedPercent).rounded())))
        let firstEventDate = windowEvents.map(\.timestamp).min() ?? now()
        let resetsAt = firstEventDate.addingTimeInterval(Double(limit.windowMinutes * 60))

        return ProviderStatus(
            id: id,
            displayName: displayName,
            percentRemaining: remaining,
            resetDescription: "window resets in \(durationText(until: resetsAt, now: now()))",
            state: providerState(remainingPercent: remaining),
            sourceDescription: "Local Claude Code OpenTelemetry stream",
            confidence: .medium,
            lastRefresh: now()
        )
    }

    private func telemetryEvents() -> [ClaudeTelemetryEvent] {
        guard let contents = try? String(contentsOf: telemetryURL, encoding: .utf8) else {
            return []
        }

        return contents.split(whereSeparator: \.isNewline).compactMap { line in
            parseTelemetryEvent(String(line))
        }
    }

    private func parseTelemetryEvent(_ line: String) -> ClaudeTelemetryEvent? {
        guard let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let timestampText = stringValue(object["timestamp"]),
              let timestamp = parseISO8601Date(timestampText),
              eventName(from: object) == "claude_code.api_request" else {
            return nil
        }

        let tokens = intValue(object["input_tokens"])
            + intValue(object["output_tokens"])
            + intValue(object["cache_read_tokens"])
            + intValue(object["cache_creation_tokens"])

        guard tokens > 0 else {
            return nil
        }

        return ClaudeTelemetryEvent(timestamp: timestamp, tokens: tokens)
    }

    private func eventName(from object: [String: Any]) -> String? {
        if let event = stringValue(object["event"]) {
            return event
        }

        if let name = stringValue(object["event.name"]) {
            return name
        }

        if let attributes = object["attributes"] as? [String: Any] {
            return stringValue(attributes["event.name"]) ?? stringValue(attributes["event"])
        }

        return nil
    }

    private func limitConfig() -> ClaudeLimitConfig? {
        guard let data = try? Data(contentsOf: limitConfigURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokenBudget = intValueIfPresent(object["token_budget"]),
              let windowMinutes = intValueIfPresent(object["window_minutes"]),
              tokenBudget > 0,
              windowMinutes > 0 else {
            return nil
        }

        return ClaudeLimitConfig(tokenBudget: tokenBudget, windowMinutes: windowMinutes)
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
        return "resets in \(durationText(until: resetsAt, now: now()))"
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

private struct ClaudeTelemetryEvent {
    var timestamp: Date
    var tokens: Int
}

private struct ClaudeLimitConfig {
    var tokenBudget: Int
    var windowMinutes: Int
}

private struct CodexRateLimitEvent {
    var timestamp: Date
    var usedPercent: Double
    var resetsAt: Date
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

private func providerState(remainingPercent: Int) -> ProviderState {
    if remainingPercent <= 5 {
        return .exhausted
    }

    if remainingPercent <= 30 {
        return .low
    }

    return .healthy
}

private func durationText(until date: Date, now: Date) -> String {
    let seconds = max(0, Int(date.timeIntervalSince(now)))
    let hours = seconds / 3_600
    let minutes = (seconds % 3_600) / 60

    if hours > 0 {
        return "\(hours)h \(minutes)m"
    }

    return "\(minutes)m"
}

private func intValue(_ value: Any?) -> Int {
    intValueIfPresent(value) ?? 0
}

private func intValueIfPresent(_ value: Any?) -> Int? {
    switch value {
    case let value as Int:
        return value
    case let value as Double:
        return Int(value)
    case let value as NSNumber:
        return value.intValue
    default:
        return nil
    }
}

private func stringValue(_ value: Any?) -> String? {
    value as? String
}

private func formatted(_ number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
}
