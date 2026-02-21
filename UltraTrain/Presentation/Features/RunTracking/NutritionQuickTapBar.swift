import SwiftUI

struct NutritionQuickTapBar: View {
    let products: [NutritionProduct]
    let totals: LiveNutritionTracker.Totals?
    let onProductTapped: (NutritionProduct) -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if let totals {
                calorieCounterRow(totals)
            }
            productButtons
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Calorie Counter

    private func calorieCounterRow(_ totals: LiveNutritionTracker.Totals) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Label("\(totals.totalCalories) kcal", systemImage: "flame.fill")
                .foregroundStyle(.orange)
            Spacer()
            Label(String(format: "%.0fg carbs", totals.totalCarbsGrams), systemImage: "leaf.fill")
                .foregroundStyle(.green)
            Spacer()
            Label(String(format: "%.0f kcal/h", totals.caloriesPerHour), systemImage: "clock")
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .font(.caption2)
    }

    // MARK: - Product Buttons

    private var productButtons: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(products.prefix(4)) { product in
                Button {
                    onProductTapped(product)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: iconForType(product.type))
                            .font(.caption)
                            .foregroundStyle(colorForType(product.type))
                        Text(product.name)
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.label)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .fill(colorForType(product.type).opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log \(product.name)")
            }
        }
    }

    // MARK: - Helpers

    private func iconForType(_ type: ProductType) -> String {
        switch type {
        case .gel: "drop.circle.fill"
        case .bar: "rectangle.fill"
        case .drink: "cup.and.saucer.fill"
        case .chew: "circle.grid.2x2.fill"
        case .realFood: "fork.knife"
        case .salt: "leaf.fill"
        }
    }

    private func colorForType(_ type: ProductType) -> Color {
        switch type {
        case .gel: Theme.Colors.warning
        case .bar: .brown
        case .drink: .blue
        case .chew: .purple
        case .realFood: .green
        case .salt: .orange
        }
    }
}
