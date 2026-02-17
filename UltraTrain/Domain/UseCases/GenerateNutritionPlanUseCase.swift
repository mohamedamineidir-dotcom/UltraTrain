import Foundation

protocol GenerateNutritionPlanUseCase: Sendable {
    func execute(
        athlete: Athlete,
        race: Race,
        estimatedDuration: TimeInterval,
        preferences: NutritionPreferences
    ) async throws -> NutritionPlan
}
