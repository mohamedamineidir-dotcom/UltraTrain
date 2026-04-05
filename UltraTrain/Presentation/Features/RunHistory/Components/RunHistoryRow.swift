import SwiftUI

struct RunHistoryRow: View {
    @Environment(\.unitPreference) private var units
    @Environment(\.colorScheme) private var colorScheme
    let run: CompletedRun

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Activity type icon with colored circle
            ZStack {
                Circle()
                    .fill(activityColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: run.activityType.iconName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(activityColor)
            }

            // Run details
            VStack(alignment: .leading, spacing: 4) {
                // Date + relative time
                HStack {
                    Text(run.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(RunStatisticsCalculator.formatDuration(run.duration))
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(Theme.Colors.label)
                }

                // Stats row
                HStack(spacing: Theme.Spacing.md) {
                    statChip(
                        value: UnitFormatter.formatDistance(run.distanceKm, unit: units, decimals: 2),
                        icon: "point.topleft.down.to.point.bottomright.curvepath"
                    )
                    statChip(
                        value: RunStatisticsCalculator.formatPace(run.averagePaceSecondsPerKm, unit: units)
                            + " " + UnitFormatter.paceLabel(units),
                        icon: "speedometer"
                    )
                    if run.elevationGainM > 0 {
                        statChip(
                            value: "+" + UnitFormatter.formatElevation(run.elevationGainM, unit: units),
                            icon: "arrow.up.right"
                        )
                    }
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private func statChip(value: String, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
        }
        .font(.caption)
        .foregroundStyle(Theme.Colors.secondaryLabel)
    }

    private var activityColor: Color {
        switch run.activityType {
        case .running: Theme.Colors.primary
        case .trailRunning: Theme.Colors.success
        default: Theme.Colors.zone3
        }
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
