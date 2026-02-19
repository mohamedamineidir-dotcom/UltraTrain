import SwiftUI

struct PlanComparisonCard: View {
    @Environment(\.unitPreference) private var units

    let comparison: PlanComparison

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Plan Comparison")
                    .font(.headline)
                Spacer()
                Text(comparison.sessionType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            header

            comparisonRow(
                label: "Distance",
                planned: UnitFormatter.formatDistance(comparison.plannedDistanceKm, unit: units),
                actual: UnitFormatter.formatDistance(comparison.actualDistanceKm, unit: units),
                targetMet: comparison.actualDistanceKm >= comparison.plannedDistanceKm * 0.9
            )

            Divider()

            comparisonRow(
                label: "Elevation",
                planned: UnitFormatter.formatElevation(comparison.plannedElevationGainM, unit: units),
                actual: UnitFormatter.formatElevation(comparison.actualElevationGainM, unit: units),
                targetMet: comparison.actualElevationGainM >= comparison.plannedElevationGainM * 0.9
            )

            Divider()

            comparisonRow(
                label: "Duration",
                planned: RunStatisticsCalculator.formatDuration(comparison.plannedDuration),
                actual: RunStatisticsCalculator.formatDuration(comparison.actualDuration),
                targetMet: comparison.actualDuration <= comparison.plannedDuration * 1.1
            )

            Divider()

            comparisonRow(
                label: "Pace",
                planned: RunStatisticsCalculator.formatPace(comparison.plannedPaceSecondsPerKm, unit: units),
                actual: RunStatisticsCalculator.formatPace(comparison.actualPaceSecondsPerKm, unit: units),
                targetMet: comparison.actualPaceSecondsPerKm <= comparison.plannedPaceSecondsPerKm * 1.1
            )
        }
        .cardStyle()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Planned")
                .font(.caption.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 80, alignment: .trailing)
            Text("Actual")
                .font(.caption.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 80, alignment: .trailing)
        }
    }

    // MARK: - Row

    private func comparisonRow(
        label: String,
        planned: String,
        actual: String,
        targetMet: Bool
    ) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(planned)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 80, alignment: .trailing)
            Text(actual)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(targetMet ? Theme.Colors.success : Theme.Colors.warning)
                .frame(width: 80, alignment: .trailing)
        }
    }
}
