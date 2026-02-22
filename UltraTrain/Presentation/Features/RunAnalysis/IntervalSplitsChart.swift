import Charts
import SwiftUI

struct IntervalSplitsChart: View {
    let workSplits: [IntervalSplit]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Interval Paces")
                .font(.headline)

            Chart {
                ForEach(Array(workSplits.enumerated()), id: \.offset) { index, split in
                    BarMark(
                        x: .value("Interval", "#\(index + 1)"),
                        y: .value("Pace", split.averagePaceSecondsPerKm)
                    )
                    .foregroundStyle(barColor(for: split))
                    .annotation(position: .top) {
                        Text(formatPace(split.averagePaceSecondsPerKm))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let avg = averagePace {
                    RuleMark(y: .value("Average", avg))
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("avg")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                }
            }
            .chartYScale(domain: yDomain)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let seconds = value.as(Double.self) {
                            Text(formatPace(seconds))
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .cardStyle()
    }

    // MARK: - Computed

    private var averagePace: Double? {
        guard !workSplits.isEmpty else { return nil }
        let total = workSplits.reduce(0.0) { $0 + $1.averagePaceSecondsPerKm }
        return total / Double(workSplits.count)
    }

    private var yDomain: ClosedRange<Double> {
        let paces = workSplits.map(\.averagePaceSecondsPerKm).filter { $0 > 0 && $0.isFinite }
        guard let minPace = paces.min(), let maxPace = paces.max() else {
            return 0...600
        }
        let padding = (maxPace - minPace) * 0.2
        return max(0, minPace - padding)...(maxPace + padding)
    }

    private func barColor(for split: IntervalSplit) -> Color {
        guard let avg = averagePace, avg > 0 else { return .red }
        if split.averagePaceSecondsPerKm < avg * 0.97 {
            return .green
        } else if split.averagePaceSecondsPerKm > avg * 1.03 {
            return .orange
        }
        return .red
    }

    private func formatPace(_ secondsPerKm: Double) -> String {
        guard secondsPerKm > 0, secondsPerKm.isFinite else { return "--" }
        let total = Int(secondsPerKm)
        let min = total / 60
        let sec = total % 60
        return String(format: "%d:%02d", min, sec)
    }
}
