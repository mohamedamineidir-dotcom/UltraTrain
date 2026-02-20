import Foundation
import os

@Observable
@MainActor
final class RaceDayPlanViewModel {

    // MARK: - Dependencies

    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let athleteRepository: any AthleteRepository
    private let runRepository: any RunRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let nutritionRepository: any NutritionRepository
    private let nutritionGenerator: any GenerateNutritionPlanUseCase

    // MARK: - State

    let race: Race
    var estimate: FinishEstimate?
    var nutritionPlan: NutritionPlan?
    var segments: [RaceDaySegment] = []
    var isLoading = false
    var error: String?

    // MARK: - Init

    init(
        race: Race,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        athleteRepository: any AthleteRepository,
        runRepository: any RunRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        nutritionRepository: any NutritionRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase
    ) {
        self.race = race
        self.finishTimeEstimator = finishTimeEstimator
        self.athleteRepository = athleteRepository
        self.runRepository = runRepository
        self.fitnessCalculator = fitnessCalculator
        self.nutritionRepository = nutritionRepository
        self.nutritionGenerator = nutritionGenerator
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
                error = "Complete some runs first to build a race day plan"
                isLoading = false
                return
            }

            var fitness: FitnessSnapshot?
            do {
                fitness = try await fitnessCalculator.execute(runs: runs, asOf: .now)
            } catch {
                Logger.fitness.warning("Could not calculate fitness for race day plan: \(error)")
            }

            let finishEstimate = try await finishTimeEstimator.execute(
                athlete: athlete,
                race: race,
                recentRuns: runs,
                currentFitness: fitness
            )
            estimate = finishEstimate

            var plan = try await nutritionRepository.getNutritionPlan(for: race.id)
            if plan == nil {
                let preferences = try await nutritionRepository.getNutritionPreferences()
                plan = try await nutritionGenerator.execute(
                    athlete: athlete,
                    race: race,
                    estimatedDuration: finishEstimate.expectedTime,
                    preferences: preferences
                )
            }
            nutritionPlan = plan

            segments = buildSegments(
                splits: finishEstimate.checkpointSplits,
                entries: plan?.entries ?? [],
                plan: plan
            )
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to build race day plan: \(error)")
        }

        isLoading = false
    }

    // MARK: - Build Segments

    func buildSegments(
        splits: [CheckpointSplit],
        entries: [NutritionEntry],
        plan: NutritionPlan?
    ) -> [RaceDaySegment] {
        guard !splits.isEmpty else { return [] }

        var result: [RaceDaySegment] = []
        var cumulativeCalories = 0
        var cumulativeHydrationMl = 0
        var cumulativeSodiumMg = 0
        var previousExpectedTime: TimeInterval = 0

        for split in splits {
            let windowStartMinutes = Int(previousExpectedTime / 60)
            let windowEndMinutes = Int(split.expectedTime / 60)

            let segmentEntries = entries.filter { entry in
                entry.timingMinutes >= windowStartMinutes && entry.timingMinutes < windowEndMinutes
            }

            for entry in segmentEntries {
                cumulativeCalories += entry.product.caloriesPerServing * entry.quantity
                cumulativeSodiumMg += entry.product.sodiumMgPerServing * entry.quantity
                if entry.product.type == .drink {
                    cumulativeHydrationMl += (plan?.hydrationMlPerHour ?? 500) / 3
                }
            }

            let segmentDuration = split.expectedTime - previousExpectedTime
            let arrivalTime = race.date.addingTimeInterval(split.expectedTime)

            result.append(RaceDaySegment(
                id: UUID(),
                checkpointName: split.checkpointName,
                distanceFromStartKm: split.distanceFromStartKm,
                segmentDistanceKm: split.segmentDistanceKm,
                segmentElevationGainM: split.segmentElevationGainM,
                hasAidStation: split.hasAidStation,
                expectedArrivalTime: arrivalTime,
                expectedCumulativeTime: split.expectedTime,
                expectedSegmentDuration: segmentDuration,
                nutritionEntries: segmentEntries,
                cumulativeCalories: cumulativeCalories,
                cumulativeHydrationMl: cumulativeHydrationMl,
                cumulativeSodiumMg: cumulativeSodiumMg
            ))

            previousExpectedTime = split.expectedTime
        }

        return result
    }
}
