import SwiftUI

struct AdvancedMetricsCard: View {
    let metrics: AdvancedRunMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Advanced Metrics")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Theme.Spacing.md
            ) {
                metricTile(
                    label: "Pace Variability",
                    value: String(format: "%.1f%%", metrics.paceVariabilityIndex * 100),
                    color: variabilityColor
                )

                metricTile(
                    label: "GAP",
                    value: RunStatisticsCalculator.formatPace(metrics.averageGradientAdjustedPace) + " /km",
                    color: Theme.Colors.primary
                )

                metricTile(
                    label: "Calories",
                    value: String(format: "%.0f kcal", metrics.estimatedCalories),
                    color: Theme.Colors.warning
                )

                if let efficiency = metrics.climbingEfficiency {
                    metricTile(
                        label: "Climb Efficiency",
                        value: String(format: "%.0f%%", efficiency * 100),
                        color: efficiency < 1.0 ? Theme.Colors.success : Theme.Colors.danger
                    )
                }
            }

            trainingEffectRow
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Subviews

    private func metricTile(label: String, value: String, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var trainingEffectRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("Training Effect")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Spacer()

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(level <= Int(metrics.trainingEffectScore.rounded())
                              ? trainingEffectColor
                              : Theme.Colors.secondaryLabel.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }

            Text(String(format: "%.1f", metrics.trainingEffectScore))
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(trainingEffectColor)
        }
    }

    // MARK: - Colors

    private var variabilityColor: Color {
        switch metrics.paceVariabilityIndex {
        case ..<0.05: return Theme.Colors.success
        case 0.05..<0.10: return Theme.Colors.warning
        default: return Theme.Colors.danger
        }
    }

    private var trainingEffectColor: Color {
        switch metrics.trainingEffectScore {
        case ..<2: return Theme.Colors.secondaryLabel
        case 2..<3.5: return Theme.Colors.success
        case 3.5..<4.5: return Theme.Colors.warning
        default: return Theme.Colors.danger
        }
    }
}
