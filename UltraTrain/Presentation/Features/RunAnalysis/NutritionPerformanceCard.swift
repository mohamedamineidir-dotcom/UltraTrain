import SwiftUI

struct NutritionPerformanceCard: View {
    @Environment(\.unitPreference) private var units

    let analysis: NutritionAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Nutrition Summary")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Theme.Spacing.md
            ) {
                statTile(label: "Adherence", value: String(format: "%.0f%%", analysis.adherencePercent))
                statTile(label: "Calories", value: String(format: "%.0f kcal", analysis.totalCaloriesConsumed))
            }

            adherenceBar

            if let impact = analysis.performanceImpact {
                performanceImpactRow(impact: impact)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Subviews

    private func statTile(label: String, value: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity)
    }

    private var adherenceBar: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text("Intake Adherence")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Spacer()
                Text(String(format: "%.0f%%", analysis.adherencePercent))
                    .font(.caption.bold())
                    .foregroundStyle(adherenceColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.secondaryLabel.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(adherenceColor)
                        .frame(width: geometry.size.width * min(analysis.adherencePercent / 100, 1.0))
                }
            }
            .frame(height: 8)
        }
    }

    private func performanceImpactRow(impact: NutritionPerformanceImpact) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Before First Intake")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(RunStatisticsCalculator.formatPace(impact.averagePaceBeforeFirstIntake, unit: units) + " " + UnitFormatter.paceLabel(units))
                    .font(.subheadline.monospacedDigit())
            }

            Spacer()

            Image(systemName: "arrow.right")
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("After Last Intake")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(RunStatisticsCalculator.formatPace(impact.averagePaceAfterLastIntake, unit: units) + " " + UnitFormatter.paceLabel(units))
                    .font(.subheadline.monospacedDigit())
            }

            paceChangeIndicator(impact.paceChangePercent)
        }
    }

    private func paceChangeIndicator(_ changePercent: Double) -> some View {
        let isImproved = changePercent < 0
        return HStack(spacing: 2) {
            Image(systemName: isImproved ? "arrow.up.right" : "arrow.down.right")
            Text(String(format: "%.1f%%", abs(changePercent)))
        }
        .font(.caption.bold())
        .foregroundStyle(isImproved ? Theme.Colors.success : Theme.Colors.danger)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule().fill((isImproved ? Theme.Colors.success : Theme.Colors.danger).opacity(0.15))
        )
    }

    // MARK: - Helpers

    private var adherenceColor: Color {
        switch analysis.adherencePercent {
        case 80...: return Theme.Colors.success
        case 50..<80: return Theme.Colors.warning
        default: return Theme.Colors.danger
        }
    }
}
