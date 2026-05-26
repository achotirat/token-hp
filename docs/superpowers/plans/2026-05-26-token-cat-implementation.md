# Token Cat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first native macOS menu-bar version of Token Cat with Claude and Codex provider cards, cat threshold state, expandable details, and low/exhausted notification logic.

**Architecture:** Use a Swift Package with a testable `TokenCatCore` library and a native SwiftUI/AppKit executable target named `TokenCatApp`. Core owns provider models, threshold decisions, worst-provider selection, adapter protocols, and notification transition logic; the app target owns macOS menu-bar UI, settings, and notification delivery.

**Tech Stack:** Swift 6, Swift Package Manager, XCTest, SwiftUI, AppKit, UserNotifications, macOS 14+.

---

## File Structure

- Create `Package.swift`: declares `TokenCatCore`, `TokenCatApp`, and `TokenCatCoreTests`.
- Create `README.md`: public repo overview, current provider support, development commands.
- Create `Sources/TokenCatCore/TokenCatCore.swift`: minimal package scaffold file that keeps the initial package buildable.
- Create `Sources/TokenCatApp/TokenCatApp.swift`: temporary command-line scaffold replaced by the native macOS app entry point.
- Create `Sources/TokenCatCore/ProviderModels.swift`: provider identifiers, status states, confidence, status value.
- Create `Sources/TokenCatCore/CatState.swift`: threshold settings and cat-state mapping.
- Create `Sources/TokenCatCore/StatusReducer.swift`: worst-provider selection and aggregate state.
- Create `Sources/TokenCatCore/NotificationStateMachine.swift`: detects one-time low/exhausted crossings.
- Create `Sources/TokenCatCore/ProviderAdapter.swift`: provider adapter protocol and refresh result shape.
- Create `Sources/TokenCatCore/BuiltinAdapters.swift`: initial Claude and Codex adapters that report honest `unknown` until real local detection is implemented.
- Create `Sources/TokenCatApp/TokenCatApp.swift`: native macOS app entry point.
- Create `Sources/TokenCatApp/AppState.swift`: observable app state, refresh loop, settings bridge.
- Create `Sources/TokenCatApp/MenuBarIconView.swift`: original vector-style cat icon.
- Create `Sources/TokenCatApp/ProviderPanelView.swift`: friendly provider cards and expandable details.
- Create `Sources/TokenCatApp/SettingsView.swift`: threshold, refresh, and notification controls.
- Create `Sources/TokenCatApp/NotificationService.swift`: macOS notification authorization and delivery.
- Create `Tests/TokenCatCoreTests/CatStateTests.swift`: threshold behavior.
- Create `Tests/TokenCatCoreTests/StatusReducerTests.swift`: worst-provider behavior.
- Create `Tests/TokenCatCoreTests/NotificationStateMachineTests.swift`: crossing behavior.
- Create `Tests/TokenCatCoreTests/BuiltinAdaptersTests.swift`: default Claude/Codex adapter behavior.

## Task 1: Swift Package Scaffold

**Files:**
- Create: `Package.swift`
- Create: `README.md`
- Create: `Sources/TokenCatCore/TokenCatCore.swift`
- Create: `Sources/TokenCatApp/TokenCatApp.swift`

- [ ] **Step 1: Create package manifest**

Create `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TokenCat",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "TokenCatCore", targets: ["TokenCatCore"]),
        .executable(name: "TokenCatApp", targets: ["TokenCatApp"])
    ],
    targets: [
        .target(name: "TokenCatCore"),
        .executableTarget(
            name: "TokenCatApp",
            dependencies: ["TokenCatCore"]
        ),
        .testTarget(
            name: "TokenCatCoreTests",
            dependencies: ["TokenCatCore"]
        )
    ]
)
```

- [ ] **Step 2: Create public README**

Create `README.md`:

