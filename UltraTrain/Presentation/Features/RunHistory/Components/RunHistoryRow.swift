import SwiftUI

struct RunHistoryRow: View {
    @Environment(\.unitPreference) private var units
    let run: CompletedRun

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Image(systemName: run.activityType.iconName)
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityLabel(run.activityType.displayName)
                Text(run.date, style: .date)
                    .font(.subheadline.bold())
                Spacer()
                Text(RunStatisticsCalculator.formatDuration(run.duration))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            HStack(spacing: Theme.Spacing.md) {
                Label(
                    UnitFormatter.formatDistance(run.distanceKm, unit: units, decimals: 2),
                    systemImage: "arrow.left.arrow.right"
                )
                Label(
                    RunStatisticsCalculator.formatPace(run.averagePaceSecondsPerKm, unit: units) + " " + UnitFormatter.paceLabel(units),
                    systemImage: "speedometer"
                )
                if run.elevationGainM > 0 {
                    Label(
                        "+" + UnitFormatter.formatElevation(run.elevationGainM, unit: units),
                        systemImage: "arrow.up.right"
                    )
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let date = run.date.formatted(.dateTime.month().day().year())
        let dist = AccessibilityFormatters.distance(run.distanceKm, unit: units)
        let pace = AccessibilityFormatters.pace(
            RunStatisticsCalculator.formatPace(run.averagePaceSecondsPerKm, unit: units),
            unit: units
        )
        let dur = AccessibilityFormatters.duration(run.duration)
        var label = "\(date). \(dist), pace \(pace), \(dur)"
        if run.elevationGainM > 0 {
            label += ", \(AccessibilityFormatters.elevation(run.elevationGainM, unit: units))"
        }
        return label
    }
}
