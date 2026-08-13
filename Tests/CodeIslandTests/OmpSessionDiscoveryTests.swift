import XCTest
@testable import CodeIsland
import CodeIslandCore

@MainActor
final class OmpSessionDiscoveryTests: XCTestCase {
    func testFindActiveOmpSessionsNamespacesMetadataAndUsesRecentFiles() throws {
        let root = try makeOmpRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }

        let file = try writeOmpSession(
            under: root,
            filename: "2026-08-12T12-00-00Z_abc.jsonl",
            contents: validTranscript(id: "abc", cwd: "/tmp/project", title: "OMP task")
        )
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 10_000)],
            ofItemAtPath: file
        )

        let found = AppState.findActiveOmpSessions(
            base: root,
            now: Date(timeIntervalSince1970: 10_120),
            fileManager: .default
        )

        XCTAssertEqual(found.map(\.sessionId), ["omp-abc"])
        XCTAssertEqual(found.first?.source, "omp")
        XCTAssertEqual(found.first?.cwd, "/tmp/project")
        XCTAssertEqual(found.first?.sessionTitle, "OMP task")
        XCTAssertEqual(found.first?.status, .processing)
        XCTAssertEqual(found.first?.recentMessages.map(\.isUser), [true, false])
    }

    func testFindActiveOmpSessionsSkipsStaleAndIncompleteTranscripts() throws {
        let root = try makeOmpRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }

        let stale = try writeOmpSession(
            under: root,
            filename: "stale.jsonl",
            contents: validTranscript(id: "stale", cwd: "/tmp/stale", title: "Old task")
        )
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 9_819)],
            ofItemAtPath: stale
        )
        _ = try writeOmpSession(
            under: root,
            filename: "incomplete.jsonl",
            contents: #"{"type":"message","message":{"role":"user","content":[{"type":"text","text":"missing session"}]}}"#
        )

        let found = AppState.findActiveOmpSessions(
            base: root,
            now: Date(timeIntervalSince1970: 10_120),
            fileManager: .default
        )

        XCTAssertTrue(found.isEmpty)
    }

    func testOmpSessionsAreNotTerminalActivatable() {
        var session = SessionSnapshot()
        session.source = "omp"

        XCTAssertFalse(TerminalActivator.canActivate(session: session))
    }

    func testIntegratingOmpSessionsKeepsConcurrentSameCwdCards() {
        let appState = AppState()
        let now = Date(timeIntervalSince1970: 10_000)
        appState.integrateDiscovered([
            AppState.DiscoveredSession(
                sessionId: "omp-alpha",
                cwd: "/tmp/project",
                tty: nil,
                model: nil,
                pid: nil,
                modifiedAt: now,
                recentMessages: [],
                source: "omp",
                sessionTitle: "Alpha"
            ),
            AppState.DiscoveredSession(
                sessionId: "omp-beta",
                cwd: "/tmp/project",
                tty: nil,
                model: nil,
                pid: nil,
                modifiedAt: now,
                recentMessages: [],
                source: "omp",
                sessionTitle: "Beta"
            )
        ])

        XCTAssertEqual(appState.sessions.keys.sorted(), ["omp-alpha", "omp-beta"])
        XCTAssertEqual(appState.sessions["omp-alpha"]?.sessionTitle, "Alpha")
        XCTAssertEqual(appState.sessions["omp-beta"]?.sessionTitle, "Beta")
    }

    private func makeOmpRoot() throws -> String {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("OmpSessionDiscoveryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.path
    }

    private func writeOmpSession(under root: String, filename: String, contents: String) throws -> String {
        let directory = URL(fileURLWithPath: root).appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent(filename)
        try contents.write(to: file, atomically: true, encoding: .utf8)
        return file.path
    }

    private func validTranscript(id: String, cwd: String, title: String) -> String {
        [
            #"{"type":"session","id":"\#(id)","cwd":"\#(cwd)","title":"\#(title)"}"#,
            #"{"type":"message","message":{"role":"user","content":[{"type":"text","text":"inspect discovery"}]}}"#,
            #"{"type":"message","message":{"role":"assistant","content":[{"type":"text","text":"discovery is active"}]}}"#
        ].joined(separator: "\n")
    }
}