```markdown
# Token Cat

Token Cat is a native macOS menu-bar app for tracking Claude and Codex usage before reset.

The menu-bar cat reflects the most urgent provider:

- Sitting: all tracked providers are above 30%.
- Lying down: the lowest provider is greater than 5% and up to 30%.
- Sleeping: the lowest provider is 5% or below, exhausted, or blocked.

## Provider Support

| Provider | V1 Status | Notes |
| --- | --- | --- |
| Claude | Planned | Adapter boundary exists first; local detection is added behind it. |
| Codex | Planned | Adapter boundary exists first; local detection is added behind it. |
| Minimax | Deferred | Future adapter. |
| Qwen | Deferred | Future adapter. |
| Kimi | Deferred | Future adapter. |

## Development

```bash
swift test
swift run TokenCatApp
```

## Design

See `docs/superpowers/specs/2026-05-26-token-cat-design.md`.
```

- [ ] **Step 3: Create temporary target source files**

Create `Sources/TokenCatCore/TokenCatCore.swift`:

```swift
public enum TokenCatCoreScaffold {
    public static let packageIsReady = true
}
```

Create `Sources/TokenCatApp/TokenCatApp.swift`:

```swift
import TokenCatCore

@main
struct TokenCatApp {
    static func main() {
        print("Token Cat scaffold ready: \(TokenCatCoreScaffold.packageIsReady)")
    }
}
```

- [ ] **Step 4: Verify package describes cleanly**

Run: `swift package describe`

Expected: command succeeds and lists `TokenCatCore`, `TokenCatApp`, and `TokenCatCoreTests`.

- [ ] **Step 5: Verify scaffold builds**

Run: `swift test`

Expected: PASS with no tests discovered or no test failures.

- [ ] **Step 6: Commit**

```bash
git add Package.swift README.md Sources/TokenCatCore/TokenCatCore.swift Sources/TokenCatApp/TokenCatApp.swift
git commit -m "chore: scaffold Swift package"
```

## Task 2: Core Provider Models And Cat Thresholds

**Files:**
- Create: `Sources/TokenCatCore/ProviderModels.swift`
- Create: `Sources/TokenCatCore/CatState.swift`
- Create: `Tests/TokenCatCoreTests/CatStateTests.swift`

- [ ] **Step 1: Write failing cat-state tests**

Create `Tests/TokenCatCoreTests/CatStateTests.swift`:

```swift
import XCTest
@testable import TokenCatCore

final class CatStateTests: XCTestCase {
    func testCatSitsAboveLowThreshold() {
        let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
        XCTAssertEqual(CatState.statusState(for: 31, providerState: .healthy, thresholds: thresholds), .sitting)
    }

    func testCatLiesDownAtLowThreshold() {
        let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
        XCTAssertEqual(CatState.statusState(for: 30, providerState: .low, thresholds: thresholds), .lyingDown)
        XCTAssertEqual(CatState.statusState(for: 6, providerState: .low, thresholds: thresholds), .lyingDown)
    }

    func testCatSleepsAtSleepThreshold() {
        let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
        XCTAssertEqual(CatState.statusState(for: 5, providerState: .exhausted, thresholds: thresholds), .sleeping)
        XCTAssertEqual(CatState.statusState(for: 0, providerState: .exhausted, thresholds: thresholds), .sleeping)
    }

    func testBlockedAlwaysSleeps() {
        let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
        XCTAssertEqual(CatState.statusState(for: 90, providerState: .blocked, thresholds: thresholds), .sleeping)
    }

    func testUnknownDoesNotSleep() {
        let thresholds = CatThresholds(lowPercent: 30, sleepPercent: 5)
        XCTAssertEqual(CatState.statusState(for: nil, providerState: .unknown, thresholds: thresholds), .sitting)
        XCTAssertEqual(CatState.statusState(for: nil, providerState: .error, thresholds: thresholds), .sitting)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter CatStateTests`

Expected: FAIL because `TokenCatCore` types do not exist.

- [ ] **Step 3: Implement provider models**

Create `Sources/TokenCatCore/ProviderModels.swift`:

```swift
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
```

