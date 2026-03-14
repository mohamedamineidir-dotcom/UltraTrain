import SwiftUI

struct PhaseHeaderCard: View {
    let phase: TrainingPhase
    let weekRange: String
    let completedWeeks: Int
    let totalWeeks: Int
    let description: String
    var phaseFocus: PhaseFocus?

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [phase.color.opacity(0.8), phase.color],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 5)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Image(systemName: phaseIcon)
                        .font(.caption)
                        .foregroundStyle(phase.color)

                    Text(focusDisplayName.uppercased())
                        .font(.subheadline.bold())
                        .tracking(1.2)
                        .foregroundStyle(phase.color)

                    Spacer()

                    Text(weekRange)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                HStack {
                    completionRing
                    Text("\(completedWeeks)/\(totalWeeks) weeks")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .lineLimit(2)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [phase.color.opacity(0.04), phase.color.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(focusDisplayName) phase, \(weekRange), \(completedWeeks) of \(totalWeeks) weeks completed")
    }

    private var focusDisplayName: String {
        phaseFocus?.displayName ?? phase.displayName
    }

    private var phaseIcon: String {
        switch phase {
        case .base:     "figure.walk"
        case .build:    "flame.fill"
        case .peak:     "bolt.fill"
        case .taper:    "leaf.fill"
        case .recovery: "heart.fill"
        case .race:     "flag.fill"
        }
    }

    private var completionRing: some View {
        let fraction = totalWeeks > 0 ? Double(completedWeeks) / Double(totalWeeks) : 0
        return ZStack {
            Circle()
                .stroke(phase.color.opacity(0.2), lineWidth: 2)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(phase.color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 14, height: 14)
    }

    static func description(for phase: TrainingPhase, focus: PhaseFocus? = nil) -> String {
        if let focus {
            return focus.shortDescription
        }
        switch phase {
        case .base:
            return "Hill threshold foundation — 30-minute tempo efforts on hills"
        case .build:
            return "VO2max intervals on steep climbs — short, intense hill repeats"
        case .peak:
            return "Sustained threshold on rolling terrain — race-specific endurance"
        case .taper:
            return "Volume reduction, freshness for race day"
        case .recovery:
            return "Active recovery and adaptation"
        case .race:
            return "Race week"
        }
    }
}
