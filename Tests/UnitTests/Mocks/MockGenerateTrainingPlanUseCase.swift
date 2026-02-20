import Foundation
@testable import UltraTrain

final class MockGenerateTrainingPlanUseCase: GenerateTrainingPlanUseCase, @unchecked Sendable {
    var result: TrainingPlan?
    var shouldThrow = false
    var executeCallCount = 0

    func execute(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race]
    ) async throws -> TrainingPlan {
        executeCallCount += 1
        if shouldThrow {
            throw DomainError.invalidTrainingPlan(reason: "Mock error")
        }
        if let result {
            return result
        }
        // Return a minimal plan
        return TrainingPlan(
            id: UUID(),
            athleteId: athlete.id,
            targetRaceId: targetRace.id,
            createdAt: .now,
            weeks: [],
            intermediateRaceIds: intermediateRaces.map(\.id),
            intermediateRaceSnapshots: []
        )
    }
}
