import Foundation

public struct ClaudeAdapter: ProviderAdapter {
    public let id: ProviderID = .claude
    public let displayName = "Claude"

    public init() {}

    public func refresh() async -> ProviderStatus {
        ProviderStatus(
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

    public init() {}

    public func refresh() async -> ProviderStatus {
        ProviderStatus(
            id: id,
            displayName: displayName,
            percentRemaining: nil,
            resetDescription: nil,
            state: .unknown,
            sourceDescription: "Local Codex usage detection is not configured yet.",
            confidence: .unknown,
            lastRefresh: Date()
        )
    }
}
