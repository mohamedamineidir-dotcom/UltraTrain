import SwiftUI
import Charts

struct WeeklyDistanceChartView: View {
    @Environment(\.unitPreference) private var units
    let weeklyVolumes: [WeeklyVolume]
    @State private var selectedDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weekly Distance")
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
        let total = weeklyVolumes.reduce(0.0) { $0 + $1.distanceKm }
        return "Weekly distance chart. \(weeklyVolumes.count) weeks. Total \(UnitFormatter.formatDistance(total, unit: units, decimals: 0))."
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(weeklyVolumes) { week in
                BarMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Distance", UnitFormatter.distanceValue(week.distanceKm, unit: units))
                )
                .foregroundStyle(Theme.Colors.primary.gradient)
                .cornerRadius(4)
            }

            ForEach(weeklyVolumes.filter { $0.plannedDistanceKm > 0 }) { week in
                LineMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Planned", UnitFormatter.distanceValue(week.plannedDistanceKm, unit: units))
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
        .chartYAxisLabel(UnitFormatter.distanceLabel(units))
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
                        let planned = week.plannedDistanceKm > 0
                            ? UnitFormatter.formatDistance(week.plannedDistanceKm, unit: units) + " planned"
                            : nil
                        ChartAnnotationCard(
                            title: week.weekStartDate.formatted(.dateTime.month(.abbreviated).day()),
                            value: UnitFormatter.formatDistance(week.distanceKm, unit: units),
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
            legendItem(color: Theme.Colors.primary, label: "Actual")
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
