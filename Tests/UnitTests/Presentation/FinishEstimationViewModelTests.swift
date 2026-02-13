import Foundation
import Testing
@testable import UltraTrain

@Suite("Finish Estimation ViewModel Tests")
struct FinishEstimationViewModelTests {

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

    private func makeRace() -> Race {
        Race(
            id: UUID(),
            name: "Test Ultra",
            date: Date.now.adding(days: 60),
            distanceKm: 50,
            elevationGainM: 3000,
            elevationLossM: 3000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
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
            optimisticTime: 28800,
            expectedTime: 32400,
            conservativeTime: 36000,
            checkpointSplits: [],
            confidencePercent: 60
        )
    }

    @MainActor
    private func makeViewModel(
        race: Race? = nil,
        estimator: MockEstimateFinishTimeUseCase = MockEstimateFinishTimeUseCase(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        runRepo: MockRunRepository = MockRunRepository(),
        fitnessCalc: MockCalculateFitnessUseCase = MockCalculateFitnessUseCase()
    ) -> FinishEstimationViewModel {
        let r = race ?? makeRace()
        return FinishEstimationViewModel(
            race: r,
            finishTimeEstimator: estimator,
            athleteRepository: athleteRepo,
            runRepository: runRepo,
            fitnessCalculator: fitnessCalc
        )
    }

    // MARK: - Tests

    @Test("Load populates estimate")
    @MainActor
    func loadPopulatesEstimate() async {
        let race = makeRace()
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let estimator = MockEstimateFinishTimeUseCase()
        estimator.resultEstimate = makeEstimate(raceId: race.id)

        let vm = makeViewModel(race: race, estimator: estimator, athleteRepo: athleteRepo, runRepo: runRepo)
        await vm.load()

        #expect(vm.estimate != nil)
        #expect(vm.estimate?.expectedTime == 32400)
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load with no runs shows error")
    @MainActor
    func loadNoRunsShowsError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.estimate == nil)
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load handles estimator error")
    @MainActor
    func loadHandlesEstimatorError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let estimator = MockEstimateFinishTimeUseCase()
        estimator.shouldThrow = true

        let vm = makeViewModel(estimator: estimator, athleteRepo: athleteRepo, runRepo: runRepo)
        await vm.load()

        #expect(vm.estimate == nil)
        #expect(vm.error != nil)
    }

    @Test("Load with no athlete shows error")
    @MainActor
    func loadNoAthleteShowsError() async {
        let vm = makeViewModel()
        await vm.load()

        #expect(vm.estimate == nil)
        #expect(vm.error != nil)
    }

    @Test("isLoading is false after load completes")
    @MainActor
    func isLoadingFalseAfterLoad() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let estimator = MockEstimateFinishTimeUseCase()
        estimator.shouldThrow = true

        let vm = makeViewModel(estimator: estimator, athleteRepo: athleteRepo, runRepo: runRepo)
        await vm.load()

        #expect(vm.isLoading == false)
    }
}
