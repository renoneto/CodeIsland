import AppKit
import SwiftUI
import CodeIslandCore

/// A static glyph keeps the notch informative without an animation scheduler.
struct CodexStatusIcon: View {
    let source: String
    let status: AgentStatus
    var size: CGFloat = 27

    static func symbol(for status: AgentStatus) -> String {
        switch status {
        case .waitingApproval, .waitingQuestion:
            return "exclamationmark.triangle.fill"
        case .running, .processing:
            return "terminal.fill"
        case .idle:
            return "terminal"
        }
    }

    static func assetName(for source: String) -> String {
        source == "claude" ? "claude" : "codex"
    }

    private var color: Color {
        switch status {
        case .waitingApproval, .waitingQuestion: return .orange
        case .running, .processing: return .green
        case .idle: return .secondary
        }
    }

    var body: some View {
        Group {
            if let url = Bundle.module.url(forResource: Self.assetName(for: source), withExtension: "png", subdirectory: "cli-icons"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: Self.symbol(for: status))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Compatibility wrapper for existing notch call sites.
struct MascotView: View {
    let source: String
    let status: AgentStatus
    var size: CGFloat = 27

    var body: some View {
        CodexStatusIcon(source: source, status: status, size: size)
    }
}
