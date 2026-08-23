import XCTest
@testable import CodeIsland
import CodeIslandCore

@MainActor
final class OmpSubagentFoldingTests: XCTestCase {
    // MARK: - Path topology

    func testChildTranscriptPathDetection() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }

        let parentUUID = "019ff97e-ccb8-7000-a22f-d1a5791d3530"
        let parentFile = try writeTranscript(
            root: root,
            filename: "2026-08-23T040000Z_\(parentUUID).jsonl",
            id: parentUUID,
            cwd: "/tmp/project"
        )
        // Artifact dir shares the parent transcript's name minus extension.
        let artifactDir = URL(fileURLWithPath: parentFile).deletingPathExtension()
        try FileManager.default.createDirectory(at: artifactDir, withIntermediateDirectories: true)
        let childFile = artifactDir.appendingPathComponent("ReplyApprovalScout.jsonl")
        try validTranscript(id: "019ff97f-0000-7000-8000-000000000000", cwd: "/tmp/project")
            .write(to: childFile, atomically: true, encoding: .utf8)

        XCTAssertTrue(OmpSessionFolding.isChildTranscriptPath(childFile.path))
        XCTAssertFalse(OmpSessionFolding.isChildTranscriptPath(parentFile))
        // Project dirs without a matching <name>.jsonl transcript are not children.
        XCTAssertFalse(OmpSessionFolding.isChildTranscriptPath(
            URL(fileURLWithPath: root).appendingPathComponent("stray.jsonl").path
        ))
    }
    // MARK: - Parent header parsing

    func testParentSessionIdFromNestedChildPath() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }

        let parentUUID = "019ff97e-ccb8-7000-a22f-d1a5791d3532"
        let childUUID = "019ff97f-0000-7000-8000-000000000001"
        let parentFile = try writeTranscript(
            root: root,
            filename: "2026-08-23T040000Z_\(parentUUID).jsonl",
            id: parentUUID,
            cwd: "/tmp/project"
        )
        let artifactDir = URL(fileURLWithPath: parentFile).deletingPathExtension()
        try FileManager.default.createDirectory(at: artifactDir, withIntermediateDirectories: true)
        let childFile = artifactDir.appendingPathComponent("ReplyApprovalScout.jsonl")
        try validTranscript(id: childUUID, cwd: "/tmp/project").write(to: childFile, atomically: true, encoding: .utf8)

        XCTAssertEqual(
            OmpSessionFolding.parentSessionId(childPath: childFile.path),
            parentUUID
        )
        // Parent header id parse works standalone too.
        XCTAssertEqual(OmpSessionFolding.sessionId(fromHeaderOf: parentFile), parentUUID)
    }

    func testParentSessionIdReturnsNilForTopLevelTranscript() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }

        let file = try writeTranscript(
            root: root,
            filename: "solo.jsonl",
            id: "019ff97e-ccb8-7000-a22f-d1a5791d3533",
            cwd: "/tmp/project"
        )
        XCTAssertNil(OmpSessionFolding.parentSessionId(childPath: file))
    }

    // MARK: - Discovery flags children

    func testDiscoveryMarksNestedChildTranscripts() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }

        let parentUUID = "019ff97e-ccb8-7000-a22f-d1a5791d3534"
        let parentFile = try writeTranscript(
            root: root,
            filename: "2026-08-23T040000Z_\(parentUUID).jsonl",
            id: parentUUID,
            cwd: "/tmp/project"
        )
        let artifactDir = URL(fileURLWithPath: parentFile).deletingPathExtension()
        try FileManager.default.createDirectory(at: artifactDir, withIntermediateDirectories: true)
        let childFile = artifactDir.appendingPathComponent("ReplyApprovalScout.jsonl")
        try validTranscript(
            id: "019ff97f-0000-7000-8000-000000000002",
            cwd: "/tmp/project"
        ).write(to: childFile, atomically: true, encoding: .utf8)
        let recent = Date(timeIntervalSince1970: 10_000)
        for path in [parentFile, childFile.path] {
            try FileManager.default.setAttributes([.modificationDate: recent], ofItemAtPath: path)
        }

        let found = AppState.findActiveOmpSessions(
            base: root,
            now: Date(timeIntervalSince1970: 10_120),
            fileManager: .default
        )

        let child = found.first { $0.sessionId == "omp-019ff97f-0000-7000-8000-000000000002" }
        XCTAssertNotNil(child)
        XCTAssertEqual(child?.parentSessionId, parentUUID)
        XCTAssertEqual(child?.agentType, "omp-subagent")
        XCTAssertEqual(child?.agentNickname, "ReplyApprovalScout")

        let parent = found.first { $0.sessionId == "omp-\(parentUUID)" }
        XCTAssertNotNil(parent)
        XCTAssertNil(parent?.parentSessionId)
    }

    // MARK: - Integration folds children into the parent card

    func testIntegratingOmpChildFoldsIntoParentCard() {
        // Folding honors the Agent Sub-Sessions setting (default: separate).
        UserDefaults.standard.set("merge", forKey: SettingsKey.pluginSessionMode)
        defer { UserDefaults.standard.removeObject(forKey: SettingsKey.pluginSessionMode) }

        let appState = AppState()
        let now = Date(timeIntervalSince1970: 10_000)
        appState.integrateDiscovered([
            AppState.DiscoveredSession(
                sessionId: "omp-parent",
                cwd: "/tmp/project",
                tty: nil,
                model: nil,
                pid: nil,
                modifiedAt: now,
                recentMessages: [],
                source: "omp",
                sessionTitle: "Main"
            ),
            AppState.DiscoveredSession(
                sessionId: "omp-child",
                cwd: "/tmp/project",
                tty: nil,
                model: nil,
                pid: nil,
                modifiedAt: now,
                recentMessages: [],
                source: "omp",
                sessionTitle: "ReplyApprovalScout",
                parentSessionId: "parent",
                agentType: "omp-subagent",
                agentNickname: "ReplyApprovalScout"
            ),
        ])

        XCTAssertEqual(appState.sessions.keys.sorted(), ["omp-parent"])
        XCTAssertEqual(appState.sessions["omp-parent"]?.subagents["omp-child"]?.status, .running)
        XCTAssertEqual(appState.sessions["omp-parent"]?.subagents["omp-child"]?.agentType, "omp-subagent")
        XCTAssertEqual(appState.sessions["omp-parent"]?.status, .running)
    }

    // MARK: - Fixtures

    private func makeRoot() throws -> String {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("OmpSubagentFoldingTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.path
    }

    private func writeTranscript(root: String, filename: String, id: String, cwd: String) throws -> String {
        let file = URL(fileURLWithPath: root).appendingPathComponent(filename)
        try validTranscript(id: id, cwd: cwd).write(to: file, atomically: true, encoding: .utf8)
        return file.path
    }

    private func validTranscript(id: String, cwd: String) -> String {
        """
        {"type":"session","id":"\(id)","cwd":"\(cwd)"}
        {"type":"message","message":{"role":"user","content":[{"type":"text","text":"hello"}]}}
        """
    }
}
