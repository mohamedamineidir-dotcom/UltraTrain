import Foundation

enum RaceCalibrationService {
    static func recalibrateEstimates(
        completedRace: Race,
        actualTime: TimeInterval,
        allRaces: [Race],
        finishEstimateRepository: any FinishEstimateRepository,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        athlete: Athlete,
        recentRuns: [CompletedRun]
    ) async throws {
        var calibrations: [RaceCalibration] = []
        for race in allRaces where race.isCompleted {
            if let existingEstimate = try? await finishEstimateRepository.getEstimate(for: race.id),
               let actual = race.actualFinishTime {
                calibrations.append(RaceCalibration(
                    raceId: race.id,
                    predictedTime: existingEstimate.expectedTime,
                    actualTime: actual,
                    raceDistanceKm: race.distanceKm,
                    raceElevationGainM: race.elevationGainM
                ))
            }
        }

        let upcomingRaces = allRaces.filter { !$0.isCompleted }
        for race in upcomingRaces {
            let newEstimate = try await finishTimeEstimator.execute(
                athlete: athlete,
                race: race,
                recentRuns: recentRuns,
                currentFitness: nil,
                pastRaceCalibrations: calibrations
            )
            try await finishEstimateRepository.saveEstimate(newEstimate)
        }
    }
}
