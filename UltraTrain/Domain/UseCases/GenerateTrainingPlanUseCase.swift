import Foundation

protocol GenerateTrainingPlanUseCase: Sendable {
    func execute(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race]
    ) async throws -> TrainingPlan

    /// Feedback-aware variant. Adapts road intervals / tempo targets from
    /// recent per-rep feedback (IR-2). Default impl ignores feedback and
    /// delegates to the legacy 3-arg method, so existing test mocks
    /// continue to work without changes.
    func execute(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race],
        recentIntervalFeedback: [IntervalPerformanceFeedback]
    ) async throws -> TrainingPlan
}

extension GenerateTrainingPlanUseCase {
    func execute(
        athlete: Athlete,
        targetRace: Race,
        intermediateRaces: [Race],
        recentIntervalFeedback: [IntervalPerformanceFeedback]
    ) async throws -> TrainingPlan {
        try await execute(
            athlete: athlete,
            targetRace: targetRace,
            intermediateRaces: intermediateRaces
        )
    }
}
