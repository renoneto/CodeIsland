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
}