- [ ] **Step 4: Implement cat thresholds and state mapping**

Create `Sources/TokenCatCore/CatState.swift`:

```swift
public enum CatState: String, Equatable, Sendable {
    case sitting
    case lyingDown
    case sleeping

    public static func statusState(
        for percentRemaining: Int?,
        providerState: ProviderState,
        thresholds: CatThresholds
    ) -> CatState {
        switch providerState {
        case .blocked, .exhausted:
            return .sleeping
        case .unknown, .error:
            return .sitting
        case .healthy, .low:
            guard let percentRemaining else {
                return .sitting
            }

            if percentRemaining <= thresholds.sleepPercent {
                return .sleeping
            }

            if percentRemaining <= thresholds.lowPercent {
                return .lyingDown
            }

            return .sitting
        }
    }
}

public struct CatThresholds: Equatable, Sendable {
    public var lowPercent: Int
    public var sleepPercent: Int

    public init(lowPercent: Int = 30, sleepPercent: Int = 5) {
        self.lowPercent = lowPercent
        self.sleepPercent = sleepPercent
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `swift test --filter CatStateTests`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/TokenCatCore/ProviderModels.swift Sources/TokenCatCore/CatState.swift Tests/TokenCatCoreTests/CatStateTests.swift
git commit -m "feat: add provider models and cat thresholds"
```

## Task 3: Worst-Provider Status Reducer

**Files:**
- Create: `Sources/TokenCatCore/StatusReducer.swift`
- Create: `Tests/TokenCatCoreTests/StatusReducerTests.swift`

- [ ] **Step 1: Write failing reducer tests**

Create `Tests/TokenCatCoreTests/StatusReducerTests.swift`:

```swift
import Foundation
import XCTest
@testable import TokenCatCore

private let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

private func status(
    id: ProviderID,
    percent: Int?,
    state: ProviderState
) -> ProviderStatus {
    ProviderStatus(
        id: id,
        displayName: id.rawValue.capitalized,
        percentRemaining: percent,
        resetDescription: "resets soon",
        state: state,
        sourceDescription: "test",
        confidence: .high,
        lastRefresh: fixedDate
    )
}

final class StatusReducerTests: XCTestCase {
    func testWorstProviderChoosesSleepingStateOverLowPercentHealthyProvider() {
        let statuses = [
            status(id: .claude, percent: 90, state: .healthy),
            status(id: .codex, percent: 2, state: .exhausted)
        ]

        let snapshot = StatusReducer.reduce(statuses: statuses, thresholds: CatThresholds())

        XCTAssertEqual(snapshot.worstProvider?.id, .codex)
        XCTAssertEqual(snapshot.catState, .sleeping)
    }

    func testWorstProviderChoosesLowestKnownPercent() {
        let statuses = [
            status(id: .claude, percent: 72, state: .healthy),
            status(id: .codex, percent: 18, state: .low)
        ]

        let snapshot = StatusReducer.reduce(statuses: statuses, thresholds: CatThresholds())

        XCTAssertEqual(snapshot.worstProvider?.id, .codex)
        XCTAssertEqual(snapshot.catState, .lyingDown)
    }

    func testUnknownDoesNotBeatKnownHealthyProvider() {
        let statuses = [
            status(id: .claude, percent: nil, state: .unknown),
            status(id: .codex, percent: 80, state: .healthy)
        ]

        let snapshot = StatusReducer.reduce(statuses: statuses, thresholds: CatThresholds())

        XCTAssertEqual(snapshot.worstProvider?.id, .codex)
        XCTAssertEqual(snapshot.catState, .sitting)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter StatusReducerTests`

Expected: FAIL because `StatusReducer` does not exist.

- [ ] **Step 3: Implement reducer**

Create `Sources/TokenCatCore/StatusReducer.swift`:

