import XCTest
@testable import CodeIslandCore

final class OmpTranscriptTests: XCTestCase {
    func testReadExtractsSessionMetadataAndSafeMessages() throws {
        let path = try writeFixture("""
        {"type":"title","title":"Ship OMP discovery"}
        {"type":"session","id":"019ff97e-ccb8-7000-a22f-d1a5791d3532","cwd":"/tmp/project"}
        {"type":"model_change","model":"openai-codex/gpt-5.6-terra"}
        {"type":"message","message":{"role":"user","content":[{"type":"text","text":"Add OMP support"}]}}
        {"type":"message","message":{"role":"assistant","content":[{"type":"thinking","thinking":"hidden"},{"type":"text","text":"I will add it."}]}}
        {"type":"custom","data":{"tool":"read","secret":"never preview"}}
        """)

        let snapshot = try XCTUnwrap(OmpTranscriptSnapshot.read(path: path))
        XCTAssertEqual(snapshot.sessionId, "019ff97e-ccb8-7000-a22f-d1a5791d3532")
        XCTAssertEqual(snapshot.cwd, "/tmp/project")
        XCTAssertEqual(snapshot.title, "Ship OMP discovery")
        XCTAssertEqual(snapshot.model, "openai-codex/gpt-5.6-terra")
        XCTAssertEqual(snapshot.recentMessages, [
            ChatMessage(isUser: true, text: "Add OMP support"),
            ChatMessage(isUser: false, text: "I will add it.")
        ])
    }

    func testReadIgnoresMalformedAndNonMessageRecords() throws {
        let path = try writeFixture("""
        not json
        {"type":"session","id":"omp-id","cwd":"/tmp/project"}
        {"type":"message","message":{"role":"tool","content":[{"type":"text","text":"do not show"}]}}
        {"type":"message","message":{"role":"assistant","content":[{"type":"toolCall","name":"bash"}]}}
        """)

        let snapshot = try XCTUnwrap(OmpTranscriptSnapshot.read(path: path))
        XCTAssertTrue(snapshot.recentMessages.isEmpty)
    }

    func testReadReturnsNilWithoutSessionMetadata() throws {
        let path = try writeFixture("{\"type\":\"message\",\"message\":{\"role\":\"user\",\"content\":[]}}")
        XCTAssertNil(OmpTranscriptSnapshot.read(path: path))
    }

    private func writeFixture(_ contents: String) throws -> String {
        let path = NSTemporaryDirectory() + "omp-transcript-\(UUID().uuidString).jsonl"
        try contents.write(toFile: path, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(atPath: path) }
        return path
    }
}
