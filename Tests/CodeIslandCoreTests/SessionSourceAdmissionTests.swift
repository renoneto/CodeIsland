import XCTest
@testable import CodeIslandCore

final class SessionSourceAdmissionTests: XCTestCase {
    func testNormalizedSupportedSourceAcceptsLeanProviderSet() {
        XCTAssertEqual(SessionSnapshot.normalizedSupportedSource("codex"), "codex")
        XCTAssertEqual(SessionSnapshot.normalizedSupportedSource("claude"), "claude")
        XCTAssertEqual(SessionSnapshot.normalizedSupportedSource("gemini"), "gemini")
        XCTAssertNil(SessionSnapshot.normalizedSupportedSource("cursor"))
    }
}
