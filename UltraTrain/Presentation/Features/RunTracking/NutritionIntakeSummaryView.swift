import SwiftUI

struct NutritionIntakeSummaryView: View {
    let summary: NutritionIntakeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Nutrition")
                .font(.headline)

            HStack(spacing: Theme.Spacing.md) {
                intakeColumn(icon: "drop.fill", color: .blue, label: "Hydration", count: summary.hydrationTakenCount)
                intakeColumn(icon: "bolt.fill", color: Theme.Colors.warning, label: "Fuel", count: summary.fuelTakenCount)
                intakeColumn(icon: "leaf.fill", color: .green, label: "Electrolyte", count: summary.electrolyteTakenCount)
            }

            if totalCalories > 0 {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    Text("~\(totalCalories) kcal consumed")
                        .foregroundStyle(Theme.Colors.label)
                }
                .font(.caption)
            }

            HStack(spacing: Theme.Spacing.lg) {
                statusLabel(count: summary.takenCount, label: "Taken", color: Theme.Colors.success)
                statusLabel(count: summary.skippedCount, label: "Skipped", color: Theme.Colors.danger)
                statusLabel(count: summary.pendingCount, label: "Missed", color: Theme.Colors.secondaryLabel)
            }
            .font(.caption)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var totalCalories: Int {
        summary.entries
            .filter { $0.status == .taken }
            .compactMap(\.caloriesConsumed)
            .reduce(0, +)
    }

    private func intakeColumn(icon: String, color: Color, label: String, count: Int) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text("\(count)")
                .font(.title3.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(count) taken")
    }

    private func statusLabel(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text("\(count) \(label)")
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}