```swift
public struct StatusSnapshot: Equatable, Sendable {
    public var statuses: [ProviderStatus]
    public var worstProvider: ProviderStatus?
    public var catState: CatState

    public init(statuses: [ProviderStatus], worstProvider: ProviderStatus?, catState: CatState) {
        self.statuses = statuses
        self.worstProvider = worstProvider
        self.catState = catState
    }
}

public enum StatusReducer {
    public static func reduce(statuses: [ProviderStatus], thresholds: CatThresholds) -> StatusSnapshot {
        let worst = statuses.max { lhs, rhs in
            severity(lhs, thresholds: thresholds) < severity(rhs, thresholds: thresholds)
        }

        let catState = worst.map {
            CatState.statusState(
                for: $0.percentRemaining,
                providerState: $0.state,
                thresholds: thresholds
            )
        } ?? .sitting

        return StatusSnapshot(statuses: statuses, worstProvider: worst, catState: catState)
    }

    private static func severity(_ status: ProviderStatus, thresholds: CatThresholds) -> Int {
        switch CatState.statusState(
            for: status.percentRemaining,
            providerState: status.state,
            thresholds: thresholds
        ) {
        case .sleeping:
            return 300 + inversePercent(status.percentRemaining)
        case .lyingDown:
            return 200 + inversePercent(status.percentRemaining)
        case .sitting:
            if status.state == .unknown || status.state == .error {
                return 0
            }
            return 100 + inversePercent(status.percentRemaining)
        }
    }

    private static func inversePercent(_ percent: Int?) -> Int {
        100 - max(0, min(percent ?? 100, 100))
    }
}
```

- [ ] **Step 4: Run reducer tests**

Run: `swift test --filter StatusReducerTests`

Expected: PASS.

- [ ] **Step 5: Run all core tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/TokenCatCore/StatusReducer.swift Tests/TokenCatCoreTests/StatusReducerTests.swift
git commit -m "feat: reduce provider statuses to cat state"
```

## Task 4: Notification Crossing Logic

**Files:**
- Create: `Sources/TokenCatCore/NotificationStateMachine.swift`
- Create: `Tests/TokenCatCoreTests/NotificationStateMachineTests.swift`

- [ ] **Step 1: Write failing notification tests**

Create `Tests/TokenCatCoreTests/NotificationStateMachineTests.swift`:

```swift
import XCTest
@testable import TokenCatCore

final class NotificationStateMachineTests: XCTestCase {
    func testFirstLowCrossingNotifiesOnce() {
        var machine = NotificationStateMachine()

        XCTAssertNil(machine.record(provider: .claude, newCatState: .sitting))
        XCTAssertEqual(machine.record(provider: .claude, newCatState: .lyingDown), .low)
        XCTAssertNil(machine.record(provider: .claude, newCatState: .lyingDown))
    }

    func testRecoveredProviderCanNotifyLowAgain() {
        var machine = NotificationStateMachine()

        _ = machine.record(provider: .claude, newCatState: .lyingDown)
        XCTAssertNil(machine.record(provider: .claude, newCatState: .sitting))
        XCTAssertEqual(machine.record(provider: .claude, newCatState: .lyingDown), .low)
    }

    func testSleepingCrossingNotifiesExhausted() {
        var machine = NotificationStateMachine()

        XCTAssertEqual(machine.record(provider: .codex, newCatState: .sleeping), .exhausted)
        XCTAssertNil(machine.record(provider: .codex, newCatState: .sleeping))
    }

