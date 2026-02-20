import SwiftUI
import Charts

struct ElevationProfileChart: View {
    @Environment(\.unitPreference) private var units

    let dataPoints: [ElevationProfilePoint]
    var elevationSegments: [ElevationSegment] = []
    var checkpointDistances: [(name: String, distanceKm: Double)] = []

    @State private var selectedDistance: Double?

    private var extremes: (highest: ElevationProfilePoint, lowest: ElevationProfilePoint)? {
        ElevationCalculator.elevationExtremes(from: dataPoints)
    }

    private var useGradientColoring: Bool {
        !elevationSegments.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Elevation Profile")
                .font(.headline)

            chart
                .frame(height: 200)

            if useGradientColoring {
                gradientLegend
            }
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            if useGradientColoring {
                gradientColoredMarks
            } else {
                defaultMarks
            }

            checkpointRules

            extremeAnnotations

            selectionMark
        }
        .chartXAxisLabel("Distance (\(UnitFormatter.distanceLabel(units)))")
        .chartYAxisLabel("Altitude (\(UnitFormatter.elevationShortLabel(units)))")
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
                                selectedDistance = nil
                            }
                    )
            }
        }
    }

    // MARK: - Default Marks

    @ChartContentBuilder
    private var defaultMarks: some ChartContent {
        ForEach(dataPoints) { point in
            AreaMark(
                x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                y: .value("Altitude", UnitFormatter.elevationValue(point.altitudeM, unit: units))
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [
                        Theme.Colors.success.opacity(0.3),
                        Theme.Colors.success.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                y: .value("Altitude", UnitFormatter.elevationValue(point.altitudeM, unit: units))
            )
            .foregroundStyle(Theme.Colors.success)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
    }

    // MARK: - Gradient Colored Marks

    @ChartContentBuilder
    private var gradientColoredMarks: some ChartContent {
        ForEach(elevationSegments) { segment in
            let color = GradientColorHelper.color(forGradient: segment.averageGradient)
            let midDistKm = Double(segment.kilometerNumber) - 0.5

            BarMark(
                x: .value("Distance", UnitFormatter.distanceValue(midDistKm, unit: units)),
                yStart: .value("Base", UnitFormatter.elevationValue(altitudeRange.lowerBound, unit: units)),
                yEnd: .value("Top", UnitFormatter.elevationValue(altitudeAtKm(segment.kilometerNumber), unit: units)),
                width: .ratio(0.95)
            )
            .foregroundStyle(color.opacity(0.3))
        }

        ForEach(dataPoints) { point in
            LineMark(
                x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                y: .value("Altitude", UnitFormatter.elevationValue(point.altitudeM, unit: units))
            )
            .foregroundStyle(Theme.Colors.label.opacity(0.8))
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
    }

    // MARK: - Checkpoint Rules

    @ChartContentBuilder
    private var checkpointRules: some ChartContent {
        ForEach(Array(checkpointDistances.enumerated()), id: \.offset) { _, cp in
            RuleMark(x: .value("CP", UnitFormatter.distanceValue(cp.distanceKm, unit: units)))
                .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .annotation(position: .top, spacing: 2) {
                    Text(cp.name)
                        .font(.system(size: 7))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
        }
    }

    // MARK: - Extreme Annotations

    @ChartContentBuilder
    private var extremeAnnotations: some ChartContent {
        if let ext = extremes, dataPoints.count >= 4 {
            PointMark(
                x: .value("Distance", UnitFormatter.distanceValue(ext.highest.distanceKm, unit: units)),
                y: .value("Altitude", UnitFormatter.elevationValue(ext.highest.altitudeM, unit: units))
            )
            .foregroundStyle(Theme.Colors.danger)
            .symbolSize(30)
            .annotation(position: .top, spacing: 2) {
                Text(UnitFormatter.formatElevation(ext.highest.altitudeM, unit: units))
                    .font(.system(size: 8).bold())
                    .foregroundStyle(Theme.Colors.danger)
            }

            PointMark(
                x: .value("Distance", UnitFormatter.distanceValue(ext.lowest.distanceKm, unit: units)),
                y: .value("Altitude", UnitFormatter.elevationValue(ext.lowest.altitudeM, unit: units))
            )
            .foregroundStyle(Theme.Colors.success)
            .symbolSize(30)
            .annotation(position: .bottom, spacing: 2) {
                Text(UnitFormatter.formatElevation(ext.lowest.altitudeM, unit: units))
                    .font(.system(size: 8).bold())
                    .foregroundStyle(Theme.Colors.success)
            }
        }
    }

    // MARK: - Selection

    @ChartContentBuilder
    private var selectionMark: some ChartContent {
        if let distKm = selectedDistance,
           let point = nearestPoint(at: distKm) {
            RuleMark(x: .value("Selected", UnitFormatter.distanceValue(distKm, unit: units)))
                .foregroundStyle(Theme.Colors.danger)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .annotation(position: .top, spacing: 4) {
                    ChartAnnotationCard(
                        title: UnitFormatter.formatDistance(distKm, unit: units),
                        value: UnitFormatter.formatElevation(point.altitudeM, unit: units),
                        subtitle: gradeLabel(at: distKm)
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
        guard let displayDistance: Double = proxy.value(atX: xPosition) else { return }
        let distKm = UnitFormatter.distanceToKm(displayDistance, unit: units)
        let clamped = max(0, min(distKm, dataPoints.last?.distanceKm ?? 0))
        selectedDistance = clamped
    }

    private func nearestPoint(at distKm: Double) -> ElevationProfilePoint? {
        dataPoints.min(by: {
            abs($0.distanceKm - distKm) < abs($1.distanceKm - distKm)
        })
    }

    private func gradeLabel(at distKm: Double) -> String? {
        guard dataPoints.count >= 2 else { return nil }
        guard let idx = dataPoints.firstIndex(where: { $0.distanceKm >= distKm }),
              idx > 0 else { return nil }
        let prev = dataPoints[idx - 1]
        let curr = dataPoints[idx]
        let horizM = (curr.distanceKm - prev.distanceKm) * 1000
        guard horizM > 0 else { return nil }
        let grade = (curr.altitudeM - prev.altitudeM) / horizM * 100
        return String(format: "Grade: %+.1f%%", grade)
    }

    // MARK: - Helpers

    private var altitudeRange: ClosedRange<Double> {
        let altitudes = dataPoints.map(\.altitudeM)
        let minAlt = altitudes.min() ?? 0
        let maxAlt = altitudes.max() ?? 0
        return minAlt...maxAlt
    }

    private func altitudeAtKm(_ km: Int) -> Double {
        let target = Double(km) - 0.5
        guard let closest = dataPoints.min(by: {
            abs($0.distanceKm - target) < abs($1.distanceKm - target)
        }) else {
            return altitudeRange.lowerBound
        }
        return closest.altitudeM
    }

    // MARK: - Gradient Legend

    private var gradientLegend: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(GradientCategory.allCases, id: \.self) { category in
                HStack(spacing: 3) {
                    Circle()
                        .fill(GradientColorHelper.color(for: category))
                        .frame(width: 7, height: 7)
                    Text(legendLabel(for: category))
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
    }

    private func legendLabel(for category: GradientCategory) -> String {
        switch category {
        case .steepDown: "Steep-"
        case .moderateDown: "Down"
        case .flat: "Flat"
        case .moderateUp: "Up"
        case .steepUp: "Steep+"
        }
    }

    // MARK: - Accessibility

    private var chartSummary: String {
        guard !dataPoints.isEmpty else { return "Elevation profile chart, no data" }
        let minAlt = dataPoints.map(\.altitudeM).min() ?? 0
        let maxAlt = dataPoints.map(\.altitudeM).max() ?? 0
        let totalDist = dataPoints.last?.distanceKm ?? 0
        let distStr = UnitFormatter.formatDistance(totalDist, unit: units)
        let minStr = UnitFormatter.formatElevation(minAlt, unit: units)
        let maxStr = UnitFormatter.formatElevation(maxAlt, unit: units)
        return "Elevation profile chart. \(distStr). Altitude range \(minStr) to \(maxStr)."
    }
}
