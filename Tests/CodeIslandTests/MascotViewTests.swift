import XCTest
@testable import CodeIsland
import CodeIslandCore

final class MascotViewTests: XCTestCase {
    func testStatusIconUsesCodexAndWaitingSymbols() {
        XCTAssertEqual(CodexStatusIcon.symbol(for: .running), "terminal.fill")
        XCTAssertEqual(CodexStatusIcon.symbol(for: .waitingApproval), "exclamationmark.triangle.fill")
    }
}
