import SwiftUI
import Charts

struct HeartRateTrendChartView: View {
    @Environment(\.unitPreference) private var units
    let trendPoints: [RunTrendPoint]
    @State private var selectedDate: Date?

    private var pointsWithHR: [RunTrendPoint] {
        trendPoints.filter { $0.averageHeartRate != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Heart Rate Trend")
                .font(.headline)

            if pointsWithHR.count < 3 {
                Text("Complete at least 3 runs with HR data to see trend")
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
        guard let latest = pointsWithHR.last else { return "Heart rate trend chart, no data" }
        return "Heart rate trend chart. \(pointsWithHR.count) runs with heart rate data. Latest average \(latest.averageHeartRate!) bpm."
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(pointsWithHR) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("HR", Double(point.averageHeartRate!))
                )
                .foregroundStyle(Theme.Colors.danger.opacity(0.5))
                .symbolSize(30)
            }

            ForEach(pointsWithHR.filter { $0.rollingAverageHR != nil }) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Avg HR", point.rollingAverageHR!)
                )
                .foregroundStyle(Theme.Colors.danger)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            if let selectedDate, let point = nearestPoint(to: selectedDate) {
                RuleMark(x: .value("Selected", point.date))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxisLabel("bpm")
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
                if let selectedDate, let point = nearestPoint(to: selectedDate) {
                    let plotFrame = geo[proxy.plotFrame!]
                    if let xPos = proxy.position(forX: point.date) {
                        ChartAnnotationCard(
                            title: point.date.formatted(.dateTime.month(.abbreviated).day()),
                            value: "\(point.averageHeartRate!) bpm",
                            subtitle: RunStatisticsCalculator.formatPace(point.averagePaceSecondsPerKm, unit: units) + " " + UnitFormatter.paceLabel(units)
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

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.xs) {
                Circle().fill(Theme.Colors.danger.opacity(0.5)).frame(width: 8, height: 8)
                Text("Per Run").foregroundStyle(Theme.Colors.secondaryLabel)
            }
            HStack(spacing: Theme.Spacing.xs) {
                Rectangle().fill(Theme.Colors.danger).frame(width: 12, height: 2)
                Text("5-Run Average").foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .font(.caption2)
    }

    // MARK: - Helpers

    private func nearestPoint(to date: Date) -> RunTrendPoint? {
        pointsWithHR.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }

    private func annotationX(xPos: CGFloat, plotWidth: CGFloat) -> CGFloat {
        let cardWidth: CGFloat = 100
        return min(max(xPos, cardWidth / 2), plotWidth - cardWidth / 2)
    }
}
