import Foundation
@testable import UltraTrain

final class MockEstimateFinishTimeUseCase: EstimateFinishTimeUseCase, @unchecked Sendable {
    var resultEstimate: FinishEstimate?
    var shouldThrow = false

    func execute(
        athlete: Athlete,
        race: Race,
        recentRuns: [CompletedRun],
        currentFitness: FitnessSnapshot?
    ) async throws -> FinishEstimate {
        if shouldThrow {
            throw DomainError.insufficientData(reason: "Mock error")
        }
        guard let result = resultEstimate else {
            throw DomainError.insufficientData(reason: "No mock estimate configured")
        }
        return result
    }
}