    func testLowThenSleepingNotifiesBothTransitions() {
        var machine = NotificationStateMachine()

        XCTAssertEqual(machine.record(provider: .codex, newCatState: .lyingDown), .low)
        XCTAssertEqual(machine.record(provider: .codex, newCatState: .sleeping), .exhausted)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter NotificationStateMachineTests`

Expected: FAIL because `NotificationStateMachine` does not exist.

- [ ] **Step 3: Implement notification state machine**

Create `Sources/TokenCatCore/NotificationStateMachine.swift`:

```swift
public enum NotificationEvent: Equatable, Sendable {
    case low
    case exhausted
}

public struct NotificationStateMachine: Sendable {
    private var previousStates: [ProviderID: CatState]

    public init(previousStates: [ProviderID: CatState] = [:]) {
        self.previousStates = previousStates
    }

    public mutating func record(provider: ProviderID, newCatState: CatState) -> NotificationEvent? {
        let previous = previousStates[provider] ?? .sitting
        previousStates[provider] = newCatState

        switch (previous, newCatState) {
        case (.sitting, .lyingDown):
            return .low
        case (.sitting, .sleeping), (.lyingDown, .sleeping):
            return .exhausted
        default:
            return nil
        }
    }
}
```

- [ ] **Step 4: Run notification tests**

Run: `swift test --filter NotificationStateMachineTests`

Expected: PASS.

- [ ] **Step 5: Run all tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/TokenCatCore/NotificationStateMachine.swift Tests/TokenCatCoreTests/NotificationStateMachineTests.swift
git commit -m "feat: add notification crossing logic"
```

## Task 5: Provider Adapter Protocol And Built-In Adapters

**Files:**
- Create: `Sources/TokenCatCore/ProviderAdapter.swift`
- Create: `Sources/TokenCatCore/BuiltinAdapters.swift`
- Create: `Tests/TokenCatCoreTests/BuiltinAdaptersTests.swift`

- [ ] **Step 1: Write failing adapter tests**

Create `Tests/TokenCatCoreTests/BuiltinAdaptersTests.swift`:

```swift
import XCTest
@testable import TokenCatCore

final class BuiltinAdaptersTests: XCTestCase {
    func testClaudeAdapterReportsHonestUnknownWhenDetectionIsUnavailable() async {
        let adapter = ClaudeAdapter()
        let status = await adapter.refresh()

        XCTAssertEqual(status.id, .claude)
        XCTAssertEqual(status.displayName, "Claude")
        XCTAssertNil(status.percentRemaining)
        XCTAssertEqual(status.state, .unknown)
        XCTAssertEqual(status.confidence, .unknown)
        XCTAssertNil(status.errorMessage)
    }

    func testCodexAdapterReportsHonestUnknownWhenDetectionIsUnavailable() async {
        let adapter = CodexAdapter()
        let status = await adapter.refresh()

        XCTAssertEqual(status.id, .codex)
        XCTAssertEqual(status.displayName, "Codex")
        XCTAssertNil(status.percentRemaining)
        XCTAssertEqual(status.state, .unknown)
        XCTAssertEqual(status.confidence, .unknown)
        XCTAssertNil(status.errorMessage)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter BuiltinAdaptersTests`

Expected: FAIL because adapters do not exist.

- [ ] **Step 3: Implement adapter protocol**

Create `Sources/TokenCatCore/ProviderAdapter.swift`:

```swift
public protocol ProviderAdapter: Sendable {
    var id: ProviderID { get }
    var displayName: String { get }

    func refresh() async -> ProviderStatus
}
```

- [ ] **Step 4: Implement initial built-in adapters**

Create `Sources/TokenCatCore/BuiltinAdapters.swift`:

```swift
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
```

- [ ] **Step 5: Run adapter tests**

Run: `swift test --filter BuiltinAdaptersTests`

Expected: PASS.

- [ ] **Step 6: Run all tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Sources/TokenCatCore/ProviderAdapter.swift Sources/TokenCatCore/BuiltinAdapters.swift Tests/TokenCatCoreTests/BuiltinAdaptersTests.swift
git commit -m "feat: add Claude and Codex adapters"
```

## Task 6: App State And Refresh Loop

**Files:**
- Create: `Sources/TokenCatApp/AppState.swift`

- [ ] **Step 1: Implement app settings and state**

Create `Sources/TokenCatApp/AppState.swift`:

```swift
import Foundation
import Observation
import TokenCatCore

@Observable
@MainActor
final class AppState {
    var thresholds = CatThresholds()
    var refreshIntervalSeconds: Double = 300
    var notificationsEnabled = true
    var snapshot = StatusSnapshot(statuses: [], worstProvider: nil, catState: .sitting)
    var expandedProvider: ProviderID?

    private let adapters: [any ProviderAdapter]
    private var notificationStateMachine = NotificationStateMachine()

    init(adapters: [any ProviderAdapter] = [ClaudeAdapter(), CodexAdapter()]) {
        self.adapters = adapters
    }

    func refresh() async -> [(ProviderStatus, NotificationEvent)] {
        var statuses: [ProviderStatus] = []

        for adapter in adapters {
            let status = await adapter.refresh()
            statuses.append(status)
        }

        snapshot = StatusReducer.reduce(statuses: statuses, thresholds: thresholds)

        return statuses.compactMap { status in
            let catState = CatState.statusState(
                for: status.percentRemaining,
                providerState: status.state,
                thresholds: thresholds
            )

            guard let event = notificationStateMachine.record(provider: status.id, newCatState: catState) else {
                return nil
            }

            return (status, event)
        }
    }

    func toggleExpandedProvider(_ provider: ProviderID) {
        expandedProvider = expandedProvider == provider ? nil : provider
    }
}
```

- [ ] **Step 2: Build app target**

Run: `swift build`

Expected: FAIL if app entry point does not exist yet. This confirms core compiles but executable still needs UI.

- [ ] **Step 3: Commit app state**

```bash
git add Sources/TokenCatApp/AppState.swift
git commit -m "feat: add app state refresh loop"
```

## Task 7: Menu-Bar UI And Provider Cards

**Files:**
- Modify: `Sources/TokenCatApp/TokenCatApp.swift`
- Create: `Sources/TokenCatApp/MenuBarIconView.swift`
- Create: `Sources/TokenCatApp/ProviderPanelView.swift`

- [ ] **Step 1: Implement vector cat menu icon**

Create `Sources/TokenCatApp/MenuBarIconView.swift`:

```swift
import SwiftUI
import TokenCatCore

struct MenuBarIconView: View {
    let state: CatState

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let stroke = Path { path in
                switch state {
                case .sitting:
                    path.addEllipse(in: rect.insetBy(dx: size.width * 0.28, dy: size.height * 0.18))
                    path.move(to: CGPoint(x: size.width * 0.34, y: size.height * 0.22))
                    path.addLine(to: CGPoint(x: size.width * 0.24, y: size.height * 0.02))
                    path.move(to: CGPoint(x: size.width * 0.66, y: size.height * 0.22))
                    path.addLine(to: CGPoint(x: size.width * 0.76, y: size.height * 0.02))
                case .lyingDown:
                    path.addRoundedRect(in: rect.insetBy(dx: size.width * 0.10, dy: size.height * 0.34), cornerSize: CGSize(width: 10, height: 10))
                    path.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.44))
                    path.addLine(to: CGPoint(x: size.width * 0.08, y: size.height * 0.24))
                case .sleeping:
                    path.addEllipse(in: rect.insetBy(dx: size.width * 0.12, dy: size.height * 0.30))
                    path.move(to: CGPoint(x: size.width * 0.66, y: size.height * 0.12))
                    path.addLine(to: CGPoint(x: size.width * 0.82, y: size.height * 0.12))
                    path.addLine(to: CGPoint(x: size.width * 0.66, y: size.height * 0.28))
                    path.addLine(to: CGPoint(x: size.width * 0.82, y: size.height * 0.28))
                }
            }

