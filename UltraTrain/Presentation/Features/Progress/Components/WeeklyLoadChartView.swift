import SwiftUI
import Charts

struct WeeklyLoadChartView: View {
    let weeklyHistory: [WeeklyLoadData]
    @State private var selectedDate: Date?

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

            if let selectedDate, let week = nearestWeek(to: selectedDate) {
                RuleMark(x: .value("Selected", week.weekStartDate, unit: .weekOfYear))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartYAxisLabel("Effort Load")
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
                        let planned = week.plannedLoad > 0 ? String(format: " / %.0f planned", week.plannedLoad) : ""
                        ChartAnnotationCard(
                            title: week.weekStartDate.formatted(.dateTime.month(.abbreviated).day()),
                            value: String(format: "%.0f load", week.actualLoad),
                            subtitle: planned.isEmpty ? nil : String(format: "%.0f planned", week.plannedLoad)
                        )
                        .offset(x: clampedX, y: -8)
                    }
                }
            }
        }
    }

    private func nearestWeek(to date: Date) -> WeeklyLoadData? {
        weeklyHistory.min { abs($0.weekStartDate.timeIntervalSince(date)) < abs($1.weekStartDate.timeIntervalSince(date)) }
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
