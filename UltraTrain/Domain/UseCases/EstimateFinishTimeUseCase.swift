import Foundation

protocol EstimateFinishTimeUseCase: Sendable {
    func execute(
        athlete: Athlete,
        race: Race,
        recentRuns: [CompletedRun],
        currentFitness: FitnessSnapshot?
    ) async throws -> FinishEstimate
}
