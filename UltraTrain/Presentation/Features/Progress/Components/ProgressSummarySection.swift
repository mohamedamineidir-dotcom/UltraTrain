import SwiftUI

struct ProgressSummarySection: View {
    @Environment(\.unitPreference) private var units
    let totalDistanceKm: Double
    let totalElevationGainM: Double
    let totalRuns: Int
    let averageWeeklyKm: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("8-Week Summary")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Theme.Spacing.md
            ) {
                StatCard(
                    title: "Total Distance",
                    value: String(format: "%.0f", UnitFormatter.distanceValue(totalDistanceKm, unit: units)),
                    unit: UnitFormatter.distanceLabel(units)
                )
                StatCard(
                    title: "Total Elevation",
                    value: String(format: "%.0f", UnitFormatter.elevationValue(totalElevationGainM, unit: units)),
                    unit: UnitFormatter.elevationLabel(units)
                )
                StatCard(
                    title: "Total Runs",
                    value: "\(totalRuns)",
                    unit: "runs"
                )
                StatCard(
                    title: "Avg/Week",
                    value: String(format: "%.1f", UnitFormatter.distanceValue(averageWeeklyKm, unit: units)),
                    unit: UnitFormatter.distanceLabel(units)
                )
            }
        }
    }
}