            context.stroke(stroke, with: .color(.primary), lineWidth: 2)
        }
        .frame(width: 28, height: 18)
        .rotationEffect(state == .sitting ? .degrees(-8) : .zero)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch state {
        case .sitting:
            return "Token Cat healthy"
        case .lyingDown:
            return "Token Cat low"
        case .sleeping:
            return "Token Cat exhausted"
        }
    }
}
```

- [ ] **Step 2: Implement provider panel**

Create `Sources/TokenCatApp/ProviderPanelView.swift`:

```swift
import SwiftUI
import TokenCatCore

struct ProviderPanelView: View {
    @Bindable var appState: AppState
    let refreshAction: () -> Void
    let openSettingsAction: () -> Void
    let quitAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Token Cat")
                    .font(.headline)
                Spacer()
                MenuBarIconView(state: appState.snapshot.catState)
                    .frame(width: 36, height: 24)
            }

            ForEach(appState.snapshot.statuses, id: \.id) { status in
                ProviderCardView(
                    status: status,
                    isExpanded: appState.expandedProvider == status.id
                )
                .onTapGesture {
                    appState.toggleExpandedProvider(status.id)
                }
            }

            Divider()

            HStack {
                Button("Refresh", action: refreshAction)
                Button("Settings", action: openSettingsAction)
                Spacer()
                Button("Quit", action: quitAction)
            }
        }
        .padding(14)
        .frame(width: 320)
    }
}

