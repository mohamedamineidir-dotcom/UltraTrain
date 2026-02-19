import SwiftUI

struct DashboardWeeklyStatsCard: View {
    @Environment(\.unitPreference) private var units
    let progress: (completed: Int, total: Int)
    let distanceKm: Double
    let elevationM: Double
    let targetDistanceKm: Double
    let targetElevationM: Double
    let weeksUntilRace: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
                if progress.total > 0 {
                    Text("\(progress.completed)/\(progress.total) sessions")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            HStack(spacing: Theme.Spacing.md) {
                if targetDistanceKm > 0 {
                    WeeklyProgressRing(actual: distanceKm, target: targetDistanceKm)
                }

                VStack(spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.md) {
                        StatCard(
                            title: "Distance",
                            value: String(format: "%.1f", UnitFormatter.distanceValue(distanceKm, unit: units)),
                            unit: UnitFormatter.distanceLabel(units)
                        )
                        StatCard(
                            title: "Elevation",
                            value: String(format: "%.0f", UnitFormatter.elevationValue(elevationM, unit: units)),
                            unit: UnitFormatter.elevationLabel(units)
                        )
                    }
                }
            }

            if targetDistanceKm > 0 {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "target")
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text("Target: \(UnitFormatter.formatDistance(targetDistanceKm, unit: units, decimals: 0)) · \(UnitFormatter.formatElevation(targetElevationM, unit: units)) D+")
                        .font(.caption)
                }
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            if let weeksLeft = weeksUntilRace {
                HStack {
                    Image(systemName: "flag.checkered")
                        .accessibilityHidden(true)
                    Text("\(weeksLeft) weeks until race day")
                        .font(.caption)
                }
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }
}
