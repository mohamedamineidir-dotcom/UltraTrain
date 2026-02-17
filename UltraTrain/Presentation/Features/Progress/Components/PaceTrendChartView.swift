import SwiftUI
import Charts

struct PaceTrendChartView: View {
    let trendPoints: [RunTrendPoint]
    @State private var selectedDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Pace Trend")
                .font(.headline)

            if trendPoints.count < 3 {
                Text("Complete at least 3 runs to see pace trend")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                chart
                legend
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(trendPoints) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Pace", point.averagePaceSecondsPerKm)
                )
                .foregroundStyle(Theme.Colors.primary.opacity(0.5))
                .symbolSize(30)
            }

            ForEach(trendPoints.filter { $0.rollingAveragePace != nil }) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Avg Pace", point.rollingAveragePace!)
                )
                .foregroundStyle(Theme.Colors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            if let selectedDate, let point = nearestPoint(to: selectedDate) {
                RuleMark(x: .value("Selected", point.date))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
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
                            value: RunStatisticsCalculator.formatPace(point.averagePaceSecondsPerKm) + " /km",
                            subtitle: String(format: "%.1f km", point.distanceKm)
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
            legendDot(color: Theme.Colors.primary.opacity(0.5), label: "Per Run", isCircle: true)
            legendDot(color: Theme.Colors.primary, label: "5-Run Average", isCircle: false)
        }
        .font(.caption2)
    }

    private func legendDot(color: Color, label: String, isCircle: Bool) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            if isCircle {
                Circle().fill(color).frame(width: 8, height: 8)
            } else {
                Rectangle().fill(color).frame(width: 12, height: 2)
            }
            Text(label).foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Helpers

    private func nearestPoint(to date: Date) -> RunTrendPoint? {
        trendPoints.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }

    private func annotationX(xPos: CGFloat, plotWidth: CGFloat) -> CGFloat {
        let cardWidth: CGFloat = 100
        let clampedX = min(max(xPos, cardWidth / 2), plotWidth - cardWidth / 2)
        return clampedX
    }
}
