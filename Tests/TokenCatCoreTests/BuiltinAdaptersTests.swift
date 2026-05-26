import Foundation
import TokenCatCore

func runBuiltinAdaptersTests() async {
    await claudeAdapterReportsHonestUnknownWhenDetectionIsUnavailable()
    await codexAdapterReportsHonestUnknownWhenDetectionIsUnavailable()
    await codexAdapterReadsLatestLocalRateLimitEvent()
}

private func claudeAdapterReportsHonestUnknownWhenDetectionIsUnavailable() async {
    let adapter = ClaudeAdapter()
    let status = await adapter.refresh()

    expectEqual(status.id, .claude)
    expectEqual(status.displayName, "Claude")
    expectNil(status.percentRemaining)
    expectEqual(status.state, .unknown)
    expectEqual(status.confidence, .unknown)
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

private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("TokenCatTests")
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
}
