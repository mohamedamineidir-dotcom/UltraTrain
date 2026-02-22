import SwiftUI

struct IntervalPhaseRow: View {
    let phase: IntervalPhase

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: phase.phaseType.iconName)
                .font(.title3)
                .foregroundStyle(phaseColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(phase.phaseType.displayName)
                    .font(.subheadline.weight(.semibold))

                Text(phase.trigger.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(phase.targetIntensity.rawValue.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(intensityColor)

                if phase.repeatCount > 1 {
                    Text("x\(phase.repeatCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var phaseColor: Color {
        switch phase.phaseType {
        case .warmUp: return .orange
        case .work: return .red
        case .recovery: return .blue
        case .coolDown: return .green
        }
    }

    private var intensityColor: Color {
        switch phase.targetIntensity {
        case .easy: return .green
        case .moderate: return .yellow
        case .hard: return .orange
        case .maxEffort: return .red
        }
    }
}
