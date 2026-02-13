import Foundation

protocol GenerateTrainingPlanUseCase: Sendable {
    func execute(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race]
    ) async throws -> TrainingPlan
}
