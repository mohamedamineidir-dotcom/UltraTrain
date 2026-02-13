import SwiftUI

struct SessionRowView: View {
    let session: TrainingSession
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Button(action: onToggle) {
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(session.isCompleted ? Theme.Colors.success : Theme.Colors.secondaryLabel)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Image(systemName: session.type.icon)
                .foregroundStyle(session.intensity.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(session.isCompleted)

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
        .opacity(session.type == .rest ? 0.5 : 1.0)
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
