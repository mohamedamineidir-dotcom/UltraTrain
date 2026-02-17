import Foundation
@testable import UltraTrain

final class MockNutritionRepository: NutritionRepository, @unchecked Sendable {
    var savedPlan: NutritionPlan?
    var plans: [UUID: NutritionPlan] = [:]
    var savedProducts: [NutritionProduct] = []
    var savedPreferences: NutritionPreferences?
    var shouldThrow = false

    func getNutritionPlan(for raceId: UUID) async throws -> NutritionPlan? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return plans[raceId]
    }

    func saveNutritionPlan(_ plan: NutritionPlan) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedPlan = plan
        plans[plan.raceId] = plan
    }

    func updateNutritionPlan(_ plan: NutritionPlan) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedPlan = plan
        plans[plan.raceId] = plan
    }

    func getProducts() async throws -> [NutritionProduct] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return savedProducts
    }

    func saveProduct(_ product: NutritionProduct) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedProducts.append(product)
    }

    func getNutritionPreferences() async throws -> NutritionPreferences {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return savedPreferences ?? .default
    }

    func saveNutritionPreferences(_ preferences: NutritionPreferences) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedPreferences = preferences
    }
}
