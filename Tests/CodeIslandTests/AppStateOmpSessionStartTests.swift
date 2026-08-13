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
    func testDiscoveryAfterOmpStopMergesOnlyMetadata() throws {
        let appState = AppState()
        let sessionId = "omp-019ff97e-ccb8-7000-a22f-d1a5791d3532"
        appState.handleEvent(try event(
            "UserPromptSubmit",
            sessionId: sessionId,
            extra: ["prompt": "Ship telemetry"]
        ))
        appState.handleEvent(try event("Stop", sessionId: sessionId))

        appState.integrateDiscovered([discoveredSession(sessionId: sessionId)])

        XCTAssertEqual(appState.sessions[sessionId]?.status, .idle)
        XCTAssertNil(appState.sessions[sessionId]?.currentTool)
        XCTAssertEqual(appState.sessions[sessionId]?.lastUserPrompt, "Ship telemetry")
        XCTAssertEqual(appState.sessions[sessionId]?.sessionTitle, "Discovery title")
        XCTAssertEqual(appState.sessions[sessionId]?.cwd, "/discovered")
    }

    func testDiscoveryDoesNotRecreateOmpSessionEndedByTelemetry() throws {
        let appState = AppState()
        let sessionId = "omp-019ff97e-ccb8-7000-a22f-d1a5791d3532"
        appState.handleEvent(try event("SessionStart", sessionId: sessionId))
        appState.handleEvent(try event("SessionEnd", sessionId: sessionId))
        XCTAssertNil(appState.sessions[sessionId])

        appState.handleEvent(try event("SessionStart", sessionId: sessionId))
        XCTAssertNil(appState.sessions[sessionId])

        appState.handleEvent(try event("PreToolUse", sessionId: sessionId))
        appState.handleEvent(try event(
            "UserPromptSubmit",
            sessionId: sessionId,
            extra: ["prompt": "delayed"]
        ))
        XCTAssertNil(appState.sessions[sessionId])
        appState.integrateDiscovered([discoveredSession(sessionId: sessionId)])

        XCTAssertNil(appState.sessions[sessionId])
    }

    private func discoveredSession(sessionId: String) -> AppState.DiscoveredSession {
        AppState.DiscoveredSession(
            sessionId: sessionId,
            cwd: "/discovered",
            tty: nil,
            model: "omp-model",
            pid: nil,
            modifiedAt: Date(),
            recentMessages: [ChatMessage(isUser: true, text: "discovered prompt")],
            source: "omp",
            sessionTitle: "Discovery title"
        )
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
