import Foundation

protocol SessionNutritionAdvisor: Sendable {
    func advise(
        for session: TrainingSession,
        athleteWeightKg: Double,
        experienceLevel: ExperienceLevel
    ) -> SessionNutritionAdvice?
}
