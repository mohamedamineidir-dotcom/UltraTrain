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

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 3)
                .fill(phaseColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
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
        .background(phaseColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }

    private var durationText: String {
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
            return "\(phase.repeatCount) × \(repText) at \(phase.targetIntensity.displayName)"
        case .distance(let km):
            return "\(phase.repeatCount) × \(String(format: "%.1f", km))km"
        }
    }
}
