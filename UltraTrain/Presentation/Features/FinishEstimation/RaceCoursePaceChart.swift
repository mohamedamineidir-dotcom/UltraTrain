import SwiftUI
import Charts

struct RaceCoursePaceChart: View {
    @Environment(\.unitPreference) private var units

    let checkpoints: [Checkpoint]
    let checkpointSplits: [CheckpointSplit]

    private var overlayData: (
        elevation: [ElevationPaceOverlayCalculator.OverlayDataPoint],
        pace: [ElevationPaceOverlayCalculator.PaceOverlayPoint]
    ) {
        ElevationPaceOverlayCalculator.buildRaceCourseOverlay(
            checkpoints: checkpoints,
            checkpointSplits: checkpointSplits
        )
    }

    private var elevationChanges: (gainM: Double, lossM: Double) {
        RaceCourseProfileCalculator.elevationChanges(from: checkpoints)
    }

    private var altitudeRange: (min: Double, max: Double) {
        let altitudes = checkpoints.map(\.elevationM)
        return (min: altitudes.min() ?? 0, max: altitudes.max() ?? 0)
    }

    private var paceRange: (min: Double, max: Double) {
        let paces = ElevationPaceOverlayCalculator.segmentPaces(from: checkpointSplits)
            .map(\.paceSecondsPerKm)
        return (min: paces.min() ?? 0, max: paces.max() ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            chart
                .frame(height: 200)
            legendRow
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Course Profile & Predicted Pace")
                .font(.headline)
            Spacer()
            elevationBadges
        }
    }

    private var elevationBadges: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Label(
                "+\(UnitFormatter.formatElevation(elevationChanges.gainM, unit: units))",
                systemImage: "arrow.up.right"
            )
            .foregroundStyle(Theme.Colors.danger)

            Label(
                "-\(UnitFormatter.formatElevation(elevationChanges.lossM, unit: units))",
                systemImage: "arrow.down.right"
            )
            .foregroundStyle(Theme.Colors.success)
        }
        .font(.caption2)
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
                        Theme.Colors.primary.opacity(0.25),
                        Theme.Colors.primary.opacity(0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                y: .value("Value", point.normalizedAltitude)
            )
            .foregroundStyle(Theme.Colors.primary.opacity(0.6))
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
        ForEach(checkpoints) { cp in
            RuleMark(x: .value("CP", UnitFormatter.distanceValue(cp.distanceFromStartKm, unit: units)))
                .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .annotation(position: .top, spacing: 2) {
                    checkpointAnnotation(cp)
                }
        }
    }

    private func checkpointAnnotation(_ cp: Checkpoint) -> some View {
        VStack(spacing: 0) {
            if cp.hasAidStation {
                Image(systemName: "cross.circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.Colors.success)
            }
            Text(cp.name)
                .font(.system(size: 7))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineLimit(1)
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
            legendDot(color: Theme.Colors.primary.opacity(0.6), label: "Elevation")
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
        let dist = checkpoints.last?.distanceFromStartKm ?? 0
        let distStr = UnitFormatter.formatDistance(dist, unit: units)
        let gain = UnitFormatter.formatElevation(elevationChanges.gainM, unit: units)
        let loss = UnitFormatter.formatElevation(elevationChanges.lossM, unit: units)
        return "Course profile with predicted pace. \(distStr). \(gain) gain, \(loss) loss."
    }
}
