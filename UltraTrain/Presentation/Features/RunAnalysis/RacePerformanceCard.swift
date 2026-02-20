import SwiftUI

struct RacePerformanceCard: View {
    @Environment(\.unitPreference) private var units

    let performance: RacePerformanceComparison

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Race Performance")
                .font(.headline)

            header

            ForEach(performance.checkpointComparisons) { cp in
                checkpointRow(cp)
                if cp.id != performance.checkpointComparisons.last?.id {
                    Divider()
                }
            }

            Divider()
                .padding(.vertical, Theme.Spacing.xs)

            finishRow
        }
        .cardStyle()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Predicted")
                .font(.caption.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 70, alignment: .trailing)
            Text("Actual")
                .font(.caption.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 70, alignment: .trailing)
            Text("Delta")
                .font(.caption.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 60, alignment: .trailing)
        }
    }

    // MARK: - Checkpoint Row

    private func checkpointRow(_ cp: CheckpointComparison) -> some View {
        HStack {
            HStack(spacing: Theme.Spacing.xs) {
                Text(cp.checkpointName)
                    .font(.subheadline)
                    .lineLimit(1)
                if cp.hasAidStation {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(FinishEstimate.formatDuration(cp.predictedTime))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 70, alignment: .trailing)

            Text(FinishEstimate.formatDuration(cp.actualTime))
                .font(.subheadline.bold().monospacedDigit())
                .frame(width: 70, alignment: .trailing)

            Text(formatDelta(cp.delta))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(deltaColor(cp.delta))
                .frame(width: 60, alignment: .trailing)
        }
    }

    // MARK: - Finish Row

    private var finishRow: some View {
        HStack {
            Text("Finish")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(FinishEstimate.formatDuration(performance.predictedFinishTime))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 70, alignment: .trailing)

            Text(FinishEstimate.formatDuration(performance.actualFinishTime))
                .font(.subheadline.bold().monospacedDigit())
                .frame(width: 70, alignment: .trailing)

            Text(formatDelta(performance.finishDelta))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(deltaColor(performance.finishDelta))
                .frame(width: 60, alignment: .trailing)
        }
    }

    // MARK: - Helpers

    private func formatDelta(_ delta: TimeInterval) -> String {
        let sign = delta < 0 ? "-" : "+"
        let absDelta = abs(delta)
        let hours = Int(absDelta) / 3600
        let minutes = (Int(absDelta) % 3600) / 60
        if hours > 0 {
            return "\(sign)\(hours)h\(String(format: "%02d", minutes))"
        }
        let seconds = Int(absDelta) % 60
        return "\(sign)\(minutes):\(String(format: "%02d", seconds))"
    }

    private func deltaColor(_ delta: TimeInterval) -> Color {
        delta <= 0 ? Theme.Colors.success : Theme.Colors.warning
    }
}
