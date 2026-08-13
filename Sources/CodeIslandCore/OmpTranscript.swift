import Foundation

public struct OmpTranscriptSnapshot: Sendable, Equatable {
    public let sessionId: String
    public let cwd: String
    public let title: String?
    public let model: String?
    public let recentMessages: [ChatMessage]

    public static func read(path: String, fileManager: FileManager = .default) -> OmpTranscriptSnapshot? {
        guard let data = fileManager.contents(atPath: path),
              let contents = String(data: data, encoding: .utf8) else {
            return nil
        }

        var sessionId: String?
        var cwd: String?
        var title: String?
        var model: String?
        var messages: [ChatMessage] = []

        for line in contents.split(whereSeparator: \.isNewline) {
            guard let record = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                  let type = record["type"] as? String else {
                continue
            }

            switch type {
            case "session":
                guard let recordSessionId = nonEmptyString(record["id"]),
                      UUID(uuidString: recordSessionId) != nil,
                      let recordCwd = nonEmptyString(record["cwd"]) else {
                    continue
                }
                sessionId = recordSessionId
                cwd = recordCwd
                if let recordTitle = nonEmptyString(record["title"]) {
                    title = recordTitle
                }
            case "title", "title_change":
                if let recordTitle = nonEmptyString(record["title"]) {
                    title = recordTitle
                }
            case "model_change":
                if let recordModel = nonEmptyString(record["model"]) {
                    model = recordModel
                }
            case "message":
                guard let message = record["message"] as? [String: Any],
                      let role = message["role"] as? String,
                      let isUser = messageRole(role),
                      let text = textContent(message["content"]) else {
                    continue
                }
                messages.append(ChatMessage(isUser: isUser, text: text))
            default:
                continue
            }
        }

        guard let sessionId, let cwd else { return nil }
        return OmpTranscriptSnapshot(
            sessionId: sessionId,
            cwd: cwd,
            title: title,
            model: model,
            recentMessages: Array(messages.suffix(3))
        )
    }

    private static func nonEmptyString(_ value: Any?) -> String? {
        guard let value = value as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func messageRole(_ role: String) -> Bool? {
        switch role {
        case "user":
            return true
        case "assistant":
            return false
        default:
            return nil
        }
    }

    private static func textContent(_ content: Any?) -> String? {
        guard let parts = content as? [[String: Any]] else { return nil }
        let textParts = parts.compactMap { part -> String? in
            guard (part["type"] as? String) == "text" else { return nil }
            return nonEmptyString(part["text"])
        }
        return textParts.isEmpty ? nil : textParts.joined(separator: "\n")
    }
}

extension ChatMessage: Equatable {
    public static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.isUser == rhs.isUser && lhs.text == rhs.text
    }
}
