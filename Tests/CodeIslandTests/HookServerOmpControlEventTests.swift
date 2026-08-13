import XCTest
@testable import CodeIsland
import CodeIslandCore

final class HookServerOmpControlEventTests: XCTestCase {
    func testOmpControlEventsAreIgnored() async throws {
        let permission = try event([
            "hook_event_name": "PermissionRequest",
            "session_id": "omp-019ff97e-ccb8-7000-a22f-d1a5791d3532",
            "_source": "omp",
            "tool_name": "Bash"
        ])
        let question = try event([
            "hook_event_name": "Notification",
            "session_id": "omp-019ff97e-ccb8-7000-a22f-d1a5791d3532",
            "_source": "omp",
            "question": "Continue?",
            "options": ["Yes", "No"]
        ])

        let permissionRoute = await MainActor.run { HookServer.routeKind(for: permission) }
        let questionRoute = await MainActor.run { HookServer.routeKind(for: question) }
        XCTAssertEqual(permissionRoute, .ignored)
        XCTAssertEqual(questionRoute, .ignored)
    }

    func testOmpLifecycleAndToolEventsRemainTelemetry() async throws {
        let lifecycle = try event([
            "hook_event_name": "SessionStart",
            "session_id": "omp-019ff97e-ccb8-7000-a22f-d1a5791d3532",
            "_source": "omp"
        ])
        let tool = try event([
            "hook_event_name": "PreToolUse",
            "session_id": "omp-019ff97e-ccb8-7000-a22f-d1a5791d3532",
            "_source": "omp",
            "tool_name": "Read"
        ])

        let lifecycleRoute = await MainActor.run { HookServer.routeKind(for: lifecycle) }
        let toolRoute = await MainActor.run { HookServer.routeKind(for: tool) }
        XCTAssertEqual(lifecycleRoute, .event)
        XCTAssertEqual(toolRoute, .event)
    }

    private func event(_ payload: [String: Any]) throws -> HookEvent {
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try XCTUnwrap(HookEvent(from: data))
    }
}
