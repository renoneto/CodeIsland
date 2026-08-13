import XCTest
@testable import CodeIsland

final class OmpExtensionContractTests: XCTestCase {
    private func packagedOmpExtensionSource() -> String? {
        let resource = Bundle.appModule
        let url = resource.url(forResource: "codeisland-omp", withExtension: "ts", subdirectory: "Resources")
            ?? resource.url(forResource: "codeisland-omp", withExtension: "ts")
        return url.flatMap { try? String(contentsOf: $0) }
    }

    func testOmpExtensionIsTelemetryOnly() throws {
        let source = try XCTUnwrap(packagedOmpExtensionSource())
        XCTAssertTrue(source.contains("_source: \"omp\""))
        XCTAssertTrue(source.contains("session_id: `omp-${sessionId}`"))
        XCTAssertFalse(source.contains("sendAndWaitResponse"))
        XCTAssertFalse(source.contains("PermissionRequest"))
        XCTAssertFalse(source.contains("forwardAskToCodeIsland"))
        XCTAssertFalse(source.contains("BRIDGE_PATH"))
    }

    func testOmpExtensionQueuesLifecycleTelemetryBeforeLaterEvents() throws {
        let source = try XCTUnwrap(packagedOmpExtensionSource())

        XCTAssertTrue(source.contains("const outboundTails = new Map<string, Promise<void>>();"))
        XCTAssertTrue(source.contains("function enqueueEvent(sessionId: string, payload: object): void"))
        XCTAssertTrue(source.contains("const previous = outboundTails.get(sessionId)?.catch(() => {}) ?? Promise.resolve();"))
        XCTAssertTrue(source.contains("const next = previous.then(() => sendToSocket(payload));"))
        XCTAssertTrue(source.contains("let serialized: string;"))
        XCTAssertTrue(source.contains("serialized = JSON.stringify(payload);"))
        XCTAssertTrue(source.contains("catch {\n    finish();\n    return promise;\n  }"))
        XCTAssertTrue(source.contains("enqueueEvent(sid, base(sessionId, cwd, {"))
        XCTAssertTrue(source.contains("enqueueEvent(`omp-${sessionId}`, base(sessionId, ctx.cwd, {"))
        XCTAssertFalse(source.contains("sendToSocket(base(sessionId, ctx.cwd"))
    }
}
