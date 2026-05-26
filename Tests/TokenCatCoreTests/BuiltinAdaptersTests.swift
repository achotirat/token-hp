import TokenCatCore

func runBuiltinAdaptersTests() async {
    await claudeAdapterReportsHonestUnknownWhenDetectionIsUnavailable()
    await codexAdapterReportsHonestUnknownWhenDetectionIsUnavailable()
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
    let adapter = CodexAdapter()
    let status = await adapter.refresh()

    expectEqual(status.id, .codex)
    expectEqual(status.displayName, "Codex")
    expectNil(status.percentRemaining)
    expectEqual(status.state, .unknown)
    expectEqual(status.confidence, .unknown)
    expectNil(status.errorMessage)
}