private struct ProviderCardView: View {
    let status: ProviderStatus
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(status.displayName)
                    .font(.headline)
                Spacer()
                Text(percentText)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            ProgressView(value: Double(status.percentRemaining ?? 0), total: 100)

            Text(summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)

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
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var percentText: String {
        guard let percent = status.percentRemaining else {
            return "Unknown"
        }

        return "\(percent)%"
    }

    private var summaryText: String {
        let reset = status.resetDescription ?? "reset unknown"
        return "\(reset) · \(status.state.rawValue.capitalized)"
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .fontWeight(.semibold)
            Text(value)
        }
    }
}
```

- [ ] **Step 3: Implement app entry point**

Replace `Sources/TokenCatApp/TokenCatApp.swift` with:

```swift
import AppKit
import SwiftUI

@main
struct TokenCatApp: App {
    @State private var appState = AppState()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            ProviderPanelView(
                appState: appState,
                refreshAction: {
                    Task { _ = await appState.refresh() }
                },
                openSettingsAction: {
                    openSettings()
                },
                quitAction: {
                    NSApplication.shared.terminate(nil)
                }
            )
            .task {
                _ = await appState.refresh()
            }
        } label: {
            MenuBarIconView(state: appState.snapshot.catState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(appState: appState)
        }
    }
}
```

- [ ] **Step 4: Build to expose missing settings view**

Run: `swift build`

Expected: FAIL because `SettingsView` does not exist.

- [ ] **Step 5: Commit UI shell**

```bash
git add Sources/TokenCatApp/TokenCatApp.swift Sources/TokenCatApp/MenuBarIconView.swift Sources/TokenCatApp/ProviderPanelView.swift
git commit -m "feat: add menu bar panel UI"
```

## Task 8: Settings View And Notification Service

**Files:**
- Create: `Sources/TokenCatApp/SettingsView.swift`
- Create: `Sources/TokenCatApp/NotificationService.swift`
- Modify: `Sources/TokenCatApp/TokenCatApp.swift`

- [ ] **Step 1: Implement settings view**

Create `Sources/TokenCatApp/SettingsView.swift`:

```swift
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
```

- [ ] **Step 2: Implement notification service**

Create `Sources/TokenCatApp/NotificationService.swift`:

```swift
import Foundation
import TokenCatCore
import UserNotifications

struct NotificationService {
    func requestAuthorization() async {
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            // Authorization failure should not stop quota display.
        }
    }

    func send(provider: ProviderStatus, event: NotificationEvent) async {
        let content = UNMutableNotificationContent()
        content.title = title(provider: provider, event: event)
        content.body = body(provider: provider, event: event)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(provider.id.rawValue)-\(event)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Notification delivery failure should not stop quota display.
        }
    }

    private func title(provider: ProviderStatus, event: NotificationEvent) -> String {
        switch event {
        case .low:
            return "\(provider.displayName) is running low"
        case .exhausted:
            return "\(provider.displayName) is almost out"
        }
    }

    private func body(provider: ProviderStatus, event: NotificationEvent) -> String {
        let percent = provider.percentRemaining.map { "\($0)%" } ?? "unknown remaining"
        let reset = provider.resetDescription ?? "reset time unknown"

        switch event {
        case .low:
            return "\(provider.displayName) has \(percent). \(reset)."
        case .exhausted:
            return "\(provider.displayName) has reached the sleep threshold. \(reset)."
        }
    }
}
```

- [ ] **Step 3: Wire notifications into app entry point**

Modify `Sources/TokenCatApp/TokenCatApp.swift` to:

```swift
import AppKit
import SwiftUI

