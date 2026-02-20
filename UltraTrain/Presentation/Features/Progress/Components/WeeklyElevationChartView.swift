import SwiftUI
import Charts

struct WeeklyElevationChartView: View {
    @Environment(\.unitPreference) private var units
    let weeklyVolumes: [WeeklyVolume]
    @State private var selectedDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weekly Elevation")
                .font(.headline)

            if weeklyVolumes.isEmpty {
                Text("No training data yet")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                chart
                legend
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary)
    }

    private var chartSummary: String {
        let total = weeklyVolumes.reduce(0.0) { $0 + $1.elevationGainM }
        return "Weekly elevation chart. \(weeklyVolumes.count) weeks. Total \(UnitFormatter.formatElevation(total, unit: units))."
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(weeklyVolumes) { week in
                BarMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Elevation", UnitFormatter.elevationValue(week.elevationGainM, unit: units))
                )
                .foregroundStyle(Theme.Colors.success.gradient)
                .cornerRadius(4)
            }

            ForEach(weeklyVolumes.filter { $0.plannedElevationGainM > 0 }) { week in
                LineMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Planned", UnitFormatter.elevationValue(week.plannedElevationGainM, unit: units))
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
        .chartYAxisLabel(UnitFormatter.elevationLabel(units))
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
                        let planned = week.plannedElevationGainM > 0
                            ? UnitFormatter.formatElevation(week.plannedElevationGainM, unit: units) + " planned"
                            : nil
                        ChartAnnotationCard(
                            title: week.weekStartDate.formatted(.dateTime.month(.abbreviated).day()),
                            value: UnitFormatter.formatElevation(week.elevationGainM, unit: units),
                            subtitle: planned
                        )
                        .offset(
                            x: annotationX(xPos: xPos, plotWidth: plotFrame.width),
                            y: -8
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func nearestWeek(to date: Date) -> WeeklyVolume? {
        weeklyVolumes.min { abs($0.weekStartDate.timeIntervalSince(date)) < abs($1.weekStartDate.timeIntervalSince(date)) }
    }

    private func annotationX(xPos: CGFloat, plotWidth: CGFloat) -> CGFloat {
        let cardWidth: CGFloat = 120
        return min(max(xPos, cardWidth / 2), plotWidth - cardWidth / 2)
    }

    private var legend: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendItem(color: Theme.Colors.success, label: "Actual")
            legendItem(color: Theme.Colors.secondaryLabel, label: "Planned", dashed: true)
        }
        .font(.caption)
    }

    private func legendItem(color: Color, label: String, dashed: Bool = false) -> some View {
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
