import SwiftUI

struct IntervalAnalysisCard: View {
    let analysis: IntervalAnalysisCalculator.IntervalAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Interval Analysis")
                .font(.headline)

            overviewGrid

            if !analysis.workSplits.isEmpty {
                splitsList
            }
        }
        .cardStyle()
    }

    // MARK: - Overview

    private var overviewGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Theme.Spacing.sm) {
            metricCell(title: "Avg Work Pace", value: formatPace(analysis.averageWorkPace))
            metricCell(title: "Consistency", value: String(format: "%.0f%%", analysis.paceConsistencyPercent))
            metricCell(title: "W:R Ratio", value: String(format: "%.1f:1", analysis.workToRestRatio))

            if let avgHR = analysis.averageWorkHeartRate {
                metricCell(title: "Avg Work HR", value: "\(avgHR) bpm")
            }
            if let hrDelta = analysis.heartRateRecoveryDelta {
                metricCell(title: "HR Recovery", value: "\(hrDelta > 0 ? "+" : "")\(hrDelta) bpm")
            }
            if let fastest = analysis.fastestWorkSplit {
                metricCell(title: "Fastest", value: formatPace(fastest.averagePaceSecondsPerKm))
            }
        }
    }

    // MARK: - Splits List

    private var splitsList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Work Intervals")
                .font(.subheadline.weight(.semibold))

            ForEach(Array(analysis.workSplits.enumerated()), id: \.offset) { index, split in
                HStack {
                    Text("#\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .leading)

                    Text(formatPace(split.averagePaceSecondsPerKm))
                        .font(.caption.monospacedDigit())

                    Spacer()

                    Text(String(format: "%.2f km", split.distanceKm))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let hr = split.averageHeartRate {
                        Text("\(hr) bpm")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    paceIndicator(split: split)
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Helpers

    private func metricCell(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func paceIndicator(split: IntervalSplit) -> some View {
        let avg = analysis.averageWorkPace
        let diff = split.averagePaceSecondsPerKm - avg
        let threshold: Double = 5

        return Group {
            if abs(diff) < threshold {
                Image(systemName: "equal.circle.fill")
                    .foregroundStyle(.secondary)
            } else if diff < 0 {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .font(.caption)
    }

    private func formatPace(_ secondsPerKm: Double) -> String {
        guard secondsPerKm > 0, secondsPerKm.isFinite else { return "--" }
        let total = Int(secondsPerKm)
        let min = total / 60
        let sec = total % 60
        return String(format: "%d:%02d /km", min, sec)
    }
}
