import Foundation
import Testing
@testable import UltraTrain

@Suite("RaceReport ViewModel Tests")
struct RaceReportViewModelTests {

    private func makeRace(
        id: UUID = UUID(),
        goalType: RaceGoal = .finish,
        actualFinishTime: TimeInterval? = nil,
        linkedRunId: UUID? = nil
    ) -> Race {
        Race(
            id: id,
            name: "Test Ultra",
            date: .now,
            distanceKm: 100,
            elevationGainM: 5000,
            elevationLossM: 5000,
            priority: .aRace,
            goalType: goalType,
            checkpoints: [],
            terrainDifficulty: .moderate,
            actualFinishTime: actualFinishTime,
            linkedRunId: linkedRunId
        )
    }

    private func makeEstimate(raceId: UUID, expectedTime: TimeInterval = 36000) -> FinishEstimate {
        FinishEstimate(
            id: UUID(),
            raceId: raceId,
            athleteId: UUID(),
            calculatedAt: .now,
            optimisticTime: expectedTime * 0.9,
            expectedTime: expectedTime,
            conservativeTime: expectedTime * 1.1,
            checkpointSplits: [],
            confidencePercent: 75,
            raceResultsUsed: 3
        )
    }

    private func makeRun(id: UUID = UUID()) -> CompletedRun {
        CompletedRun(
            id: id,
            athleteId: UUID(),
            date: .now,
            distanceKm: 100,
            elevationGainM: 5000,
            elevationLossM: 5000,
            duration: 36000,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0
        )
    }

    @MainActor
    private func makeSUT(
        race: Race,
        reflectionRepo: MockRaceReflectionRepository = MockRaceReflectionRepository(),
        estimateRepo: MockFinishEstimateRepository = MockFinishEstimateRepository(),
        runRepo: MockRunRepository = MockRunRepository()
    ) -> RaceReportViewModel {
        RaceReportViewModel(
            race: race,
            raceReflectionRepository: reflectionRepo,
            finishEstimateRepository: estimateRepo,
            runRepository: runRepo
        )
    }

    // MARK: - Load

    @Test("Load fetches reflection, estimate, and linked run")
    @MainActor
    func loadFetchesAll() async {
        let runId = UUID()
        let race = makeRace(linkedRunId: runId)
        let reflectionRepo = MockRaceReflectionRepository()
        let estimateRepo = MockFinishEstimateRepository()
        let runRepo = MockRunRepository()

        estimateRepo.estimates[race.id] = makeEstimate(raceId: race.id)
        runRepo.runs = [makeRun(id: runId)]

        let vm = makeSUT(race: race, reflectionRepo: reflectionRepo, estimateRepo: estimateRepo, runRepo: runRepo)
        await vm.load()

        #expect(vm.estimate != nil)
        #expect(vm.linkedRun != nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load without linked run leaves linkedRun nil")
    @MainActor
    func loadWithoutLinkedRun() async {
        let race = makeRace(linkedRunId: nil)
        let vm = makeSUT(race: race)
        await vm.load()

        #expect(vm.linkedRun == nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - goalAchieved

    @Test("Finish goal is achieved when actual finish time exists")
    @MainActor
    func finishGoalAchieved() async {
        let race = makeRace(goalType: .finish, actualFinishTime: 36000)
        let vm = makeSUT(race: race)
        #expect(vm.goalAchieved == true)
    }

    @Test("Finish goal not achieved when no actual time")
    @MainActor
    func finishGoalNotAchievedWithoutTime() async {
        let race = makeRace(goalType: .finish, actualFinishTime: nil)
        let vm = makeSUT(race: race)
        #expect(vm.goalAchieved == false)
    }

    @Test("Target time goal achieved when actual is under target")
    @MainActor
    func targetTimeGoalAchieved() async {
        let race = makeRace(goalType: .targetTime(36000), actualFinishTime: 35000)
        let vm = makeSUT(race: race)
        #expect(vm.goalAchieved == true)
    }

    @Test("Target time goal not achieved when actual exceeds target")
    @MainActor
    func targetTimeGoalNotAchieved() async {
        let race = makeRace(goalType: .targetTime(36000), actualFinishTime: 37000)
        let vm = makeSUT(race: race)
        #expect(vm.goalAchieved == false)
    }

    // MARK: - predictionAccuracy

    @Test("Prediction accuracy is nil without estimate")
    @MainActor
    func predictionAccuracyNilWithoutEstimate() async {
        let race = makeRace(actualFinishTime: 36000)
        let vm = makeSUT(race: race)
        #expect(vm.predictionAccuracy == nil)
    }

    @Test("Prediction accuracy is nil without actual finish time")
    @MainActor
    func predictionAccuracyNilWithoutActualTime() async {
        let race = makeRace(actualFinishTime: nil)
        let estimateRepo = MockFinishEstimateRepository()
        estimateRepo.estimates[race.id] = makeEstimate(raceId: race.id)
        let vm = makeSUT(race: race, estimateRepo: estimateRepo)
        await vm.load()
        #expect(vm.predictionAccuracy == nil)
    }

    @Test("Perfect prediction gives 100% accuracy")
    @MainActor
    func perfectPredictionAccuracy() async {
        let race = makeRace(actualFinishTime: 36000)
        let estimateRepo = MockFinishEstimateRepository()
        estimateRepo.estimates[race.id] = makeEstimate(raceId: race.id, expectedTime: 36000)
        let vm = makeSUT(race: race, estimateRepo: estimateRepo)
        await vm.load()
        #expect(vm.predictionAccuracy == 100.0)
    }

    @Test("10% off prediction gives 90% accuracy")
    @MainActor
    func tenPercentOffAccuracy() async {
        let race = makeRace(actualFinishTime: 39600) // 11h vs 10h expected
        let estimateRepo = MockFinishEstimateRepository()
        estimateRepo.estimates[race.id] = makeEstimate(raceId: race.id, expectedTime: 36000)
        let vm = makeSUT(race: race, estimateRepo: estimateRepo)
        await vm.load()
        #expect(vm.predictionAccuracy == 90.0)
    }
}
