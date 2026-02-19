import SwiftUI

struct RunHistoryRow: View {
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
                    String(format: "%.2f km", run.distanceKm),
                    systemImage: "arrow.left.arrow.right"
                )
                Label(run.paceFormatted, systemImage: "speedometer")
                if run.elevationGainM > 0 {
                    Label(
                        String(format: "+%.0f m", run.elevationGainM),
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
