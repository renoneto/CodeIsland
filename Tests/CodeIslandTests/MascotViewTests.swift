import XCTest
@testable import CodeIsland
import CodeIslandCore

final class MascotViewTests: XCTestCase {
    func testStaticIconUsesCodexAndClaudeAssets() {
        XCTAssertEqual(CodexStatusIcon.assetName(for: "codex"), "codex")
        XCTAssertEqual(CodexStatusIcon.assetName(for: "claude"), "claude")
    }

    func testStatusIconUsesCodexAndWaitingSymbols() {
        XCTAssertEqual(CodexStatusIcon.symbol(for: .running), "terminal.fill")
        XCTAssertEqual(CodexStatusIcon.symbol(for: .waitingApproval), "exclamationmark.triangle.fill")
    }
}
