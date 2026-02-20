import SwiftUI
import Charts

struct ElevationPaceChart: View {
    @Environment(\.unitPreference) private var units

    let elevationProfile: [ElevationProfilePoint]
    let splits: [Split]
    var checkpointDistances: [(name: String, distanceKm: Double)] = []

    private var overlayData: (
        elevation: [ElevationPaceOverlayCalculator.OverlayDataPoint],
        pace: [ElevationPaceOverlayCalculator.PaceOverlayPoint]
    ) {
        ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: elevationProfile,
            splits: splits
        )
    }

    private var altitudeRange: (min: Double, max: Double) {
        let altitudes = elevationProfile.map(\.altitudeM)
        return (min: altitudes.min() ?? 0, max: altitudes.max() ?? 0)
    }

    private var paceRange: (min: Double, max: Double) {
        let paces = splits.map(\.duration)
        return (min: paces.min() ?? 0, max: paces.max() ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Elevation & Pace")
                .font(.headline)

            chart
                .frame(height: 220)

            legendRow
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            elevationMarks
            paceMarks
            checkpointRules
        }
        .chartYScale(domain: 0...1)
        .chartXAxisLabel("Distance (\(UnitFormatter.distanceLabel(units)))")
        .chartYAxis {
            AxisMarks(position: .leading, values: [0.0, 0.25, 0.5, 0.75, 1.0]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let normalized = value.as(Double.self) {
                        let alt = denormalizeAltitude(normalized)
                        Text(UnitFormatter.formatElevation(alt, unit: units))
                            .font(.system(size: 8))
                    }
                }
            }
            AxisMarks(position: .trailing, values: [0.0, 0.25, 0.5, 0.75, 1.0]) { value in
                AxisValueLabel {
                    if let normalized = value.as(Double.self) {
                        let pace = denormalizePace(normalized)
                        Text(RunStatisticsCalculator.formatPace(pace, unit: units))
                            .font(.system(size: 8))
                    }
                }
            }
        }
    }

    // MARK: - Elevation Marks

    @ChartContentBuilder
    private var elevationMarks: some ChartContent {
        let data = overlayData.elevation
        ForEach(data) { point in
            AreaMark(
                x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                y: .value("Value", point.normalizedAltitude)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [
                        Theme.Colors.success.opacity(0.2),
                        Theme.Colors.success.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                y: .value("Value", point.normalizedAltitude)
            )
            .foregroundStyle(Theme.Colors.success.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
    }

    // MARK: - Pace Marks

    @ChartContentBuilder
    private var paceMarks: some ChartContent {
        let data = overlayData.pace
        ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
            if index > 0 {
                LineMark(
                    x: .value("Distance", UnitFormatter.distanceValue(data[index - 1].distanceKm, unit: units)),
                    y: .value("Pace", data[index - 1].normalizedPace),
                    series: .value("Pace", "pace-\(index)")
                )
                .foregroundStyle(paceColor(for: point.paceCategory))
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                LineMark(
                    x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                    y: .value("Pace", point.normalizedPace),
                    series: .value("Pace", "pace-\(index)")
                )
                .foregroundStyle(paceColor(for: point.paceCategory))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            }

            PointMark(
                x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                y: .value("Pace", point.normalizedPace)
            )
            .foregroundStyle(paceColor(for: point.paceCategory))
            .symbolSize(20)
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

    // MARK: - Helpers

    private func paceColor(for category: ElevationPaceOverlayCalculator.PaceCategory) -> Color {
        switch category {
        case .faster: Theme.Colors.success
        case .average: Theme.Colors.primary
        case .slower: Theme.Colors.danger
        }
    }

    private func denormalizeAltitude(_ normalized: Double) -> Double {
        let range = altitudeRange
        return range.min + normalized * (range.max - range.min)
    }

    private func denormalizePace(_ normalized: Double) -> Double {
        let range = paceRange
        guard range.max > range.min else { return range.min }
        return range.max - normalized * (range.max - range.min)
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendDot(color: Theme.Colors.success.opacity(0.5), label: "Elevation")
            legendDot(color: Theme.Colors.success, label: "Faster")
            legendDot(color: Theme.Colors.primary, label: "Average")
            legendDot(color: Theme.Colors.danger, label: "Slower")
        }
        .font(.caption)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Accessibility

    private var chartSummary: String {
        guard !elevationProfile.isEmpty else { return "Elevation and pace chart, no data" }
        let dist = elevationProfile.last?.distanceKm ?? 0
        let distStr = UnitFormatter.formatDistance(dist, unit: units)
        let altRange = altitudeRange
        let minStr = UnitFormatter.formatElevation(altRange.min, unit: units)
        let maxStr = UnitFormatter.formatElevation(altRange.max, unit: units)
        let avgPace = splits.isEmpty ? 0 : splits.map(\.duration).reduce(0, +) / Double(splits.count)
        let paceStr = RunStatisticsCalculator.formatPace(avgPace, unit: units)
        return "Elevation and pace chart. \(distStr). Altitude \(minStr) to \(maxStr). Average pace \(paceStr)."
    }
}
