import SwiftUI
import Charts

struct CourseRouteElevationChart: View {
    @Environment(\.unitPreference) private var units

    let courseRoute: [TrackPoint]

    private var profilePoints: [ElevationProfilePoint] {
        ElevationCalculator.elevationProfile(from: courseRoute)
    }

    private var altitudes: [Double] {
        profilePoints.map(\.altitudeM)
    }

    private var minAltitude: Double { altitudes.min() ?? 0 }
    private var maxAltitude: Double { altitudes.max() ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Elevation Profile")
                .font(.headline)

            chart
                .frame(height: 180)

            elevationLabels
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
                .foregroundStyle(elevationGradient)

                LineMark(
                    x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                    y: .value("Altitude", UnitFormatter.elevationValue(point.altitudeM, unit: units))
                )
                .foregroundStyle(Theme.Colors.success)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxisLabel("Distance (\(UnitFormatter.distanceLabel(units)))")
        .chartYAxisLabel("Altitude (\(UnitFormatter.elevationShortLabel(units)))")
    }

    // MARK: - Gradient

    private var elevationGradient: LinearGradient {
        .linearGradient(
            colors: [
                Theme.Colors.success.opacity(0.35),
                Theme.Colors.success.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Labels

    private var elevationLabels: some View {
        HStack(spacing: Theme.Spacing.lg) {
            labelItem(
                title: "Min",
                value: UnitFormatter.formatElevation(minAltitude, unit: units),
                color: Theme.Colors.success
            )
            labelItem(
                title: "Max",
                value: UnitFormatter.formatElevation(maxAltitude, unit: units),
                color: Theme.Colors.danger
            )
        }
    }

    private func labelItem(title: String, value: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(title): \(value)")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Accessibility

    private var accessibilitySummary: String {
        let totalDist = profilePoints.last?.distanceKm ?? 0
        let distStr = UnitFormatter.formatDistance(totalDist, unit: units)
        let minStr = UnitFormatter.formatElevation(minAltitude, unit: units)
        let maxStr = UnitFormatter.formatElevation(maxAltitude, unit: units)
        return "Course elevation profile. \(distStr). Altitude from \(minStr) to \(maxStr)."
    }
}
