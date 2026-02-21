import Foundation

enum LiveNutritionTracker {

    struct Totals: Equatable, Sendable {
        var totalCalories: Int
        var totalCarbsGrams: Double
        var totalSodiumMg: Int
        var hydrationCount: Int
        var fuelCount: Int
        var electrolyteCount: Int
        var caloriesPerHour: Double
    }

    static func calculateTotals(
        from log: [NutritionIntakeEntry],
        elapsedTime: TimeInterval
    ) -> Totals {
        var calories = 0
        var carbs = 0.0
        var sodium = 0
        var hydration = 0
        var fuel = 0
        var electrolyte = 0

        for entry in log where entry.status == .taken {
            calories += entry.caloriesConsumed ?? defaultCalories(for: entry.reminderType)
            carbs += entry.carbsGramsConsumed ?? 0
            sodium += entry.sodiumMgConsumed ?? 0

            switch entry.reminderType {
            case .hydration: hydration += 1
            case .fuel: fuel += 1
            case .electrolyte: electrolyte += 1
            }
        }

        let hours = max(elapsedTime / 3600.0, 1.0 / 60.0)
        let calPerHour = Double(calories) / hours

        return Totals(
            totalCalories: calories,
            totalCarbsGrams: carbs,
            totalSodiumMg: sodium,
            hydrationCount: hydration,
            fuelCount: fuel,
            electrolyteCount: electrolyte,
            caloriesPerHour: calPerHour
        )
    }

    static func buildManualEntry(
        product: NutritionProduct,
        elapsedTime: TimeInterval,
        quantity: Int = 1
    ) -> NutritionIntakeEntry {
        let reminderType: NutritionReminderType = switch product.type {
        case .drink: .hydration
        case .salt: .electrolyte
        case .gel, .bar, .chew, .realFood: .fuel
        }

        return NutritionIntakeEntry(
            reminderType: reminderType,
            status: .taken,
            elapsedTimeSeconds: elapsedTime,
            message: product.name,
            productId: product.id,
            productName: product.name,
            caloriesConsumed: product.caloriesPerServing * quantity,
            carbsGramsConsumed: product.carbsGramsPerServing * Double(quantity),
            sodiumMgConsumed: product.sodiumMgPerServing * quantity,
            isManualEntry: true
        )
    }

    private static func defaultCalories(for type: NutritionReminderType) -> Int {
        switch type {
        case .fuel: 25
        case .electrolyte: 5
        case .hydration: 0
        }
    }
}
