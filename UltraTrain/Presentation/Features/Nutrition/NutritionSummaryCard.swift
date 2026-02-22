import SwiftUI

struct NutritionSummaryCard: View {
    let caloriesPerHour: Int
    let hydrationMlPerHour: Int
    let sodiumMgPerHour: Int
    let totalCalories: Int
    let gutTrainingSessions: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Hourly Targets")
                .font(.headline)

            HStack(spacing: Theme.Spacing.sm) {
                StatCard(title: "Calories", value: "\(caloriesPerHour)", unit: "kcal/h")
                StatCard(title: "Hydration", value: "\(hydrationMlPerHour)", unit: "ml/h")
                StatCard(title: "Sodium", value: "\(sodiumMgPerHour)", unit: "mg/h")
            }

            Divider()

            HStack {
                Label("\(totalCalories) kcal total", systemImage: "flame.fill")
                    .font(.subheadline)
                Spacer()
                if gutTrainingSessions > 0 {
                    Label("\(gutTrainingSessions) gut training runs", systemImage: "figure.run")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
        .cardStyle()
        .accessibilityIdentifier("nutrition.summaryCard")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hourly targets: \(caloriesPerHour) kilocalories per hour, \(hydrationMlPerHour) milliliters hydration per hour, \(sodiumMgPerHour) milligrams sodium per hour. Total: \(totalCalories) kilocalories. \(gutTrainingSessions) gut training runs")
    }
}
