import XCTest
@testable import CodeIslandCore

final class OmpControlEventPolicyTests: XCTestCase {
    func testDropsOmpPermissionAndQuestionEvents() {
        XCTAssertTrue(OmpControlEventPolicy.shouldDrop(
            source: "omp",
            normalizedEventName: "PermissionRequest",
            hasQuestion: false
        ))
        XCTAssertTrue(OmpControlEventPolicy.shouldDrop(
            source: "omp",
            normalizedEventName: "Notification",
            hasQuestion: true
        ))
    }

    func testAllowsOmpTelemetryAndOtherSourceControlEvents() {
        XCTAssertFalse(OmpControlEventPolicy.shouldDrop(
            source: "omp",
            normalizedEventName: "SessionStart",
            hasQuestion: false
        ))
        XCTAssertFalse(OmpControlEventPolicy.shouldDrop(
            source: "omp",
            normalizedEventName: "PreToolUse",
            hasQuestion: false
        ))
        XCTAssertFalse(OmpControlEventPolicy.shouldDrop(
            source: "codex",
            normalizedEventName: "PermissionRequest",
            hasQuestion: false
        ))
    }
}
