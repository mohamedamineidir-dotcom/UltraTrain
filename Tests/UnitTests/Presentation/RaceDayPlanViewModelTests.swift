import Foundation
import Testing
@testable import UltraTrain

@Suite("RaceDayPlan ViewModel Tests")
struct RaceDayPlanViewModelTests {

    private let race = Race(
        id: UUID(),
        name: "Test Ultra",
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 6))!,
        distanceKm: 50,
        elevationGainM: 3000,
        elevationLossM: 3000,
        priority: .aRace,
        goalType: .finish,
        checkpoints: [
            Checkpoint(id: UUID(), name: "CP1", distanceFromStartKm: 15, elevationM: 800, hasAidStation: true),
            Checkpoint(id: UUID(), name: "CP2", distanceFromStartKm: 30, elevationM: 1500, hasAidStation: true),
            Checkpoint(id: UUID(), name: "CP3", distanceFromStartKm: 45, elevationM: 600, hasAidStation: false)
        ],
        terrainDifficulty: .moderate
    )

    private let athlete = Athlete(
        id: UUID(),
        firstName: "Test",
        lastName: "Runner",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
        weightKg: 70,
        heightCm: 175,
        restingHeartRate: 50,
        maxHeartRate: 185,
        experienceLevel: .intermediate,
        weeklyVolumeKm: 50,
        longestRunKm: 30,
        preferredUnit: .metric
    )

    private func makeRun() -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athlete.id,
            date: .now,
            distanceKm: 15,
            elevationGainM: 500,
            elevationLossM: 500,
            duration: 5400,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeProduct(name: String, type: ProductType, calories: Int, sodium: Int) -> NutritionProduct {
        NutritionProduct(
            id: UUID(),
            name: name,
            type: type,
            caloriesPerServing: calories,
            carbsGramsPerServing: 25,
            sodiumMgPerServing: sodium,
            caffeinated: false
        )
    }

    private func makeEntry(product: NutritionProduct, timingMinutes: Int) -> NutritionEntry {
        NutritionEntry(id: UUID(), product: product, timingMinutes: timingMinutes, quantity: 1)
    }

    private func makeDeps(
        nutritionPlan: NutritionPlan? = nil
    ) -> (MockAthleteRepository, MockRunRepository, MockEstimateFinishTimeUseCase, MockCalculateFitnessUseCase, MockNutritionRepository, MockGenerateNutritionPlanUseCase, MockRaceRepository, MockFinishEstimateRepository) {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete

        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]

        let estimator = MockEstimateFinishTimeUseCase()
        estimator.resultEstimate = FinishEstimate(
            id: UUID(),
            raceId: race.id,
            athleteId: athlete.id,
            calculatedAt: .now,
            optimisticTime: 25200,
            expectedTime: 28800,
            conservativeTime: 32400,
            checkpointSplits: [
                CheckpointSplit(
                    id: UUID(), checkpointId: race.checkpoints[0].id,
                    checkpointName: "CP1", distanceFromStartKm: 15,
                    segmentDistanceKm: 15, segmentElevationGainM: 800,
                    hasAidStation: true,
                    optimisticTime: 7560, expectedTime: 8640, conservativeTime: 9720
                ),
                CheckpointSplit(
                    id: UUID(), checkpointId: race.checkpoints[1].id,
                    checkpointName: "CP2", distanceFromStartKm: 30,
                    segmentDistanceKm: 15, segmentElevationGainM: 700,
                    hasAidStation: true,
                    optimisticTime: 15120, expectedTime: 17280, conservativeTime: 19440
                ),
                CheckpointSplit(
                    id: UUID(), checkpointId: race.checkpoints[2].id,
                    checkpointName: "CP3", distanceFromStartKm: 45,
                    segmentDistanceKm: 15, segmentElevationGainM: 0,
                    hasAidStation: false,
                    optimisticTime: 22680, expectedTime: 25920, conservativeTime: 29160
                )
            ],
            confidencePercent: 60,
            raceResultsUsed: 0
        )

        let fitnessCalc = MockCalculateFitnessUseCase()

        let nutritionRepo = MockNutritionRepository()
        if let plan = nutritionPlan {
            nutritionRepo.plans[race.id] = plan
        }

        let nutritionGen = MockGenerateNutritionPlanUseCase()
        let raceRepo = MockRaceRepository()
        let estimateRepo = MockFinishEstimateRepository()

        return (athleteRepo, runRepo, estimator, fitnessCalc, nutritionRepo, nutritionGen, raceRepo, estimateRepo)
    }

    // MARK: - Tests

    @Test("Segments are built from checkpoint splits")
    @MainActor
    func segmentsBuiltFromSplits() async {
        let (athleteRepo, runRepo, estimator, fitnessCalc, nutritionRepo, nutritionGen, raceRepo, estimateRepo) = makeDeps()

        let vm = RaceDayPlanViewModel(
            race: race,
            finishTimeEstimator: estimator,
            athleteRepository: athleteRepo,
            runRepository: runRepo,
            fitnessCalculator: fitnessCalc,
            nutritionRepository: nutritionRepo,
            nutritionGenerator: nutritionGen,
            raceRepository: raceRepo,
            finishEstimateRepository: estimateRepo
        )

        await vm.load()

        #expect(vm.segments.count == 3)
        #expect(vm.segments[0].checkpointName == "CP1")
        #expect(vm.segments[1].checkpointName == "CP2")
        #expect(vm.segments[2].checkpointName == "CP3")
    }

    @Test("Nutrition entries are assigned to correct segments")
    @MainActor
    func nutritionEntriesAssignedCorrectly() async {
        let gel = makeProduct(name: "Gel", type: .gel, calories: 100, sodium: 60)
        let bar = makeProduct(name: "Bar", type: .bar, calories: 250, sodium: 200)

        // CP1 expected at 8640s = 144min, CP2 at 17280s = 288min
        let plan = NutritionPlan(
            id: UUID(),
            raceId: race.id,
            caloriesPerHour: 280,
            hydrationMlPerHour: 500,
            sodiumMgPerHour: 600,
            entries: [
                makeEntry(product: gel, timingMinutes: 20),   // segment 1 (0-144min)
                makeEntry(product: gel, timingMinutes: 60),   // segment 1
                makeEntry(product: bar, timingMinutes: 180),  // segment 2 (144-288min)
                makeEntry(product: gel, timingMinutes: 300),  // segment 3 (288-432min)
            ],
            gutTrainingSessionIds: []
        )

        let (athleteRepo, runRepo, estimator, fitnessCalc, nutritionRepo, nutritionGen, raceRepo, estimateRepo) = makeDeps(nutritionPlan: plan)

        let vm = RaceDayPlanViewModel(
            race: race,
            finishTimeEstimator: estimator,
            athleteRepository: athleteRepo,
            runRepository: runRepo,
            fitnessCalculator: fitnessCalc,
            nutritionRepository: nutritionRepo,
            nutritionGenerator: nutritionGen,
            raceRepository: raceRepo,
            finishEstimateRepository: estimateRepo
        )

        await vm.load()

        #expect(vm.segments[0].nutritionEntries.count == 2)
        #expect(vm.segments[1].nutritionEntries.count == 1)
        #expect(vm.segments[2].nutritionEntries.count == 1)
    }

    @Test("Cumulative nutrition totals accumulate across segments")
    @MainActor
    func cumulativeNutritionTotals() async {
        let gel = makeProduct(name: "Gel", type: .gel, calories: 100, sodium: 60)

        let plan = NutritionPlan(
            id: UUID(),
            raceId: race.id,
            caloriesPerHour: 280,
            hydrationMlPerHour: 500,
            sodiumMgPerHour: 600,
            entries: [
                makeEntry(product: gel, timingMinutes: 20),
                makeEntry(product: gel, timingMinutes: 60),
                makeEntry(product: gel, timingMinutes: 200),
            ],
            gutTrainingSessionIds: []
        )

        let (athleteRepo, runRepo, estimator, fitnessCalc, nutritionRepo, nutritionGen, raceRepo, estimateRepo) = makeDeps(nutritionPlan: plan)

        let vm = RaceDayPlanViewModel(
            race: race,
            finishTimeEstimator: estimator,
            athleteRepository: athleteRepo,
            runRepository: runRepo,
            fitnessCalculator: fitnessCalc,
            nutritionRepository: nutritionRepo,
            nutritionGenerator: nutritionGen,
            raceRepository: raceRepo,
            finishEstimateRepository: estimateRepo
        )

        await vm.load()

        #expect(vm.segments[0].cumulativeCalories == 200)
        #expect(vm.segments[1].cumulativeCalories == 300)
        #expect(vm.segments[0].cumulativeSodiumMg == 120)
        #expect(vm.segments[1].cumulativeSodiumMg == 180)
    }

    @Test("Empty nutrition plan produces segments with no entries")
    @MainActor
    func emptyNutritionPlan() async {
        let (athleteRepo, runRepo, estimator, fitnessCalc, nutritionRepo, nutritionGen, raceRepo, estimateRepo) = makeDeps()

        let vm = RaceDayPlanViewModel(
            race: race,
            finishTimeEstimator: estimator,
            athleteRepository: athleteRepo,
            runRepository: runRepo,
            fitnessCalculator: fitnessCalc,
            nutritionRepository: nutritionRepo,
            nutritionGenerator: nutritionGen,
            raceRepository: raceRepo,
            finishEstimateRepository: estimateRepo
        )

        await vm.load()

        for segment in vm.segments {
            #expect(segment.nutritionEntries.isEmpty)
        }
    }

    @Test("Empty checkpoints produces no segments")
    @MainActor
    func emptyCheckpointsNoSegments() async {
        let raceNoCheckpoints = Race(
            id: UUID(), name: "Flat Race",
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 6))!,
            distanceKm: 50, elevationGainM: 1000, elevationLossM: 1000,
            priority: .aRace, goalType: .finish,
            checkpoints: [], terrainDifficulty: .easy
        )

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete

        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]

        let estimator = MockEstimateFinishTimeUseCase()
        estimator.resultEstimate = FinishEstimate(
            id: UUID(), raceId: raceNoCheckpoints.id, athleteId: athlete.id,
            calculatedAt: .now, optimisticTime: 25200, expectedTime: 28800,
            conservativeTime: 32400, checkpointSplits: [],
            confidencePercent: 50, raceResultsUsed: 0
        )

        let vm = RaceDayPlanViewModel(
            race: raceNoCheckpoints,
            finishTimeEstimator: estimator,
            athleteRepository: athleteRepo,
            runRepository: runRepo,
            fitnessCalculator: MockCalculateFitnessUseCase(),
            nutritionRepository: MockNutritionRepository(),
            nutritionGenerator: MockGenerateNutritionPlanUseCase(),
            raceRepository: MockRaceRepository(),
            finishEstimateRepository: MockFinishEstimateRepository()
        )

        await vm.load()

        #expect(vm.segments.isEmpty)
    }

    @Test("Arrival time is race date plus expected cumulative time")
    @MainActor
    func arrivalTimeCalculation() async {
        let (athleteRepo, runRepo, estimator, fitnessCalc, nutritionRepo, nutritionGen, raceRepo, estimateRepo) = makeDeps()

        let vm = RaceDayPlanViewModel(
            race: race,
            finishTimeEstimator: estimator,
            athleteRepository: athleteRepo,
            runRepository: runRepo,
            fitnessCalculator: fitnessCalc,
            nutritionRepository: nutritionRepo,
            nutritionGenerator: nutritionGen,
            raceRepository: raceRepo,
            finishEstimateRepository: estimateRepo
        )

        await vm.load()

        let expectedArrival = race.date.addingTimeInterval(8640)
        let actualArrival = vm.segments[0].expectedArrivalTime
        #expect(abs(expectedArrival.timeIntervalSince(actualArrival)) < 1)
    }
}
