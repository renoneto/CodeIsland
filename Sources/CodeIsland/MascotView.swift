import SwiftUI
import CodeIslandCore

/// A static glyph keeps the notch informative without an animation scheduler.
struct CodexStatusIcon: View {
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

    private var color: Color {
        switch status {
        case .waitingApproval, .waitingQuestion: return .orange
        case .running, .processing: return .green
        case .idle: return .secondary
        }
    }

    var body: some View {
        Image(systemName: Self.symbol(for: status))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .font(.system(size: size * 0.62, weight: .medium))
            .frame(width: size, height: size)
    }
}

/// Compatibility wrapper for existing notch call sites.
struct MascotView: View {
    let source: String
    let status: AgentStatus
    var size: CGFloat = 27

    var body: some View {
        CodexStatusIcon(status: status, size: size)
    }
}
