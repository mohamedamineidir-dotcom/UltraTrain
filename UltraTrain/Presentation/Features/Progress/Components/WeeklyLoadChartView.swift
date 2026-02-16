import SwiftUI
import Charts

struct WeeklyLoadChartView: View {
    let weeklyHistory: [WeeklyLoadData]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weekly Training Load")
                .font(.headline)

            if weeklyHistory.isEmpty {
                Text("No training data yet")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                chart
                legend
            }
        }
        .cardStyle()
    }

    private var chart: some View {
        Chart {
            ForEach(weeklyHistory) { week in
                BarMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Load", week.actualLoad)
                )
                .foregroundStyle(Theme.Colors.primary.gradient)
                .cornerRadius(4)
            }

            ForEach(weeklyHistory.filter { $0.plannedLoad > 0 }) { week in
                LineMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Planned", week.plannedLoad)
                )
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                .symbol {
                    Circle()
                        .fill(Theme.Colors.secondaryLabel)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .chartYAxisLabel("Effort Load")
        .frame(height: 200)
    }

    private var legend: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendDot(color: Theme.Colors.primary, label: "Actual")
            legendDot(color: Theme.Colors.secondaryLabel, label: "Planned", dashed: true)
        }
        .font(.caption)
    }

    private func legendDot(color: Color, label: String, dashed: Bool = false) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            if dashed {
                Rectangle()
                    .fill(color)
                    .frame(width: 12, height: 2)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            Text(label)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}
