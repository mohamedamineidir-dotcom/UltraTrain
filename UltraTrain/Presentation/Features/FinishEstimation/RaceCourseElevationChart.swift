import SwiftUI
import Charts

struct RaceCourseElevationChart: View {
    @Environment(\.unitPreference) private var units
    let checkpoints: [Checkpoint]

    private var profilePoints: [ElevationProfilePoint] {
        RaceCourseProfileCalculator.elevationProfile(from: checkpoints)
    }

    private var elevationChanges: (gainM: Double, lossM: Double) {
        RaceCourseProfileCalculator.elevationChanges(from: checkpoints)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Course Profile")
                    .font(.headline)
                Spacer()
                elevationBadges
            }

            chart
                .frame(height: 180)
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(profilePoints) { point in
                AreaMark(
                    x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                    y: .value("Altitude", UnitFormatter.elevationValue(point.altitudeM, unit: units))
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            Theme.Colors.primary.opacity(0.3),
                            Theme.Colors.primary.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                    y: .value("Altitude", UnitFormatter.elevationValue(point.altitudeM, unit: units))
                )
                .foregroundStyle(Theme.Colors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            ForEach(checkpoints) { cp in
                RuleMark(x: .value("CP", UnitFormatter.distanceValue(cp.distanceFromStartKm, unit: units)))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .annotation(position: .top, spacing: 2) {
                        checkpointAnnotation(cp)
                    }
            }
        }
        .chartXAxisLabel("Distance (\(UnitFormatter.distanceLabel(units)))")
        .chartYAxisLabel("Altitude (\(UnitFormatter.elevationShortLabel(units)))")
    }

    // MARK: - Checkpoint Annotation

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

    // MARK: - Elevation Badges

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

    // MARK: - Accessibility

    private var accessibilitySummary: String {
        let gain = elevationChanges.gainM
        let loss = elevationChanges.lossM
        let dist = checkpoints.last?.distanceFromStartKm ?? 0
        return "Course elevation profile. \(UnitFormatter.formatDistance(dist, unit: units, decimals: 0)) with \(UnitFormatter.formatElevation(gain, unit: units)) gain and \(UnitFormatter.formatElevation(loss, unit: units)) loss."
    }
}
