import SwiftUI
import Charts

struct AdherenceTrendChartView: View {
    let weeklyAdherence: [WeeklyAdherence]
    @State private var selectedDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weekly Adherence Trend")
                .font(.headline)

            chart
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary)
    }

    private var chartSummary: String {
        guard let latest = weeklyAdherence.last else { return "Weekly adherence trend, no data" }
        return "Weekly adherence trend. \(weeklyAdherence.count) weeks. Latest week \(Int(latest.percent))%, \(latest.completed) of \(latest.total) sessions."
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

            if let selectedDate, let week = nearestWeek(to: selectedDate) {
                RuleMark(x: .value("Selected", week.weekStartDate, unit: .weekOfYear))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxisLabel("%")
        .frame(height: 200)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let x = drag.location.x - geo[proxy.plotFrame!].origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedDate = date
                                }
                            }
                            .onEnded { _ in
                                selectedDate = nil
                            }
                    )
            }
        }
        .chartBackground { proxy in
            GeometryReader { geo in
                if let selectedDate, let week = nearestWeek(to: selectedDate) {
                    let plotFrame = geo[proxy.plotFrame!]
                    if let xPos = proxy.position(forX: week.weekStartDate) {
                        let cardWidth: CGFloat = 120
                        let clampedX = min(max(xPos, cardWidth / 2), plotFrame.width - cardWidth / 2)
                        ChartAnnotationCard(
                            title: "Week \(week.weekNumber)",
                            value: String(format: "%.0f%%", week.percent),
                            subtitle: "\(week.completed)/\(week.total) sessions"
                        )
                        .offset(x: clampedX, y: -8)
                    }
                }
            }
        }
    }

    private func nearestWeek(to date: Date) -> WeeklyAdherence? {
        weeklyAdherence.min { abs($0.weekStartDate.timeIntervalSince(date)) < abs($1.weekStartDate.timeIntervalSince(date)) }
    }
}
