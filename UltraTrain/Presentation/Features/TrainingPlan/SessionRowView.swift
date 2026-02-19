import SwiftUI

struct SessionRowView: View {
    let session: TrainingSession
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Button(action: onToggle) {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Image(systemName: session.type.icon)
                .foregroundStyle(session.isSkipped ? Theme.Colors.secondaryLabel : session.intensity.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(session.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(session.isCompleted || session.isSkipped)

                    if session.isSkipped {
                        Text("Skipped")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    if session.isGutTrainingRecommended && !session.isSkipped {
                        GutTrainingBadge()
                    }
                }

                if session.plannedDistanceKm > 0 {
                    Text("\(session.plannedDistanceKm, specifier: "%.1f") km")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            Spacer()

            Text(session.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .opacity(session.type == .rest || session.isSkipped ? 0.5 : 1.0)
    }

    private var statusIcon: String {
        if session.isCompleted { return "checkmark.circle.fill" }
        if session.isSkipped { return "forward.circle.fill" }
        return "circle"
    }

    private var statusColor: Color {
        if session.isCompleted { return Theme.Colors.success }
        if session.isSkipped { return .orange }
        return Theme.Colors.secondaryLabel
    }
}

extension SessionType {
    var displayName: String {
        switch self {
        case .longRun:       "Long Run"
        case .tempo:         "Tempo"
        case .intervals:     "Intervals"
        case .verticalGain:  "Vertical Gain"
        case .backToBack:    "Back-to-Back"
        case .recovery:      "Recovery"
        case .crossTraining: "Cross-Training"
        case .rest:          "Rest"
        }
    }

    var icon: String {
        switch self {
        case .longRun:       "figure.run"
        case .tempo:         "speedometer"
        case .intervals:     "timer"
        case .verticalGain:  "mountain.2.fill"
        case .backToBack:    "arrow.triangle.2.circlepath"
        case .recovery:      "heart.fill"
        case .crossTraining: "figure.mixed.cardio"
        case .rest:          "bed.double.fill"
        }
    }
}

extension Intensity {
    var color: Color {
        switch self {
        case .easy:      Theme.Colors.zone2
        case .moderate:  Theme.Colors.zone3
        case .hard:      Theme.Colors.zone4
        case .maxEffort: Theme.Colors.zone5
        }
    }

    var displayName: String {
        switch self {
        case .easy:      "Easy"
        case .moderate:  "Moderate"
        case .hard:      "Hard"
        case .maxEffort: "Max Effort"
        }
    }
}
