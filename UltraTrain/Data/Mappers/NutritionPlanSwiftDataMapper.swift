import Foundation

enum NutritionPlanSwiftDataMapper {

    // MARK: - To Domain

    static func toDomain(_ model: NutritionPlanSwiftDataModel) -> NutritionPlan? {
        let entries = model.entries
            .sorted { $0.timingMinutes < $1.timingMinutes }
            .compactMap { entryToDomain($0) }

        guard entries.count == model.entries.count else { return nil }

        return NutritionPlan(
            id: model.id,
            raceId: model.raceId,
            caloriesPerHour: model.caloriesPerHour,
            hydrationMlPerHour: model.hydrationMlPerHour,
            sodiumMgPerHour: model.sodiumMgPerHour,
            entries: entries,
            gutTrainingSessionIds: model.gutTrainingSessionIds
        )
    }

    static func entryToDomain(_ model: NutritionEntrySwiftDataModel) -> NutritionEntry? {
        guard let productType = ProductType(rawValue: model.productTypeRaw) else { return nil }

        let product = NutritionProduct(
            id: model.productId,
            name: model.productName,
            type: productType,
            caloriesPerServing: model.productCaloriesPerServing,
            carbsGramsPerServing: model.productCarbsGramsPerServing,
            sodiumMgPerServing: model.productSodiumMgPerServing,
            caffeinated: model.productCaffeinated
        )

        return NutritionEntry(
            id: model.id,
            product: product,
            timingMinutes: model.timingMinutes,
            quantity: model.quantity,
            notes: model.notes
        )
    }

    static func productToDomain(_ model: NutritionProductSwiftDataModel) -> NutritionProduct? {
        guard let type = ProductType(rawValue: model.typeRaw) else { return nil }
        return NutritionProduct(
            id: model.id,
            name: model.name,
            type: type,
            caloriesPerServing: model.caloriesPerServing,
            carbsGramsPerServing: model.carbsGramsPerServing,
            sodiumMgPerServing: model.sodiumMgPerServing,
            caffeinated: model.caffeinated
        )
    }

    // MARK: - To SwiftData

    static func toSwiftData(_ plan: NutritionPlan) -> NutritionPlanSwiftDataModel {
        let entryModels = plan.entries.map { entryToSwiftData($0) }
        return NutritionPlanSwiftDataModel(
            id: plan.id,
            raceId: plan.raceId,
            caloriesPerHour: plan.caloriesPerHour,
            hydrationMlPerHour: plan.hydrationMlPerHour,
            sodiumMgPerHour: plan.sodiumMgPerHour,
            entries: entryModels,
            gutTrainingSessionIds: plan.gutTrainingSessionIds
        )
    }

    static func entryToSwiftData(_ entry: NutritionEntry) -> NutritionEntrySwiftDataModel {
        NutritionEntrySwiftDataModel(
            id: entry.id,
            productId: entry.product.id,
            productName: entry.product.name,
            productTypeRaw: entry.product.type.rawValue,
            productCaloriesPerServing: entry.product.caloriesPerServing,
            productCarbsGramsPerServing: entry.product.carbsGramsPerServing,
            productSodiumMgPerServing: entry.product.sodiumMgPerServing,
            productCaffeinated: entry.product.caffeinated,
            timingMinutes: entry.timingMinutes,
            quantity: entry.quantity,
            notes: entry.notes
        )
    }

    static func productToSwiftData(_ product: NutritionProduct) -> NutritionProductSwiftDataModel {
        NutritionProductSwiftDataModel(
            id: product.id,
            name: product.name,
            typeRaw: product.type.rawValue,
            caloriesPerServing: product.caloriesPerServing,
            carbsGramsPerServing: product.carbsGramsPerServing,
            sodiumMgPerServing: product.sodiumMgPerServing,
            caffeinated: product.caffeinated
        )
    }
}
