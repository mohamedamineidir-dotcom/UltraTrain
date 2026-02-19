import SwiftUI
import Charts

struct ElevationProfileChart: View {
    let dataPoints: [ElevationProfilePoint]
    var elevationSegments: [ElevationSegment] = []
    var checkpointDistances: [(name: String, distanceKm: Double)] = []

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
        }
        .chartXAxisLabel("Distance (km)")
        .chartYAxisLabel("Altitude (m)")
    }

    // MARK: - Default Marks

    @ChartContentBuilder
    private var defaultMarks: some ChartContent {
        ForEach(dataPoints) { point in
            AreaMark(
                x: .value("Distance", point.distanceKm),
                y: .value("Altitude", point.altitudeM)
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
                x: .value("Distance", point.distanceKm),
                y: .value("Altitude", point.altitudeM)
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
                x: .value("Distance", midDistKm),
                yStart: .value("Base", altitudeRange.lowerBound),
                yEnd: .value("Top", altitudeAtKm(segment.kilometerNumber)),
                width: .ratio(0.95)
            )
            .foregroundStyle(color.opacity(0.3))
        }

        ForEach(dataPoints) { point in
            LineMark(
                x: .value("Distance", point.distanceKm),
                y: .value("Altitude", point.altitudeM)
            )
            .foregroundStyle(Theme.Colors.label.opacity(0.8))
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
    }

    // MARK: - Checkpoint Rules

    @ChartContentBuilder
    private var checkpointRules: some ChartContent {
        ForEach(Array(checkpointDistances.enumerated()), id: \.offset) { _, cp in
            RuleMark(x: .value("CP", cp.distanceKm))
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
                x: .value("Distance", ext.highest.distanceKm),
                y: .value("Altitude", ext.highest.altitudeM)
            )
            .foregroundStyle(Theme.Colors.danger)
            .symbolSize(30)
            .annotation(position: .top, spacing: 2) {
                Text("\(Int(ext.highest.altitudeM))m")
                    .font(.system(size: 8).bold())
                    .foregroundStyle(Theme.Colors.danger)
            }

            PointMark(
                x: .value("Distance", ext.lowest.distanceKm),
                y: .value("Altitude", ext.lowest.altitudeM)
            )
            .foregroundStyle(Theme.Colors.success)
            .symbolSize(30)
            .annotation(position: .bottom, spacing: 2) {
                Text("\(Int(ext.lowest.altitudeM))m")
                    .font(.system(size: 8).bold())
                    .foregroundStyle(Theme.Colors.success)
            }
        }
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
        return "Elevation profile chart. \(String(format: "%.1f", totalDist)) km. Altitude range \(Int(minAlt)) to \(Int(maxAlt)) meters."
    }
}
