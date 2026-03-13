import SwiftUI

struct PhaseHeaderCard: View {
    let phase: TrainingPhase
    let weekRange: String
    let completedWeeks: Int
    let totalWeeks: Int
    let description: String

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
                .frame(width: 4)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(phase.displayName.uppercased())
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
                .fill(phase.color.opacity(0.06))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(phase.displayName) phase, \(weekRange), \(completedWeeks) of \(totalWeeks) weeks completed")
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

    static func description(for phase: TrainingPhase) -> String {
        switch phase {
        case .base:
            "Hill threshold foundation — 30-minute tempo efforts on hills"
        case .build:
            "Race-specific intensity with progressive long runs and B2Bs"
        case .peak:
            "Race simulation and final sharpening"
        case .taper:
            "Volume reduction, freshness for race day"
        case .recovery:
            "Active recovery and adaptation"
        case .race:
            "Race week"
        }
    }
}
