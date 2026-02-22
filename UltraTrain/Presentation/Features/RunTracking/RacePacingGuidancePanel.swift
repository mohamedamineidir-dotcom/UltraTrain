import SwiftUI

struct RacePacingGuidancePanel: View {
    @Environment(\.unitPreference) private var units
    let guidance: RacePacingGuidance

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            segmentHeader
            Divider()
            paceComparison
            HStack(spacing: Theme.Spacing.md) {
                timeBudget
                projectedFinish
            }
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let target = formatPace(guidance.targetPaceSecondsPerKm)
        let current = formatPace(guidance.currentPaceSecondsPerKm)
        let remaining = UnitFormatter.formatDistance(guidance.segmentDistanceRemainingKm, unit: units, decimals: 1)
        let scenario = guidance.projectedFinishScenario == .aheadOfPlan ? "ahead of plan" :
            guidance.projectedFinishScenario == .behindPlan ? "behind plan" : "on plan"
        return "Pacing guidance for \(guidance.currentSegmentName). Target pace \(target), current pace \(current). \(remaining) remaining. \(scenario)."
    }

    // MARK: - Segment Header

    private var segmentHeader: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(guidance.currentSegmentName)
                .font(.caption.bold())
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(1)
            Spacer()
            Text(guidance.pacingZone.label)
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, 2)
                .background(guidance.pacingZone.color)
                .clipShape(Capsule())
        }
    }

    // MARK: - Pace Comparison

    private var paceComparison: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(spacing: 2) {
                Text("Target")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(formatPace(guidance.targetPaceSecondsPerKm))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Theme.Colors.primary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text("Current")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(formatPace(guidance.currentPaceSecondsPerKm))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(currentPaceColor)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text("Remaining")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(UnitFormatter.formatDistance(guidance.segmentDistanceRemainingKm, unit: units, decimals: 1))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Theme.Colors.label)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Time Budget

    private var timeBudget: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "timer")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text(formatDuration(guidance.segmentTimeBudgetRemaining))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.Colors.label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Projected Finish

    private var projectedFinish: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: scenarioIcon)
                .font(.caption2)
                .foregroundStyle(scenarioColor)
                .accessibilityHidden(true)
            Text(FinishEstimate.formatDuration(guidance.projectedFinishTime))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(scenarioColor)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Helpers

    private var currentPaceColor: Color {
        let deviation = abs(guidance.currentPaceSecondsPerKm - guidance.targetPaceSecondsPerKm)
            / guidance.targetPaceSecondsPerKm
        if deviation <= 0.05 { return Theme.Colors.success }
        if deviation <= 0.15 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }

    private var scenarioIcon: String {
        switch guidance.projectedFinishScenario {
        case .aheadOfPlan: "arrow.up.right"
        case .onPlan: "equal"
        case .behindPlan: "arrow.down.right"
        }
    }

    private var scenarioColor: Color {
        switch guidance.projectedFinishScenario {
        case .aheadOfPlan: Theme.Colors.success
        case .onPlan: Theme.Colors.primary
        case .behindPlan: Theme.Colors.danger
        }
    }

    private func formatPace(_ secondsPerKm: Double) -> String {
        RunStatisticsCalculator.formatPace(secondsPerKm, unit: units)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
