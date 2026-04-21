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
                Text("Weekly Progress")
                    .font(.headline)
                Spacer()
                if progress.total > 0 {
                    Text("\(progress.completed)/\(progress.total) sessions")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(Theme.Colors.accentColor)
                }
            }

            HStack(spacing: Theme.Spacing.md) {
                if targetDistanceKm > 0 {
                    WeeklyProgressRing(actual: distanceKm, target: targetDistanceKm)
                }

                HStack(spacing: Theme.Spacing.sm) {
                    statPill(
                        icon: "figure.run",
                        value: String(format: "%.1f", UnitFormatter.distanceValue(distanceKm, unit: units)),
                        unit: UnitFormatter.distanceLabel(units),
                        target: targetDistanceKm > 0
                            ? UnitFormatter.formatDistance(targetDistanceKm, unit: units, decimals: 0)
                            : nil
                    )
                    statPill(
                        icon: "mountain.2.fill",
                        value: String(format: "%.0f", UnitFormatter.elevationValue(elevationM, unit: units)),
                        unit: UnitFormatter.elevationLabel(units),
                        target: targetElevationM > 0
                            ? UnitFormatter.formatElevation(targetElevationM, unit: units)
                            : nil
                    )
                }
            }

            if let weeksLeft = weeksUntilRace {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "flag.checkered")
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text("\(weeksLeft) weeks until race day")
                        .font(.caption)
                }
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .futuristicGlassStyle()
    }

    private func statPill(icon: String, value: String, unit: String, target: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.accentColor)
                Spacer(minLength: 0)
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold).monospacedDigit())
                    .foregroundStyle(Theme.Colors.label)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            if let target {
                Text("of \(target)")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.7))
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm)
        .background(.ultraThinMaterial)
        .overlay(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }
}
