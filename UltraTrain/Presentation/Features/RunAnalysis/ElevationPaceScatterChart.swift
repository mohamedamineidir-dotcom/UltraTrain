import SwiftUI
import Charts

struct ElevationPaceScatterChart: View {
    @Environment(\.unitPreference) private var units
    let points: [ElevationPaceScatterCalculator.GradientPacePoint]
    @State private var selectedPoint: ElevationPaceScatterCalculator.GradientPacePoint?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Elevation vs Pace")
                .font(.headline)

            Chart {
                ForEach(displayPoints) { point in
                    PointMark(
                        x: .value("Gradient %", point.gradientPercent),
                        y: .value("Pace", point.paceSecondsPerKm)
                    )
                    .foregroundStyle(GradientColorHelper.color(forGradient: point.gradientPercent))
                    .symbolSize(40)
                    .opacity(selectedPoint == nil || selectedPoint?.id == point.id ? 1.0 : 0.3)
                }

                zeroGradientLine
                selectionMark
            }
            .chartXAxisLabel("Gradient %")
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let gradient = value.as(Double.self) {
                            Text(String(format: "%.0f%%", gradient))
                        }
                    }
                }
            }
            .chartYAxisLabel("Pace")
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
            .chartYScale(domain: yDomain)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleDrag(value: value, proxy: proxy, geometry: geometry)
                                }
                                .onEnded { _ in
                                    selectedPoint = nil
                                }
                        )
                }
            }
            .frame(height: 200)

            legendRow
        }
        .chartAccessibility(summary: chartSummary)
    }

    // MARK: - Display Points (capped at 200)

    private var displayPoints: [ElevationPaceScatterCalculator.GradientPacePoint] {
        guard points.count > 200 else { return points }
        let strideBy = max(points.count / 200, 2)
        return stride(from: 0, to: points.count, by: strideBy).map { points[$0] }
    }

    // MARK: - Y Domain

    private var yDomain: ClosedRange<Double> {
        let paces = displayPoints.map(\.paceSecondsPerKm)
        guard let minPace = paces.min(), let maxPace = paces.max() else {
            return 180...600
        }
        let padding = (maxPace - minPace) * 0.1
        return max(minPace - padding, 60)...maxPace + padding
    }

    // MARK: - Zero Gradient Line

    @ChartContentBuilder
    private var zeroGradientLine: some ChartContent {
        RuleMark(x: .value("Zero", 0))
            .foregroundStyle(.gray.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }

    // MARK: - Selection

    @ChartContentBuilder
    private var selectionMark: some ChartContent {
        if let point = selectedPoint {
            RuleMark(x: .value("Selected", point.gradientPercent))
                .foregroundStyle(Theme.Colors.label.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .annotation(position: .top, spacing: 4) {
                    ChartAnnotationCard(
                        title: "KM \(point.kilometerNumber)",
                        value: RunStatisticsCalculator.formatPace(point.paceSecondsPerKm) + " " + UnitFormatter.paceLabel(units),
                        subtitle: String(format: "Gradient: %+.1f%%", point.gradientPercent)
                    )
                }
        }
    }

    private func handleDrag(
        value: DragGesture.Value,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        let plotFrame = geometry[proxy.plotFrame!]
        let xPosition = value.location.x - plotFrame.origin.x
        let yPosition = value.location.y - plotFrame.origin.y

        guard let dragGradient: Double = proxy.value(atX: xPosition),
              let dragPace: Double = proxy.value(atY: yPosition) else { return }

        var closest: ElevationPaceScatterCalculator.GradientPacePoint?
        var closestDistance = Double.greatestFiniteMagnitude

        for point in displayPoints {
            let gradientRange = (displayPoints.map(\.gradientPercent).max() ?? 1)
                - (displayPoints.map(\.gradientPercent).min() ?? 0)
            let paceRange = (displayPoints.map(\.paceSecondsPerKm).max() ?? 1)
                - (displayPoints.map(\.paceSecondsPerKm).min() ?? 0)

            let normalizedGradientDiff = gradientRange > 0
                ? (point.gradientPercent - dragGradient) / gradientRange
                : 0
            let normalizedPaceDiff = paceRange > 0
                ? (point.paceSecondsPerKm - dragPace) / paceRange
                : 0

            let distance = normalizedGradientDiff * normalizedGradientDiff
                + normalizedPaceDiff * normalizedPaceDiff

            if distance < closestDistance {
                closestDistance = distance
                closest = point
            }
        }

        if closestDistance < 0.05 {
            selectedPoint = closest
        } else {
            selectedPoint = nil
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            legendDot(color: .blue, label: "Downhill")
            legendDot(color: .green, label: "Flat")
            legendDot(color: .orange, label: "Uphill")
            legendDot(color: .red, label: "Steep Up")
        }
        .font(.caption)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Accessibility

    private var chartSummary: String {
        guard !points.isEmpty else { return "Elevation vs pace scatter chart, no data" }
        let avgPace = points.map(\.paceSecondsPerKm).reduce(0, +) / Double(points.count)
        let formatted = RunStatisticsCalculator.formatPace(avgPace)
        return "Scatter chart showing gradient vs pace for \(points.count) segments. Average pace \(formatted) per \(UnitFormatter.distanceLabel(units))."
    }
}
