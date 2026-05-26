import Foundation
import TokenCatCore

func runBuiltinAdaptersTests() async {
    await claudeAdapterReportsHonestUnknownWhenDetectionIsUnavailable()
    await claudeAdapterReadsLocalTelemetryWhenLimitIsConfigured()
    await claudeAdapterReportsUsageWithoutPercentWhenLimitIsMissing()
    await codexAdapterReportsHonestUnknownWhenDetectionIsUnavailable()
    await codexAdapterReadsLatestLocalRateLimitEvent()
    await codexAdapterReportsUnknownWhenLatestRateLimitEventIsExpired()
}

private func claudeAdapterReportsHonestUnknownWhenDetectionIsUnavailable() async {
    let adapter = ClaudeAdapter(telemetryURL: temporaryDirectory().appendingPathComponent("claude-telemetry.jsonl"))
    let status = await adapter.refresh()

    expectEqual(status.id, .claude)
    expectEqual(status.displayName, "Claude")
    expectNil(status.percentRemaining)
    expectEqual(status.state, .unknown)
    expectEqual(status.confidence, .unknown)
    expectNil(status.errorMessage)
}

private func claudeAdapterReadsLocalTelemetryWhenLimitIsConfigured() async {
    let directory = temporaryDirectory()
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let telemetryURL = directory.appendingPathComponent("claude-telemetry.jsonl")
    let configURL = directory.appendingPathComponent("claude-limits.json")

    try! """
    {"timestamp":"2026-05-26T08:30:00Z","event":"claude_code.api_request","input_tokens":1200,"output_tokens":800,"cache_read_tokens":10000,"cache_creation_tokens":2000}
    {"timestamp":"2026-05-26T10:00:00Z","event":"claude_code.api_request","input_tokens":3000,"output_tokens":2000,"cache_read_tokens":40000,"cache_creation_tokens":5000}
    """.write(to: telemetryURL, atomically: true, encoding: .utf8)

    try! """
    {"token_budget":100000,"window_minutes":300}
    """.write(to: configURL, atomically: true, encoding: .utf8)

    let adapter = ClaudeAdapter(
        telemetryURL: telemetryURL,
        limitConfigURL: configURL,
        now: { Date(timeIntervalSince1970: 1779793200) }
    )
    let status = await adapter.refresh()

    expectEqual(status.id, .claude)
    expectEqual(status.displayName, "Claude")
    expectEqual(status.percentRemaining, 36)
    expectEqual(status.resetDescription, "window resets in 2h 30m")
    expectEqual(status.state, .healthy)
    expectEqual(status.confidence, .medium)
    expectEqual(status.sourceDescription, "Local Claude Code OpenTelemetry stream")
    expectNil(status.errorMessage)
}

private func claudeAdapterReportsUsageWithoutPercentWhenLimitIsMissing() async {
    let directory = temporaryDirectory()
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let telemetryURL = directory.appendingPathComponent("claude-telemetry.jsonl")

    try! """
    {"timestamp":"2026-05-26T10:00:00Z","event":"claude_code.api_request","input_tokens":1000,"output_tokens":500}
    """.write(to: telemetryURL, atomically: true, encoding: .utf8)

    let adapter = ClaudeAdapter(
        telemetryURL: telemetryURL,
        limitConfigURL: directory.appendingPathComponent("missing.json"),
        now: { Date(timeIntervalSince1970: 1779793200) }
    )
    let status = await adapter.refresh()

    expectNil(status.percentRemaining)
    expectEqual(status.resetDescription, "1,500 tokens observed")
    expectEqual(status.state, .unknown)
    expectEqual(status.confidence, .low)
    expectNil(status.errorMessage)
}

private func codexAdapterReportsHonestUnknownWhenDetectionIsUnavailable() async {
    let adapter = CodexAdapter(sessionsRoot: temporaryDirectory())
    let status = await adapter.refresh()

    expectEqual(status.id, .codex)
    expectEqual(status.displayName, "Codex")
    expectNil(status.percentRemaining)
    expectEqual(status.state, .unknown)
    expectEqual(status.confidence, .unknown)
    expectNil(status.errorMessage)
}

private func codexAdapterReadsLatestLocalRateLimitEvent() async {
    let sessionsRoot = temporaryDirectory()
    let dayDirectory = sessionsRoot.appendingPathComponent("2026/05/26", isDirectory: true)
    try! FileManager.default.createDirectory(at: dayDirectory, withIntermediateDirectories: true)

    let olderSession = dayDirectory.appendingPathComponent("rollout-old.jsonl")
    try! """
    {"timestamp":"2026-05-26T09:00:00Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","primary":{"used_percent":80.0,"window_minutes":300,"resets_at":1779990000},"plan_type":"plus"}}}
    """.write(to: olderSession, atomically: true, encoding: .utf8)

    let newerSession = dayDirectory.appendingPathComponent("rollout-new.jsonl")
    try! """
    {"timestamp":"2026-05-26T10:00:00Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","primary":{"used_percent":37.4,"window_minutes":300,"resets_at":1779996400},"secondary":{"used_percent":52.0,"window_minutes":10080,"resets_at":1780500000},"plan_type":"plus"}}}
    """.write(to: newerSession, atomically: true, encoding: .utf8)

    let adapter = CodexAdapter(
        sessionsRoot: sessionsRoot,
        now: { Date(timeIntervalSince1970: 1779992800) }
    )
    let status = await adapter.refresh()

    expectEqual(status.id, .codex)
    expectEqual(status.displayName, "Codex")
    expectEqual(status.percentRemaining, 63)
    expectEqual(status.resetDescription, "resets in 1h 0m")
    expectEqual(status.state, .healthy)
    expectEqual(status.confidence, .high)
    expectEqual(status.sourceDescription, "Latest local Codex session rate limit event")
    expectNil(status.errorMessage)
}

private func codexAdapterReportsUnknownWhenLatestRateLimitEventIsExpired() async {
    let sessionsRoot = temporaryDirectory()
    let dayDirectory = sessionsRoot.appendingPathComponent("2026/05/26", isDirectory: true)
    try! FileManager.default.createDirectory(at: dayDirectory, withIntermediateDirectories: true)

    let session = dayDirectory.appendingPathComponent("rollout-expired.jsonl")
    try! """
    {"timestamp":"2026-05-26T10:00:00Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","primary":{"used_percent":66.0,"window_minutes":300,"resets_at":1779795000},"plan_type":"plus"}}}
    """.write(to: session, atomically: true, encoding: .utf8)

    let adapter = CodexAdapter(
        sessionsRoot: sessionsRoot,
        now: { Date(timeIntervalSince1970: 1779800000) }
    )
    let status = await adapter.refresh()

    expectNil(status.percentRemaining)
    expectNil(status.resetDescription)
    expectEqual(status.state, .unknown)
    expectEqual(status.confidence, .low)
    expectEqual(status.sourceDescription, "Latest local Codex rate limit event is expired; open Codex to refresh usage.")
}

private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("TokenCatTests")
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
}
