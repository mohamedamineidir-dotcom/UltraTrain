import SwiftUI
import Charts

struct CumulativeVolumeChartView: View {
    let weeklyVolumes: [WeeklyVolume]
    @State private var selectedDate: Date?

    private var cumulativeData: [(date: Date, cumulativeKm: Double)] {
        var total = 0.0
        return weeklyVolumes.map { week in
            total += week.distanceKm
            return (date: week.weekStartDate, cumulativeKm: total)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Cumulative Volume")
                .font(.headline)

            chart
        }
    }

    // MARK: - Chart

    private var chart: some View {
        let data = cumulativeData
        return Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                AreaMark(
                    x: .value("Week", item.date, unit: .weekOfYear),
                    y: .value("Cumulative", item.cumulativeKm)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.primary.opacity(0.3), Theme.Colors.primary.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Week", item.date, unit: .weekOfYear),
                    y: .value("Cumulative", item.cumulativeKm)
                )
                .foregroundStyle(Theme.Colors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            if let selectedDate, let item = nearestItem(to: selectedDate, in: data) {
                RuleMark(x: .value("Selected", item.date, unit: .weekOfYear))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartYAxisLabel("km")
        .frame(height: 180)
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
                let data = cumulativeData
                if let selectedDate, let item = nearestItem(to: selectedDate, in: data) {
                    let plotFrame = geo[proxy.plotFrame!]
                    if let xPos = proxy.position(forX: item.date) {
                        ChartAnnotationCard(
                            title: item.date.formatted(.dateTime.month(.abbreviated).day()),
                            value: String(format: "%.0f km total", item.cumulativeKm)
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

    private func nearestItem(to date: Date, in data: [(date: Date, cumulativeKm: Double)]) -> (date: Date, cumulativeKm: Double)? {
        data.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }

    private func annotationX(xPos: CGFloat, plotWidth: CGFloat) -> CGFloat {
        let cardWidth: CGFloat = 110
        return min(max(xPos, cardWidth / 2), plotWidth - cardWidth / 2)
    }
}
