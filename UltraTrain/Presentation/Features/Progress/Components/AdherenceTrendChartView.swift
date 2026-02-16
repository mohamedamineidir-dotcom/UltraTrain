import SwiftUI
import Charts

struct AdherenceTrendChartView: View {
    let weeklyAdherence: [WeeklyAdherence]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weekly Adherence Trend")
                .font(.headline)

            chart
        }
    }

    private var chart: some View {
        Chart {
            RuleMark(y: .value("Target", 80))
                .foregroundStyle(Theme.Colors.success.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("80%")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.success)
                }

            ForEach(weeklyAdherence) { week in
                AreaMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Adherence", week.percent)
                )
                .foregroundStyle(Theme.Colors.primary.opacity(0.15))

                LineMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Adherence", week.percent)
                )
                .foregroundStyle(Theme.Colors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Adherence", week.percent)
                )
                .foregroundStyle(Theme.Colors.primary)
                .symbolSize(30)
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxisLabel("%")
        .frame(height: 200)
    }
}
