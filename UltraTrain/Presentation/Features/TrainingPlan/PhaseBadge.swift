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
        case .base:     String(localized: "phase.base", defaultValue: "Base")
        case .build:    String(localized: "phase.build", defaultValue: "Build")
        case .peak:     String(localized: "phase.peak", defaultValue: "Peak")
        case .taper:    String(localized: "phase.taper", defaultValue: "Taper")
        case .recovery: String(localized: "phase.recovery", defaultValue: "Recovery")
        case .race:     String(localized: "phase.race", defaultValue: "Race")
        }
    }

    var color: Color {
        switch self {
        case .base:     .blue
        case .build:    .orange
        case .peak:     .red
        case .taper:    .green
        case .recovery: .mint
        case .race:     .purple
        }
    }
}
