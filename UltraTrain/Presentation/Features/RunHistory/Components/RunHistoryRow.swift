import SwiftUI

struct RunHistoryRow: View {
    @Environment(\.unitPreference) private var units
    let run: CompletedRun

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
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
    }
}
