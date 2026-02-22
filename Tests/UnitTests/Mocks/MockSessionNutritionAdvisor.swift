import Foundation
@testable import UltraTrain

final class MockSessionNutritionAdvisor: SessionNutritionAdvisor, @unchecked Sendable {
    var adviceToReturn: SessionNutritionAdvice?

    func advise(
        for session: TrainingSession,
        athleteWeightKg: Double,
        experienceLevel: ExperienceLevel,
        preferences: NutritionPreferences
    ) -> SessionNutritionAdvice? {
        adviceToReturn
    }
}
