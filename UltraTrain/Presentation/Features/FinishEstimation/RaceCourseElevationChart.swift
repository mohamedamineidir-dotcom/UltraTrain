import SwiftUI
import Charts

struct RaceCourseElevationChart: View {
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
                    x: .value("Distance", point.distanceKm),
                    y: .value("Altitude", point.altitudeM)
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
                    x: .value("Distance", point.distanceKm),
                    y: .value("Altitude", point.altitudeM)
                )
                .foregroundStyle(Theme.Colors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            ForEach(checkpoints) { cp in
                RuleMark(x: .value("CP", cp.distanceFromStartKm))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .annotation(position: .top, spacing: 2) {
                        checkpointAnnotation(cp)
                    }
            }
        }
        .chartXAxisLabel("Distance (km)")
        .chartYAxisLabel("Altitude (m)")
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
                String(format: "+%.0f m", elevationChanges.gainM),
                systemImage: "arrow.up.right"
            )
            .foregroundStyle(Theme.Colors.danger)

            Label(
                String(format: "-%.0f m", elevationChanges.lossM),
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
        return "Course elevation profile. \(String(format: "%.0f", dist)) km with \(Int(gain)) meters gain and \(Int(loss)) meters loss."
    }
}
