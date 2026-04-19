import SwiftUI

struct WorkoutBlockCard: View {
    let phase: IntervalPhase
    var easyPaceLabel: String?

    private var phaseColor: Color {
        switch phase.phaseType {
        case .warmUp:   .orange
        case .coolDown: .teal
        case .work:     phase.targetIntensity.color
        case .recovery: Theme.Colors.zone2
        }
    }

    private var phaseIcon: String {
        switch phase.phaseType {
        case .warmUp:   "flame"
        case .coolDown: "wind"
        case .work:     "bolt.fill"
        case .recovery: "leaf.fill"
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 3)
                .fill(phaseColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Image(systemName: phaseIcon)
                        .font(.caption2)
                        .foregroundStyle(phaseColor)
                        .shadow(color: phaseColor.opacity(0.4), radius: 3)
                    Text(phase.phaseType.displayName)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(durationText)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                if phase.repeatCount > 1 {
                    Text(repDescription)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                if let easyPaceLabel {
                    Text("\(String(localized: "workout.easyPace", defaultValue: "Easy pace")): \(easyPaceLabel)")
                        .font(.caption)
                        .foregroundStyle(phaseColor)
                }

                if let notes = phase.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(phaseColor.opacity(0.06))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .stroke(phaseColor.opacity(0.1), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }

    private var durationText: String {
        // For distance triggers, show total distance. For duration, show time.
        if case .distance(let km) = phase.trigger {
            let totalMeters = Int(km * 1000) * phase.repeatCount
            return totalMeters >= 1000
                ? String(format: "%.1fkm", Double(totalMeters) / 1000.0)
                : "\(totalMeters)m"
        }
        let totalSec = phase.totalDuration
        let mins = Int(totalSec) / 60
        if mins >= 60 {
            return "\(mins / 60)h\(String(format: "%02d", mins % 60))"
        }
        return "\(mins)min"
    }

    private var repDescription: String {
        switch phase.trigger {
        case .duration(let seconds):
            let perRep = Int(seconds) / 60
            let secRemainder = Int(seconds) % 60
            let repText = secRemainder > 0 ? "\(perRep)m\(secRemainder)s" : "\(perRep)min"
            return "\(repText) per rep at \(phase.targetIntensity.displayName)"
        case .distance(let km):
            let meters = Int(km * 1000)
            return "\(meters)m per rep at \(phase.targetIntensity.displayName)"
        }
    }
}
