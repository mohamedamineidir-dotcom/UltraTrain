import SwiftUI
import Charts

struct RouteComparisonView: View {
    @Environment(\.unitPreference) private var units
    let routeA: SavedRoute
    let routeB: SavedRoute

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                statsComparison
                elevationOverlay
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .navigationTitle("Compare Routes")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stats Comparison

    private var statsComparison: some View {
        VStack(spacing: Theme.Spacing.md) {
            comparisonRow(
                label: "Name",
                valueA: routeA.name,
                valueB: routeB.name
            )
            comparisonRow(
                label: "Distance",
                valueA: UnitFormatter.formatDistance(routeA.distanceKm, unit: units, decimals: 1),
                valueB: UnitFormatter.formatDistance(routeB.distanceKm, unit: units, decimals: 1)
            )
            comparisonRow(
                label: "D+",
                valueA: "+" + UnitFormatter.formatElevation(routeA.elevationGainM, unit: units),
                valueB: "+" + UnitFormatter.formatElevation(routeB.elevationGainM, unit: units)
            )
            comparisonRow(
                label: "D-",
                valueA: "-" + UnitFormatter.formatElevation(routeA.elevationLossM, unit: units),
                valueB: "-" + UnitFormatter.formatElevation(routeB.elevationLossM, unit: units)
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func comparisonRow(label: String, valueA: String, valueB: String) -> some View {
        HStack {
            Text(valueA)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 70)
            Text(valueB)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Elevation Overlay

    private var elevationOverlay: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Elevation Profiles")
                .font(.headline)
                .padding(.horizontal, Theme.Spacing.md)

            let profileA = ElevationCalculator.elevationProfile(from: routeA.courseRoute)
            let profileB = ElevationCalculator.elevationProfile(from: routeB.courseRoute)

            Chart {
                ForEach(profileA, id: \.distanceKm) { point in
                    LineMark(
                        x: .value("Distance", point.distanceKm),
                        y: .value("Altitude", point.altitudeM),
                        series: .value("Route", routeA.name)
                    )
                    .foregroundStyle(.blue)
                }
                ForEach(profileB, id: \.distanceKm) { point in
                    LineMark(
                        x: .value("Distance", point.distanceKm),
                        y: .value("Altitude", point.altitudeM),
                        series: .value("Route", routeB.name)
                    )
                    .foregroundStyle(.orange)
                }
            }
            .chartXAxisLabel("Distance (km)")
            .chartYAxisLabel("Altitude (m)")
            .frame(height: 200)
            .padding(.horizontal, Theme.Spacing.md)

            HStack(spacing: Theme.Spacing.md) {
                Label(routeA.name, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Label(routeB.name, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}
