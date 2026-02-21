import SwiftUI

struct DashboardGoalProgressCard: View {
    @Environment(\.unitPreference) private var units
    let weeklyProgress: GoalProgress?
    let monthlyProgress: GoalProgress?
    let onSetGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(Theme.Colors.primary)
                Text("Goals")
                    .font(.headline)
                Spacer()
                Button {
                    onSetGoal()
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.primary)
                }
            }

            if let weekly = weeklyProgress {
                goalRow(label: "Weekly", progress: weekly)
            }

            if let monthly = monthlyProgress {
                goalRow(label: "Monthly", progress: monthly)
            }

            if weeklyProgress == nil && monthlyProgress == nil {
                Button {
                    onSetGoal()
                } label: {
                    Text("Set a training goal")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                }
                .buttonStyle(.bordered)
            }
        }
        .cardStyle()
    }

    // MARK: - Goal Row

    private func goalRow(label: String, progress: GoalProgress) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)

            HStack(spacing: Theme.Spacing.md) {
                if progress.goal.targetDistanceKm != nil {
                    metricRing(
                        percent: progress.distancePercent,
                        actual: UnitFormatter.formatDistance(progress.actualDistanceKm, unit: units, decimals: 1),
                        target: UnitFormatter.formatDistance(progress.goal.targetDistanceKm!, unit: units, decimals: 0),
                        label: UnitFormatter.distanceLabel(units)
                    )
                }

                if progress.goal.targetElevationM != nil {
                    metricRing(
                        percent: progress.elevationPercent,
                        actual: UnitFormatter.formatElevation(progress.actualElevationM, unit: units),
                        target: UnitFormatter.formatElevation(progress.goal.targetElevationM!, unit: units),
                        label: "D+"
                    )
                }

                if progress.goal.targetRunCount != nil {
                    metricRing(
                        percent: progress.runCountPercent,
                        actual: "\(progress.actualRunCount)",
                        target: "\(progress.goal.targetRunCount!)",
                        label: "runs"
                    )
                }

                if progress.goal.targetDurationSeconds != nil {
                    metricRing(
                        percent: progress.durationPercent,
                        actual: formatDuration(progress.actualDurationSeconds),
                        target: formatDuration(progress.goal.targetDurationSeconds!),
                        label: "time"
                    )
                }
            }
        }
    }

    // MARK: - Metric Ring

    private func metricRing(percent: Double, actual: String, target: String, label: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(Theme.Colors.secondaryLabel.opacity(0.2), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: percent)
                    .stroke(ringColor(percent), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: percent)

                Text("\(Int(percent * 100))%")
                    .font(.system(.caption2, design: .rounded).bold())
            }
            .frame(width: 44, height: 44)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Text("\(actual)/\(target)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func ringColor(_ percent: Double) -> Color {
        if percent >= 0.8 { return Theme.Colors.success }
        if percent >= 0.5 { return Theme.Colors.warning }
        return Theme.Colors.primary
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(minutes)m"
    }
}
