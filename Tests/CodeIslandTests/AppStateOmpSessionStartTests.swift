import XCTest
@testable import CodeIsland
@testable import CodeIslandCore

@MainActor
final class AppStateOmpSessionStartTests: XCTestCase {
    func testLateOmpSessionStartPreservesPromptAndActiveTool() throws {
        let appState = AppState()
        let sessionId = "omp-019ff97e-ccb8-7000-a22f-d1a5791d3532"

        appState.handleEvent(try event(
            "UserPromptSubmit",
            sessionId: sessionId,
            extra: ["prompt": "Deploy the release"]
        ))
        appState.handleEvent(try event(
            "PreToolUse",
            sessionId: sessionId,
            extra: ["tool_name": "Bash", "tool_input": ["command": "git push"]]
        ))
        appState.handleEvent(try event(
            "SessionStart",
            sessionId: sessionId,
            extra: ["cwd": "/repo", "session_title": "Release"]
        ))

        XCTAssertEqual(appState.sessions[sessionId]?.status, .running)
        XCTAssertEqual(appState.sessions[sessionId]?.currentTool, "Bash")
        XCTAssertEqual(appState.sessions[sessionId]?.lastUserPrompt, "Deploy the release")
        XCTAssertEqual(appState.sessions[sessionId]?.cwd, "/repo")
        XCTAssertEqual(appState.sessions[sessionId]?.sessionTitle, "Release")
    }

    private func event(
        _ name: String,
        sessionId: String,
        extra: [String: Any] = [:]
    ) throws -> HookEvent {
        var payload: [String: Any] = [
            "hook_event_name": name,
            "session_id": sessionId,
            "_source": "omp",
        ]
        for (key, value) in extra {
            payload[key] = value
        }
        return try XCTUnwrap(HookEvent(from: JSONSerialization.data(withJSONObject: payload)))
    }
}
