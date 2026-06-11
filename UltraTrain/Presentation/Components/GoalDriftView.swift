import SwiftUI

// MARK: - Level presentation

extension GoalDriftAssessment.Level {

    /// Short headline shown on the badge.
    var title: String {
        switch self {
        case .veryAmbitious:   return String(localized: "goalDrift.title.veryAmbitious", defaultValue: "Ambitious goal")
        case .ambitious:       return String(localized: "goalDrift.title.ambitious", defaultValue: "Stretch goal")
        case .onTrack:         return String(localized: "goalDrift.title.onTrack", defaultValue: "On track")
        case .comfortable:     return String(localized: "goalDrift.title.comfortable", defaultValue: "Room to push")
        case .wellWithinReach: return String(localized: "goalDrift.title.aimHigher", defaultValue: "Aim higher")
        }
    }

    var icon: String {
        switch self {
        case .veryAmbitious:   return "exclamationmark.triangle.fill"
        case .ambitious:       return "flag.fill"
        case .onTrack:         return "checkmark.circle.fill"
        case .comfortable:     return "arrow.up.circle.fill"
        case .wellWithinReach: return "arrow.up.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .veryAmbitious, .ambitious: return Theme.Colors.warning
        case .onTrack:                   return Theme.Colors.success
        case .comfortable, .wellWithinReach: return Theme.Colors.accentColor
        }
    }
}

extension GoalDriftAssessment.Assessment {

    private func time(_ value: TimeInterval, raceDistanceKm: Double) -> String {
        FinishEstimate.formatDuration(value, raceDistanceKm: raceDistanceKm)
    }

    /// One-line caption for the compact dashboard flag.
    func shortMessage(raceDistanceKm: Double) -> String {
        let goal = time(goalTime, raceDistanceKm: raceDistanceKm)
        let pred = time(predictedTime, raceDistanceKm: raceDistanceKm)
        switch level {
        case .veryAmbitious:   return String(localized: "goalDrift.short.veryAmbitious", defaultValue: "Goal \(goal) is well ahead of your \(pred) prediction")
        case .ambitious:       return String(localized: "goalDrift.short.ambitious", defaultValue: "Goal \(goal) is a stretch vs your \(pred) prediction")
        case .onTrack:         return String(localized: "goalDrift.short.onTrack", defaultValue: "Goal \(goal) matches your \(pred) prediction")
        case .comfortable:     return String(localized: "goalDrift.short.comfortable", defaultValue: "Goal \(goal) is easier than your \(pred) prediction")
        case .wellWithinReach: return String(localized: "goalDrift.short.wellWithinReach", defaultValue: "Goal \(goal) sits well inside your \(pred) prediction")
        }
    }

    /// Fuller explanation for the actionable card on the detail screen.
    func fullMessage(raceDistanceKm: Double) -> String {
        let goal = time(goalTime, raceDistanceKm: raceDistanceKm)
        let pred = time(predictedTime, raceDistanceKm: raceDistanceKm)
        switch level {
        case .veryAmbitious:
            return String(localized: "goalDrift.full.veryAmbitious", defaultValue: "Your goal of \(goal) is well ahead of your predicted \(pred). Keep building, or set a target that matches your current fitness.")
        case .ambitious:
            return String(localized: "goalDrift.full.ambitious", defaultValue: "Your goal of \(goal) is a little faster than your predicted \(pred). It is within reach if your training keeps trending up.")
        case .onTrack:
            return String(localized: "goalDrift.full.onTrack", defaultValue: "Your goal of \(goal) lines up with your predicted \(pred). Stay the course.")
        case .comfortable:
            return String(localized: "goalDrift.full.comfortable", defaultValue: "Your goal of \(goal) is a touch easier than your predicted \(pred). You have room to aim faster.")
        case .wellWithinReach:
            return String(localized: "goalDrift.full.wellWithinReach", defaultValue: "Your goal of \(goal) sits well inside your predicted \(pred). Consider a faster, more motivating target.")
        }
    }
}

// MARK: - Compact flag (dashboard card)

/// One-line goal reality flag, sized to sit inside the dashboard finish card.
struct GoalDriftFlagRow: View {
    let assessment: GoalDriftAssessment.Assessment
    let raceDistanceKm: Double

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: assessment.level.icon)
                .font(.caption2)
                .foregroundStyle(assessment.level.tint)
            Text(assessment.shortMessage(raceDistanceKm: raceDistanceKm))
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Actionable card (finish-estimation detail)

/// Full goal reality check with a one-tap "adjust my goal" action when the
/// drift is large enough to warrant a new target.
struct GoalDriftCard: View {
    let assessment: GoalDriftAssessment.Assessment
    let raceDistanceKm: Double
    /// Invoked with the suggested realistic time when the athlete taps adjust.
    var onAdjust: ((TimeInterval) -> Void)? = nil
    /// True while the re-estimate runs after an adjustment.
    var isAdjusting: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: assessment.level.icon)
                    .foregroundStyle(assessment.level.tint)
                Text(assessment.level.title)
                    .font(.headline)
                Spacer()
            }

            Text(assessment.fullMessage(raceDistanceKm: raceDistanceKm))
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            if assessment.suggestsAdjustment, let onAdjust {
                Button {
                    onAdjust(assessment.suggestedTime)
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        if isAdjusting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "target")
                        }
                        Text(String(localized: "goalDrift.setGoal", defaultValue: "Set goal to \(FinishEstimate.formatDuration(assessment.suggestedTime, raceDistanceKm: raceDistanceKm))"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(assessment.level.tint)
                .disabled(isAdjusting)
                .accessibilityIdentifier("finishEstimate.adjustGoalButton")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
