import Foundation

protocol GenerateNutritionPlanUseCase: Sendable {
    func execute(
        athlete: Athlete,
        race: Race,
        estimatedDuration: TimeInterval,
        preferences: NutritionPreferences,
        weatherAdjustment: WeatherImpactCalculator.NutritionWeatherAdjustment?
    ) async throws -> NutritionPlan
}

extension GenerateNutritionPlanUseCase {
    func execute(
        athlete: Athlete,
        race: Race,
        estimatedDuration: TimeInterval,
        preferences: NutritionPreferences
    ) async throws -> NutritionPlan {
        try await execute(
            athlete: athlete,
            race: race,
            estimatedDuration: estimatedDuration,
            preferences: preferences,
            weatherAdjustment: nil
        )
    }
}
