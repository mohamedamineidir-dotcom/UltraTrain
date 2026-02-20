import Foundation
@testable import UltraTrain

final class MockEstimateFinishTimeUseCase: EstimateFinishTimeUseCase, @unchecked Sendable {
    var resultEstimate: FinishEstimate?
    var shouldThrow = false
    var lastCalibrations: [RaceCalibration] = []

    func execute(
        athlete: Athlete,
        race: Race,
        recentRuns: [CompletedRun],
        currentFitness: FitnessSnapshot?,
        pastRaceCalibrations: [RaceCalibration]
    ) async throws -> FinishEstimate {
        lastCalibrations = pastRaceCalibrations
        if shouldThrow {
            throw DomainError.insufficientData(reason: "Mock error")
        }
        guard let result = resultEstimate else {
            throw DomainError.insufficientData(reason: "No mock estimate configured")
        }
        return result
    }
}
