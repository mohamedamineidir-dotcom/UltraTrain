import SwiftUI

struct DashboardFinishEstimateCard: View {
    let estimate: FinishEstimate
    let race: Race

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Race Estimate")
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .accessibilityHidden(true)
            }

            Text(race.name)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            HStack(spacing: Theme.Spacing.md) {
                scenarioColumn(
                    time: FinishEstimate.formatDuration(estimate.optimisticTime),
                    label: "Best",
                    color: Theme.Colors.success,
                    font: .caption
                )
                scenarioColumn(
                    time: estimate.expectedTimeFormatted,
                    label: "Expected",
                    color: Theme.Colors.primary,
                    font: .title2.bold()
                )
                scenarioColumn(
                    time: FinishEstimate.formatDuration(estimate.conservativeTime),
                    label: "Safe",
                    color: Theme.Colors.warning,
                    font: .caption
                )
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: Theme.Spacing.xs) {
                ProgressView(value: estimate.confidencePercent, total: 100)
                    .tint(Theme.Colors.primary)
                Text("\(Int(estimate.confidencePercent))%")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .cardStyle()
    }

    private func scenarioColumn(time: String, label: String, color: Color, font: Font) -> some View {
        VStack(spacing: 2) {
            Text(time)
                .font(font)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}
