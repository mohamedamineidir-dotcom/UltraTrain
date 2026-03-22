import Foundation
@testable import UltraTrain

final class MockReframePlanForPreferencesUseCase: ReframePlanForPreferencesUseCase, @unchecked Sendable {
    var result: TrainingPlan?
    var shouldThrow = false
    var executeCallCount = 0
    var lastUpdatedAthlete: Athlete?

    func execute(
        currentPlan: TrainingPlan,
        updatedAthlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race]
    ) async throws -> TrainingPlan? {
        executeCallCount += 1
        lastUpdatedAthlete = updatedAthlete
        if shouldThrow {
            throw DomainError.invalidTrainingPlan(reason: "Mock error")
        }
        return result
    }
}
