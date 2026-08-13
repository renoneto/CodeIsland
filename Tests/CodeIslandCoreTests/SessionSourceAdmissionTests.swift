import XCTest
@testable import CodeIslandCore

final class SessionSourceAdmissionTests: XCTestCase {
    func testNormalizedSupportedSourceAcceptsOmp() {
        XCTAssertEqual(SessionSnapshot.normalizedSupportedSource("omp"), "omp")
        XCTAssertNil(SessionSnapshot.normalizedSupportedSource("cursor"))
    }
}
