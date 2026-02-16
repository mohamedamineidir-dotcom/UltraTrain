import Foundation

protocol CalculateTrainingLoadUseCase: Sendable {
    func execute(
        runs: [CompletedRun],
        plan: TrainingPlan?,
        asOf date: Date
    ) async throws -> TrainingLoadSummary
}
