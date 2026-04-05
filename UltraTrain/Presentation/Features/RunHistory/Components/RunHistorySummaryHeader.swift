import SwiftUI

struct RunHistorySummaryHeader: View {
    @Environment(\.unitPreference) private var units
    @Environment(\.colorScheme) private var colorScheme
    let runCount: Int
    let totalDistanceKm: Double
    let totalElevationM: Double
    let totalDuration: TimeInterval

    var body: some View {
        HStack(spacing: 0) {
            summaryItem(
                title: "Runs",
                value: "\(runCount)",
                icon: "figure.run",
                color: Theme.Colors.warmCoral
            )
            thinDivider
            summaryItem(
                title: "Distance",
                value: UnitFormatter.formatDistance(totalDistanceKm, unit: units),
                icon: "point.topleft.down.to.point.bottomright.curvepath",
                color: Theme.Colors.primary
            )
            thinDivider
            summaryItem(
                title: "D+",
                value: UnitFormatter.formatElevation(totalElevationM, unit: units),
                icon: "arrow.up.right",
                color: Theme.Colors.success
            )
            thinDivider
            summaryItem(
                title: "Time",
                value: RunStatisticsCalculator.formatDuration(totalDuration),
                icon: "clock",
                color: Theme.Colors.zone3
            )
        }
        .padding(.vertical, Theme.Spacing.md)
        .padding(.horizontal, Theme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .futuristicGlassStyle()
    }

    private func summaryItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.primary.opacity(0.08))
            .frame(width: 0.5, height: 36)
    }
}
