import Foundation
import Testing
@testable import UltraTrain

@Suite("Dashboard ViewModel Tests")
struct DashboardViewModelTests {

    private let athleteId = UUID()

    private func makeAthlete() -> Athlete {
        Athlete(
            id: athleteId,
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
    }

    private func makeRace(priority: RacePriority = .aRace) -> Race {
        Race(
            id: UUID(),
            name: "UTMB",
            date: Date.now.adding(days: 60),
            distanceKm: 170,
            elevationGainM: 10000,
            elevationLossM: 10000,
            priority: priority,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .technical
        )
    }

    private func makeRun() -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
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

    private func makeEstimate(raceId: UUID) -> FinishEstimate {
        FinishEstimate(
            id: UUID(),
            raceId: raceId,
            athleteId: athleteId,
            calculatedAt: .now,
            optimisticTime: 36000,
            expectedTime: 43200,
            conservativeTime: 50400,
            checkpointSplits: [],
            confidencePercent: 65,
            raceResultsUsed: 0
        )
    }

    private func makeSnapshot(acr: Double = 1.0) -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(),
            date: .now,
            fitness: 50,
            fatigue: 50 * acr,
            form: 50 - 50 * acr,
            weeklyVolumeKm: 40,
            weeklyElevationGainM: 800,
            weeklyDuration: 14400,
            acuteToChronicRatio: acr,
            monotony: 0
        )
    }

    @MainActor
    private func makeViewModel(
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        fitnessRepo: MockFitnessRepository = MockFitnessRepository(),
        fitnessCalc: MockCalculateFitnessUseCase = MockCalculateFitnessUseCase(),
        raceRepo: MockRaceRepository = MockRaceRepository(),
        estimator: MockEstimateFinishTimeUseCase = MockEstimateFinishTimeUseCase(),
        estimateRepo: MockFinishEstimateRepository = MockFinishEstimateRepository()
    ) -> DashboardViewModel {
        DashboardViewModel(
            planRepository: planRepo,
            runRepository: runRepo,
            athleteRepository: athleteRepo,
            fitnessRepository: fitnessRepo,
            fitnessCalculator: fitnessCalc,
            raceRepository: raceRepo,
            finishTimeEstimator: estimator,
            finishEstimateRepository: estimateRepo
        )
    }

    // MARK: - Finish Estimate

    @Test("Load fetches estimate when A-race exists")
    @MainActor
    func loadFetchesEstimateWithARace() async {
        let race = makeRace()
        let estimate = makeEstimate(raceId: race.id)
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let estimator = MockEstimateFinishTimeUseCase()
        estimator.resultEstimate = estimate
        let estimateRepo = MockFinishEstimateRepository()

        let vm = makeViewModel(
            runRepo: runRepo,
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            estimator: estimator,
            estimateRepo: estimateRepo
        )
        await vm.load()

        #expect(vm.finishEstimate != nil)
        #expect(vm.aRace?.id == race.id)
        #expect(estimateRepo.savedEstimate != nil)
    }

    @Test("Load with no A-race has nil estimate")
    @MainActor
    func loadWithNoARaceHasNilEstimate() async {
        let bRace = makeRace(priority: .bRace)
        let raceRepo = MockRaceRepository()
        raceRepo.races = [bRace]

        let vm = makeViewModel(raceRepo: raceRepo)
        await vm.load()

        #expect(vm.finishEstimate == nil)
        #expect(vm.aRace == nil)
    }

    @Test("Load with no runs has nil estimate")
    @MainActor
    func loadWithNoRunsHasNilEstimate() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo, raceRepo: raceRepo)
        await vm.load()

        #expect(vm.aRace?.id == race.id)
        #expect(vm.finishEstimate == nil)
    }

    @Test("Load caches estimate in repository")
    @MainActor
    func loadCachesEstimate() async {
        let race = makeRace()
        let estimate = makeEstimate(raceId: race.id)
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let estimator = MockEstimateFinishTimeUseCase()
        estimator.resultEstimate = estimate
        let estimateRepo = MockFinishEstimateRepository()

        let vm = makeViewModel(
            runRepo: runRepo,
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            estimator: estimator,
            estimateRepo: estimateRepo
        )
        await vm.load()

        #expect(estimateRepo.savedEstimate != nil)
        #expect(estimateRepo.savedEstimate?.raceId == race.id)
    }

    @Test("Load handles estimator error silently")
    @MainActor
    func loadHandlesEstimatorError() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let estimator = MockEstimateFinishTimeUseCase()
        estimator.shouldThrow = true

        let vm = makeViewModel(
            runRepo: runRepo,
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            estimator: estimator
        )
        await vm.load()

        #expect(vm.finishEstimate == nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load uses cached estimate before recalculating")
    @MainActor
    func loadUsesCachedFirst() async {
        let race = makeRace()
        let cached = makeEstimate(raceId: race.id)
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let estimateRepo = MockFinishEstimateRepository()
        estimateRepo.estimates[race.id] = cached
        let estimator = MockEstimateFinishTimeUseCase()
        let fresh = makeEstimate(raceId: race.id)
        estimator.resultEstimate = fresh

        let vm = makeViewModel(
            runRepo: runRepo,
            athleteRepo: athleteRepo,
            raceRepo: raceRepo,
            estimator: estimator,
            estimateRepo: estimateRepo
        )
        await vm.load()

        #expect(vm.finishEstimate != nil)
    }

    // MARK: - Fitness Status

    @Test("Fitness status returns noData when nil")
    @MainActor
    func statusNoData() {
        let vm = makeViewModel()
        #expect(vm.fitnessStatus == .noData)
    }

    @Test("Fitness status returns optimal for normal ACR")
    @MainActor
    func statusOptimal() {
        let vm = makeViewModel()
        vm.fitnessSnapshot = makeSnapshot(acr: 1.0)
        #expect(vm.fitnessStatus == .optimal)
    }

    @Test("Fitness status returns injuryRisk for ACR above 1.5")
    @MainActor
    func statusInjuryRisk() {
        let vm = makeViewModel()
        vm.fitnessSnapshot = makeSnapshot(acr: 1.8)
        #expect(vm.fitnessStatus == .injuryRisk)
    }

    @Test("Fitness status returns detraining for low ACR")
    @MainActor
    func statusDetraining() {
        let vm = makeViewModel()
        vm.fitnessSnapshot = makeSnapshot(acr: 0.5)
        #expect(vm.fitnessStatus == .detraining)
    }
}
