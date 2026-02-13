import Foundation
import os

@Observable
@MainActor
final class FinishEstimationViewModel {

    // MARK: - Dependencies

    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let athleteRepository: any AthleteRepository
    private let runRepository: any RunRepository
    private let fitnessCalculator: any CalculateFitnessUseCase

    // MARK: - State

    let race: Race
    var estimate: FinishEstimate?
    var isLoading = false
    var error: String?

    // MARK: - Init

    init(
        race: Race,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        athleteRepository: any AthleteRepository,
        runRepository: any RunRepository,
        fitnessCalculator: any CalculateFitnessUseCase
    ) {
        self.race = race
        self.finishTimeEstimator = finishTimeEstimator
        self.athleteRepository = athleteRepository
        self.runRepository = runRepository
        self.fitnessCalculator = fitnessCalculator
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                error = "Athlete profile not found"
                isLoading = false
                return
            }

            let runs = try await runRepository.getRuns(for: athlete.id)
            guard !runs.isEmpty else {
                error = "Complete some runs first to get a finish time estimate"
                isLoading = false
                return
            }

            var fitness: FitnessSnapshot?
            do {
                fitness = try await fitnessCalculator.execute(runs: runs, asOf: .now)
            } catch {
                Logger.fitness.warning("Could not calculate fitness for estimation: \(error)")
            }

            estimate = try await finishTimeEstimator.execute(
                athlete: athlete,
                race: race,
                recentRuns: runs,
                currentFitness: fitness
            )
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to estimate finish time: \(error)")
        }

        isLoading = false
    }
}
