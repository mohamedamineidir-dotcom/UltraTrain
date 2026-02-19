import SwiftUI

struct RunHistorySummaryHeader: View {
    @Environment(\.unitPreference) private var units
    let runCount: Int
    let totalDistanceKm: Double
    let totalElevationM: Double
    let totalDuration: TimeInterval

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            summaryItem(title: "Runs", value: "\(runCount)", icon: "figure.run")
            Divider().frame(height: 32)
            summaryItem(
                title: "Distance",
                value: UnitFormatter.formatDistance(totalDistanceKm, unit: units),
                icon: "arrow.left.arrow.right"
            )
            Divider().frame(height: 32)
            summaryItem(
                title: "D+",
                value: UnitFormatter.formatElevation(totalElevationM, unit: units),
                icon: "arrow.up.right"
            )
            Divider().frame(height: 32)
            summaryItem(
                title: "Time",
                value: RunStatisticsCalculator.formatDuration(totalDuration),
                icon: "clock"
            )
        }
        .font(.caption)
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }

    private func summaryItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Colors.primary)
                .font(.caption2)
            Text(value)
                .font(.caption.bold().monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}
