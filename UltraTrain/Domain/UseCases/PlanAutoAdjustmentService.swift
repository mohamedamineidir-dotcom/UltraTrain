import Foundation

protocol PlanAutoAdjustmentService: Sendable {
    func adjustPlanIfNeeded(
        currentPlan: TrainingPlan,
        currentRaces: [Race],
        athlete: Athlete,
        targetRace: Race
    ) async throws -> TrainingPlan?
}