@main
struct TokenCatApp: App {
    @State private var appState = AppState()
    private let notificationService = NotificationService()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            ProviderPanelView(
                appState: appState,
                refreshAction: {
                    refresh()
                },
                openSettingsAction: {
                    openSettings()
                },
                quitAction: {
                    NSApplication.shared.terminate(nil)
                }
            )
            .task {
                await notificationService.requestAuthorization()
                refresh()
            }
        } label: {
            MenuBarIconView(state: appState.snapshot.catState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(appState: appState)
        }
    }

    private func refresh() {
        Task {
            let events = await appState.refresh()
            guard appState.notificationsEnabled else {
                return
            }

            for (provider, event) in events {
                await notificationService.send(provider: provider, event: event)
            }
        }
    }
}
```

- [ ] **Step 4: Build**

Run: `swift build`

Expected: PASS.

- [ ] **Step 5: Run tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/TokenCatApp/SettingsView.swift Sources/TokenCatApp/NotificationService.swift Sources/TokenCatApp/TokenCatApp.swift
git commit -m "feat: add settings and notifications"
```

## Task 9: Verification And Public Repo Readiness

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-05-26-token-cat-design.md` only if implementation reveals a mismatch.

- [ ] **Step 1: Update README with current behavior**

Modify `README.md` provider table to show the honest first implementation:

```markdown
| Provider | V1 Status | Notes |
| --- | --- | --- |
| Claude | Adapter scaffolded | Shows `Unknown` until local detection is implemented. |
| Codex | Adapter scaffolded | Shows `Unknown` until local detection is implemented. |
| Minimax | Deferred | Future adapter. |
| Qwen | Deferred | Future adapter. |
| Kimi | Deferred | Future adapter. |
```

- [ ] **Step 2: Run full verification**

Run: `swift test`

Expected: PASS.

Run: `swift build`

Expected: PASS.

- [ ] **Step 3: Inspect Git status**

Run: `git status --short`

Expected: only README changes are listed before staging.

- [ ] **Step 4: Commit readiness docs**

```bash
git add README.md
git commit -m "docs: document initial provider support"
```

- [ ] **Step 5: Final local check**

Run: `git status --short`

Expected: clean working tree.

Run: `git log --oneline -5`

Expected: shows the recent implementation commits.

## Self-Review

Spec coverage:

- Native macOS SwiftUI menu-bar app: Tasks 1, 6, 7, and 8.
- Claude and Codex only: Task 5.
- Percent remaining first, reset time second: Task 7.
- Cat states and thresholds: Tasks 2 and 3.
- Friendly provider cards: Task 7.
- Expandable card details: Task 7.
- Low/exhausted notifications: Tasks 4 and 8.
- Settings for notifications, refresh interval, and thresholds: Task 8.
- Honest unknown/error handling: Tasks 2, 3, 5, and 7.
- Public GitHub sharing basics: Tasks 1 and 9.
- Weekly/session-limit drilldown: documented as deferred in the spec and intentionally not implemented in this v1 plan.

Placeholder scan:

- The plan intentionally uses no placeholder markers.
- Provider adapters return honest `unknown` statuses until local detection is designed with real source evidence.

Type consistency:

- `ProviderID`, `ProviderStatus`, `ProviderState`, `ProviderConfidence`, `CatState`, `CatThresholds`, `StatusReducer`, `StatusSnapshot`, `NotificationStateMachine`, and `NotificationEvent` are introduced before use.
- App files import `TokenCatCore` when using core types.
