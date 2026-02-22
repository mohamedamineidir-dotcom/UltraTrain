import SwiftUI
import Charts

struct ACRTrendChartView: View {
    let dataPoints: [ACRDataPoint]
    @State private var selectedDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Acute:Chronic Ratio Trend")
                .font(.headline)

            if dataPoints.count < 2 {
                Text("Not enough data to show trend")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                chart
                legend
            }
        }
        .cardStyle()
        .chartAccessibility(summary: chartSummary)
    }

    private var chartSummary: String {
        guard let latest = dataPoints.last else { return "Acute to chronic ratio chart, no data" }
        return "Acute to chronic ratio chart. Latest ACR \(String(format: "%.2f", latest.value)), \(acrZoneLabel(latest.value)). \(dataPoints.count) data points."
    }

    private var chart: some View {
        Chart {
            // Zone bands
            RectangleMark(
                yStart: .value("", 0),
                yEnd: .value("", 0.8)
            )
            .foregroundStyle(Theme.Colors.warning.opacity(0.08))

            RectangleMark(
                yStart: .value("", 0.8),
                yEnd: .value("", 1.3)
            )
            .foregroundStyle(Theme.Colors.success.opacity(0.08))

            RectangleMark(
                yStart: .value("", 1.3),
                yEnd: .value("", 1.5)
            )
            .foregroundStyle(Theme.Colors.warning.opacity(0.08))

            RectangleMark(
                yStart: .value("", 1.5),
                yEnd: .value("", maxYValue)
            )
            .foregroundStyle(Theme.Colors.danger.opacity(0.08))

            // Threshold lines
            RuleMark(y: .value("Low", 0.8))
                .foregroundStyle(Theme.Colors.warning.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

            RuleMark(y: .value("High", 1.5))
                .foregroundStyle(Theme.Colors.danger.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

            // ACR line
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("ACR", point.value)
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
        .chartYScale(domain: 0...maxYValue)
        .chartYAxisLabel("ACR")
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
                        let cardWidth: CGFloat = 120
                        let clampedX = min(max(xPos, cardWidth / 2), plotFrame.width - cardWidth / 2)
                        ChartAnnotationCard(
                            title: point.date.formatted(.dateTime.month(.abbreviated).day()),
                            value: String(format: "ACR: %.2f", point.value),
                            subtitle: acrZoneLabel(point.value)
                        )
                        .offset(x: clampedX, y: -8)
                    }
                }
            }
        }
    }

    private func nearestPoint(to date: Date) -> ACRDataPoint? {
        dataPoints.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }

    private func acrZoneLabel(_ value: Double) -> String {
        if value > 1.5 { return "Injury Risk" }
        if value > 1.3 { return "Caution" }
        if value >= 0.8 { return "Optimal" }
        return "Detraining"
    }

    private var maxYValue: Double {
        let maxACR = dataPoints.map(\.value).max() ?? 2.0
        return max(maxACR * 1.1, 2.0)
    }

    private var legend: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendItem(color: Theme.Colors.success, label: "Optimal (0.8–1.3)")
            legendItem(color: Theme.Colors.warning, label: "Caution")
            legendItem(color: Theme.Colors.danger, label: "Injury Risk (>1.5)")
        }
        .font(.caption2)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.3))
                .frame(width: 10, height: 10)
            Text(label)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}
