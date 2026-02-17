import SwiftUI
import Charts

struct PaceSplitsChart: View {
    let splits: [Split]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Pace per Kilometer")
                .font(.headline)

            Chart(splits) { split in
                BarMark(
                    x: .value("KM", split.kilometerNumber),
                    y: .value("Pace", split.duration)
                )
                .foregroundStyle(barColor(for: split))
                .cornerRadius(4)
            }
            .chartXAxisLabel("Kilometer")
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: min(splits.count, 10)))
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let seconds = value.as(Double.self) {
                            Text(RunStatisticsCalculator.formatPace(seconds))
                        }
                    }
                }
            }
            .frame(height: 200)

            legendRow
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary)
    }

    private var chartSummary: String {
        guard !splits.isEmpty else { return "Pace splits chart, no data" }
        let avg = RunStatisticsCalculator.formatPace(averagePace)
        let fastest = splits.min(by: { $0.duration < $1.duration })
        let slowest = splits.max(by: { $0.duration < $1.duration })
        let fastestPace = fastest.map { RunStatisticsCalculator.formatPace($0.duration) } ?? "--"
        let slowestPace = slowest.map { RunStatisticsCalculator.formatPace($0.duration) } ?? "--"
        return "Pace splits chart. \(splits.count) kilometers. Average \(avg) per km. Fastest \(fastestPace), slowest \(slowestPace)."
    }

    // MARK: - Helpers

    private func barColor(for split: Split) -> Color {
        let avg = averagePace
        guard avg > 0 else { return Theme.Colors.primary }
        if split.duration < avg * 0.95 { return Theme.Colors.success }
        if split.duration > avg * 1.05 { return Theme.Colors.danger }
        return Theme.Colors.primary
    }

    private var averagePace: Double {
        guard !splits.isEmpty else { return 0 }
        return splits.map(\.duration).reduce(0, +) / Double(splits.count)
    }

    private var legendRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendDot(color: Theme.Colors.success, label: "Faster")
            legendDot(color: Theme.Colors.primary, label: "Average")
            legendDot(color: Theme.Colors.danger, label: "Slower")
        }
        .font(.caption)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}
