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
            confidencePercent: 60,
            raceResultsUsed: 0
        )
    }

    @MainActor
    private func makeViewModel(
        race: Race? = nil,
        estimator: MockEstimateFinishTimeUseCase = MockEstimateFinishTimeUseCase(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        runRepo: MockRunRepository = MockRunRepository(),
        fitnessCalc: MockCalculateFitnessUseCase = MockCalculateFitnessUseCase(),
        raceRepo: MockRaceRepository = MockRaceRepository(),
        estimateRepo: MockFinishEstimateRepository = MockFinishEstimateRepository()
    ) -> FinishEstimationViewModel {
        let r = race ?? makeRace()
        return FinishEstimationViewModel(
            race: r,
            finishTimeEstimator: estimator,
            athleteRepository: athleteRepo,
            runRepository: runRepo,
            fitnessCalculator: fitnessCalc,
            raceRepository: raceRepo,
            finishEstimateRepository: estimateRepo
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

    // MARK: - Known-race course backfill

    @Test("A race matching a known race with a bundled GPX gets its course backfilled on load")
    @MainActor
    func loadBackfillsKnownRaceCourse() async {
        var race = makeRace()
        race.name = "Oman by UTMB 50K"
        race.checkpoints = []
        // courseRoute defaults to [] — no course on file yet, matching a
        // race added before this feature shipped, or one whose name
        // matches a known race without ever going through the
        // autocomplete selection that would populate it at creation.

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let estimator = MockEstimateFinishTimeUseCase()
        estimator.resultEstimate = makeEstimate(raceId: race.id)

        let vm = makeViewModel(race: race, estimator: estimator, athleteRepo: athleteRepo, runRepo: runRepo, raceRepo: raceRepo)
        await vm.load()

        #expect(vm.race.hasCourseRoute == true)
        #expect(raceRepo.savedRace?.courseRoute.isEmpty == false)
    }

    @Test("A race not matching any known race is left without a course")
    @MainActor
    func loadDoesNotBackfillUnmatchedRace() async {
        let race = makeRace() // name: "Test Ultra" — not in RaceDatabase

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let estimator = MockEstimateFinishTimeUseCase()
        estimator.resultEstimate = makeEstimate(raceId: race.id)

        let vm = makeViewModel(race: race, estimator: estimator, athleteRepo: athleteRepo, runRepo: runRepo)
        await vm.load()

        #expect(vm.race.hasCourseRoute == false)
    }

    @Test("A race that already has a course route is not touched by backfill")
    @MainActor
    func loadSkipsBackfillWhenCourseAlreadyExists() async {
        var race = makeRace()
        race.name = "Oman by UTMB 50K"
        let existingPoint = TrackPoint(latitude: 1, longitude: 1, altitudeM: 100, timestamp: .now, heartRate: nil)
        race.courseRoute = [existingPoint, existingPoint]

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let estimator = MockEstimateFinishTimeUseCase()
        estimator.resultEstimate = makeEstimate(raceId: race.id)

        let vm = makeViewModel(race: race, estimator: estimator, athleteRepo: athleteRepo, runRepo: runRepo, raceRepo: raceRepo)
        await vm.load()

        #expect(raceRepo.savedRace == nil, "updateRace should never be called when the race already has a course")
    }
}
