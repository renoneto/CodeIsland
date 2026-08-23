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
        switch source {
        case "claude", "gemini": return source
        default: return "codex"
        }
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

/// Compact model-name label shown where sessions previously rendered a
/// provider/harness glyph. Falls back to the source name when the model is
/// unknown (hooks report `model` inconsistently across providers).
struct ModelNameLabel: View {
    let model: String?
    let fallback: String
    let status: AgentStatus
    var size: CGFloat = 11

    private var label: String {
        if let model, !model.isEmpty { return model }
        return fallback
    }

    private var color: Color {
        switch status {
        case .waitingApproval, .waitingQuestion: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .running, .processing: return Color(red: 0.3, green: 0.85, blue: 0.4)
        case .idle: return .white.opacity(0.55)
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: size, weight: .semibold, design: .monospaced))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .help(label)
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
