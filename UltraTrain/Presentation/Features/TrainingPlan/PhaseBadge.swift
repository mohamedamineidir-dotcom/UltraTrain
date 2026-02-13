import SwiftUI

struct PhaseBadge: View {
    let phase: TrainingPhase

    var body: some View {
        Text(phase.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(phase.color)
            .clipShape(Capsule())
    }
}

extension TrainingPhase {
    var displayName: String {
        switch self {
        case .base:     "Base"
        case .build:    "Build"
        case .peak:     "Peak"
        case .taper:    "Taper"
        case .recovery: "Recovery"
        case .race:     "Race"
        }
    }

    var color: Color {
        switch self {
        case .base:     .blue
        case .build:    .orange
        case .peak:     .red
        case .taper:    .purple
        case .recovery: .green
        case .race:     .yellow
        }
    }
}
