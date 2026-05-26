public protocol ProviderAdapter: Sendable {
    var id: ProviderID { get }
    var displayName: String { get }

    func refresh() async -> ProviderStatus
}
