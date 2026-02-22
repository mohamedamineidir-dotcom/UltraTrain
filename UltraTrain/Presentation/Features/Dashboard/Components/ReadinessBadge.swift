import SwiftUI

struct ReadinessBadge: View {
    let score: Int
    let status: ReadinessStatus

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text("\(status.displayLabel) \(score)")
                .font(.caption.bold())
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.12))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Readiness: \(status.displayLabel), score \(score)")
    }

    private var statusColor: Color {
        switch status {
        case .primed: Theme.Colors.success
        case .ready: Theme.Colors.primary
        case .moderate: Theme.Colors.warning
        case .fatigued: .orange
        case .needsRest: Theme.Colors.danger
        }
    }
}

private extension ReadinessStatus {
    var displayLabel: String {
        switch self {
        case .primed: "Primed"
        case .ready: "Ready"
        case .moderate: "Moderate"
        case .fatigued: "Fatigued"
        case .needsRest: "Rest"
        }
    }
}
