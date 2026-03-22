import Foundation

protocol ReframePlanForPreferencesUseCase: Sendable {
    func execute(
        currentPlan: TrainingPlan,
        updatedAthlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race]
    ) async throws -> TrainingPlan?
}
