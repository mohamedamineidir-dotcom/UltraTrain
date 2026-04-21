import Foundation
@testable import UltraTrain

final class MockGenerateNutritionPlanUseCase: GenerateNutritionPlanUseCase, @unchecked Sendable {
    var result: NutritionPlan?
    var shouldThrow = false
    var executeCallCount = 0
    var lastWeatherAdjustment: WeatherImpactCalculator.NutritionWeatherAdjustment?

    func execute(
        athlete: Athlete,
        race: Race,
        estimatedDuration: TimeInterval,
        preferences: NutritionPreferences,
        weatherAdjustment: WeatherImpactCalculator.NutritionWeatherAdjustment?
    ) async throws -> NutritionPlan {
        executeCallCount += 1
        lastWeatherAdjustment = weatherAdjustment
        if shouldThrow {
            throw DomainError.invalidTrainingPlan(reason: "Mock error")
        }
        if let result {
            return result
        }
        return NutritionPlan(
            id: UUID(),
            raceId: race.id,
            carbsPerHour: 70,
            caloriesPerHour: 280,
            hydrationMlPerHour: 500,
            sodiumMgPerHour: 600,
            totalCaffeineMg: 0,
            entries: [],
            gutTrainingSessionIds: []
        )
    }
}
