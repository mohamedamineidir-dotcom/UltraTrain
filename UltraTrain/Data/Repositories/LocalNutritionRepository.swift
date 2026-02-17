import Foundation
import SwiftData
import os

final class LocalNutritionRepository: NutritionRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getNutritionPlan(for raceId: UUID) async throws -> NutritionPlan? {
        let context = ModelContext(modelContainer)
        let targetRaceId = raceId
        var descriptor = FetchDescriptor<NutritionPlanSwiftDataModel>(
            predicate: #Predicate { $0.raceId == targetRaceId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else { return nil }
        guard let plan = NutritionPlanSwiftDataMapper.toDomain(model) else {
            throw DomainError.persistenceError(message: "Failed to map stored nutrition plan data")
        }
        return plan
    }

    func saveNutritionPlan(_ plan: NutritionPlan) async throws {
        let context = ModelContext(modelContainer)

        let targetRaceId = plan.raceId
        let existing = FetchDescriptor<NutritionPlanSwiftDataModel>(
            predicate: #Predicate { $0.raceId == targetRaceId }
        )
        for old in try context.fetch(existing) {
            context.delete(old)
        }

        let model = NutritionPlanSwiftDataMapper.toSwiftData(plan)
        context.insert(model)
        try context.save()
        Logger.nutrition.info("Nutrition plan saved with \(plan.entries.count) entries")
    }

    func updateNutritionPlan(_ plan: NutritionPlan) async throws {
        let context = ModelContext(modelContainer)
        let targetId = plan.id
        var descriptor = FetchDescriptor<NutritionPlanSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.nutritionPlanNotFound
        }

        context.delete(existing)
        let model = NutritionPlanSwiftDataMapper.toSwiftData(plan)
        context.insert(model)
        try context.save()
        Logger.nutrition.info("Nutrition plan updated")
    }

    func getProducts() async throws -> [NutritionProduct] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<NutritionProductSwiftDataModel>(
            sortBy: [SortDescriptor(\.name)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { NutritionPlanSwiftDataMapper.productToDomain($0) }
    }

    func saveProduct(_ product: NutritionProduct) async throws {
        let context = ModelContext(modelContainer)
        let model = NutritionPlanSwiftDataMapper.productToSwiftData(product)
        context.insert(model)
        try context.save()
        Logger.nutrition.info("Product saved: \(product.name)")
    }

    func getNutritionPreferences() async throws -> NutritionPreferences {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<NutritionPreferencesSwiftDataModel>()
        guard let model = try context.fetch(descriptor).first else {
            return .default
        }
        return NutritionPreferencesMapper.toDomain(model)
    }

    func saveNutritionPreferences(_ preferences: NutritionPreferences) async throws {
        let context = ModelContext(modelContainer)
        let existing = FetchDescriptor<NutritionPreferencesSwiftDataModel>()
        for old in try context.fetch(existing) {
            context.delete(old)
        }
        let model = NutritionPreferencesMapper.toSwiftData(preferences)
        context.insert(model)
        try context.save()
        Logger.nutrition.info("Nutrition preferences saved")
    }
}
