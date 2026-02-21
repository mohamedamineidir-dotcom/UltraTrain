import Foundation
@testable import UltraTrain

final class MockEstimateFinishTimeUseCase: EstimateFinishTimeUseCase, @unchecked Sendable {
    var resultEstimate: FinishEstimate?
    var shouldThrow = false
    var lastCalibrations: [RaceCalibration] = []
    var lastWeatherImpact: WeatherImpactCalculator.WeatherImpact?

    func execute(
        athlete: Athlete,
        race: Race,
        recentRuns: [CompletedRun],
        currentFitness: FitnessSnapshot?,
        pastRaceCalibrations: [RaceCalibration],
        weatherImpact: WeatherImpactCalculator.WeatherImpact?
    ) async throws -> FinishEstimate {
        lastCalibrations = pastRaceCalibrations
        lastWeatherImpact = weatherImpact
        if shouldThrow {
            throw DomainError.insufficientData(reason: "Mock error")
        }
        guard let result = resultEstimate else {
            throw DomainError.insufficientData(reason: "No mock estimate configured")
        }
        return result
    }
}
