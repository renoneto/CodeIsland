import Foundation

/// Maps Oh My Pi subagent transcripts onto their parent session.
///
/// omp writes each session transcript as `<sessionsRoot>/<project>/<session>.jsonl`
/// and nests transcripts spawned by an agent (subagents) inside a sibling
/// artifact directory named after the parent transcript minus its extension:
/// `<sessionsRoot>/<project>/<parent>/<child>.jsonl`. Without folding, every
/// child appears as a duplicate card for the same project.
public enum OmpSessionFolding {
    /// True when `path` sits inside a `<parent>/` artifact directory whose
    /// matching `<parent>.jsonl` transcript exists.
    public static func isChildTranscriptPath(_ path: String, fileManager: FileManager = .default) -> Bool {
        parentTranscriptPath(forChildPath: path, fileManager: fileManager) != nil
    }

    /// Transcript path of the parent session for a nested child transcript;
    /// nil when `path` is not a child transcript.
    public static func parentTranscriptPath(
        forChildPath path: String,
        fileManager: FileManager = .default
    ) -> String? {
        let dir = (path as NSString).deletingLastPathComponent
        guard (path as NSString).lastPathComponent.hasSuffix(".jsonl") else { return nil }
        let parentPath = dir + ".jsonl"
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: parentPath, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            return nil
        }
        return parentPath
    }

    /// Native parent session id (UUID from the parent transcript's session
    /// header) for a nested child transcript; nil when `path` is not a child
    /// or the parent header cannot be read.
    public static func parentSessionId(
        childPath: String,
        fileManager: FileManager = .default
    ) -> String? {
        guard let parentPath = parentTranscriptPath(forChildPath: childPath, fileManager: fileManager) else {
            return nil
        }
        return sessionId(fromHeaderOf: parentPath, fileManager: fileManager)
    }

    /// Parse the session id from a transcript's `session` header record
    /// without decoding the whole file — only the leading bytes are read,
    /// and the walk stops at the first `session` record.
    public static func sessionId(
        fromHeaderOf path: String,
        fileManager: FileManager = .default
    ) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)) else {
            return nil
        }
        defer { try? handle.close() }
        var head = Data()
        // The session header is written first; a few 64 KiB chunks are ample.
        for _ in 0..<3 {
            let chunk = handle.readData(ofLength: 64 * 1024)
            if chunk.isEmpty { break }
            head.append(chunk)
            if let id = sessionId(inHeaderBytes: head) { return id }
        }
        return nil
    }

    /// Extract the session id from complete lines within `data`.
    static func sessionId(inHeaderBytes data: Data) -> String? {
        guard let contents = String(data: data, encoding: .utf8) else { return nil }
        for line in contents.split(whereSeparator: \.isNewline) {
            guard let record = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                  record["type"] as? String == "session",
                  let id = record["id"] as? String,
                  UUID(uuidString: id) != nil else {
                continue
            }
            return id
        }
        return nil
    }
}
