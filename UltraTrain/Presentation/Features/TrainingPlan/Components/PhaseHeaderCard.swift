import SwiftUI

struct PhaseHeaderCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let phase: TrainingPhase
    let weekRange: String
    let completedWeeks: Int
    let totalWeeks: Int
    let description: String
    var phaseFocus: PhaseFocus?

    var body: some View {
        HStack(spacing: 0) {
            // Phase accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [phase.color, phase.color.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .shadow(color: phase.color.opacity(0.3), radius: 3, x: 2)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    // Icon with glow
                    ZStack {
                        Circle()
                            .fill(phase.color.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: phaseIcon)
                            .font(.caption.bold())
                            .foregroundStyle(phase.color)
                    }
                    .shadow(color: phase.color.opacity(0.3), radius: 4)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(focusDisplayName.uppercased())
                            .font(.caption.bold())
                            .tracking(Theme.LetterSpacing.tracked)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [phase.color, phase.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text(weekRange)
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }

                    Spacer()

                    // Completion ring + label
                    HStack(spacing: 6) {
                        completionRing
                        Text("\(completedWeeks)/\(totalWeeks)")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }

                // Description
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .lineLimit(2)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(phaseBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(phase.color.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(focusDisplayName) phase, \(weekRange), \(completedWeeks) of \(totalWeeks) weeks completed")
    }

    private var focusDisplayName: String {
        phaseFocus?.displayName ?? phase.displayName
    }

    private var phaseIcon: String {
        switch phase {
        case .base:     return "figure.walk"
        case .build:    return "flame.fill"
        case .peak:     return "bolt.fill"
        case .taper:    return "leaf.fill"
        case .recovery: return "heart.fill"
        case .race:     return "flag.fill"
        }
    }

    private var phaseBackground: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
            .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [phase.color.opacity(0.08), phase.color.opacity(0.02)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }

    private var completionRing: some View {
        let fraction = totalWeeks > 0 ? Double(completedWeeks) / Double(totalWeeks) : 0
        return ZStack {
            Circle()
                .stroke(phase.color.opacity(0.15), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(phase.color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: phase.color.opacity(0.4), radius: 3)
        }
        .frame(width: 20, height: 20)
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
