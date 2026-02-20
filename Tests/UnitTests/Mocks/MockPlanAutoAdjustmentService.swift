import Foundation
@testable import UltraTrain

final class MockPlanAutoAdjustmentService: PlanAutoAdjustmentService, @unchecked Sendable {
    var adjustedPlan: TrainingPlan?
    var shouldThrow = false
    var adjustCallCount = 0

    func adjustPlanIfNeeded(
        currentPlan: TrainingPlan,
        currentRaces: [Race],
        athlete: Athlete,
        targetRace: Race
    ) async throws -> TrainingPlan? {
        adjustCallCount += 1
        if shouldThrow { throw DomainError.invalidTrainingPlan(reason: "Mock error") }
        return adjustedPlan
    }
}
