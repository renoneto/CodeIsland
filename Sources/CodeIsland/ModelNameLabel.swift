import SwiftUI
import CodeIslandCore

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

