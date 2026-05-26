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
