import Foundation

public enum ProviderID: String, Codable, CaseIterable, Sendable {
    case claude
    case codex
}

public enum ProviderState: String, Codable, Sendable {
    case healthy
    case low
    case exhausted
    case blocked
    case unknown
    case error
}

public enum ProviderConfidence: String, Codable, Sendable {
    case high
    case medium
    case low
    case unknown
}

public struct ProviderStatus: Equatable, Sendable {
    public var id: ProviderID
    public var displayName: String
    public var percentRemaining: Int?
    public var resetDescription: String?
    public var state: ProviderState
    public var sourceDescription: String
    public var confidence: ProviderConfidence
    public var lastRefresh: Date
    public var errorMessage: String?

    public init(
        id: ProviderID,
        displayName: String,
        percentRemaining: Int?,
        resetDescription: String?,
        state: ProviderState,
        sourceDescription: String,
        confidence: ProviderConfidence,
        lastRefresh: Date,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.percentRemaining = percentRemaining
        self.resetDescription = resetDescription
        self.state = state
        self.sourceDescription = sourceDescription
        self.confidence = confidence
        self.lastRefresh = lastRefresh
        self.errorMessage = errorMessage
    }
}
