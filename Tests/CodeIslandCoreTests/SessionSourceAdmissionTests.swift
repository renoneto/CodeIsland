import XCTest
@testable import CodeIslandCore

final class SessionSourceAdmissionTests: XCTestCase {
    func testNormalizedSupportedSourceAcceptsOnlyCodex() {
        XCTAssertEqual(SessionSnapshot.normalizedSupportedSource("codex"), "codex")
        XCTAssertNil(SessionSnapshot.normalizedSupportedSource("claude"))
        XCTAssertNil(SessionSnapshot.normalizedSupportedSource("gemini"))
    }
}
