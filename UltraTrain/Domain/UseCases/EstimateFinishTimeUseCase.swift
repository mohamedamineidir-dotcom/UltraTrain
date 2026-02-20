import Foundation

protocol EstimateFinishTimeUseCase: Sendable {
    func execute(
        athlete: Athlete,
        race: Race,
        recentRuns: [CompletedRun],
        currentFitness: FitnessSnapshot?,
        pastRaceCalibrations: [RaceCalibration]
    ) async throws -> FinishEstimate
}

extension EstimateFinishTimeUseCase {
    func execute(
        athlete: Athlete,
        race: Race,
        recentRuns: [CompletedRun],
        currentFitness: FitnessSnapshot?
    ) async throws -> FinishEstimate {
        try await execute(
            athlete: athlete,
            race: race,
            recentRuns: recentRuns,
            currentFitness: currentFitness,
            pastRaceCalibrations: []
        )
    }
}
