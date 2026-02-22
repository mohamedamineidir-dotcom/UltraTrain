import Foundation

enum FoodLogEntryMapper {

    static func toDomain(_ model: FoodLogEntrySwiftDataModel) -> FoodLogEntry? {
        guard let mealType = MealType(rawValue: model.mealTypeRaw) else { return nil }

        return FoodLogEntry(
            id: model.id,
            date: model.date,
            mealType: mealType,
            description: model.entryDescription,
            caloriesEstimate: model.caloriesEstimate,
            carbsGrams: model.carbsGrams,
            proteinGrams: model.proteinGrams,
            fatGrams: model.fatGrams,
            hydrationMl: model.hydrationMl,
            productId: model.productId
        )
    }

    static func toSwiftData(_ entry: FoodLogEntry) -> FoodLogEntrySwiftDataModel {
        FoodLogEntrySwiftDataModel(
            id: entry.id,
            date: entry.date,
            mealTypeRaw: entry.mealType.rawValue,
            entryDescription: entry.description,
            caloriesEstimate: entry.caloriesEstimate,
            carbsGrams: entry.carbsGrams,
            proteinGrams: entry.proteinGrams,
            fatGrams: entry.fatGrams,
            hydrationMl: entry.hydrationMl,
            productId: entry.productId
        )
    }
}
