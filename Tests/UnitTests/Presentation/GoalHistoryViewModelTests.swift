import Foundation
import Testing
@testable import UltraTrain

@Suite("GoalHistory ViewModel Tests")
struct GoalHistoryViewModelTests {

    private func makeAthlete(id: UUID = UUID()) -> Athlete {
        Athlete(
            id: id,
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 40,
            longestRunKm: 25,
            preferredUnit: .metric
        )
    }

    private func makeGoal(period: GoalPeriod, distanceKm: Double = 50, daysAgo: Int = 7) -> TrainingGoal {
        let end = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        let start = Calendar.current.date(byAdding: .day, value: -daysAgo - 7, to: .now)!
        return TrainingGoal(
            id: UUID(),
            period: period,
            targetDistanceKm: distanceKm,
            startDate: start,
            endDate: end
        )
    }

    private func makeRun(athleteId: UUID, distanceKm: Double = 10) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: .now,
            distanceKm: distanceKm,
            elevationGainM: 100,
            elevationLossM: 80,
            duration: 3600,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0
        )
    }

    @MainActor
    private func makeSUT(
        goalRepo: MockGoalRepository = MockGoalRepository(),
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository()
    ) -> (GoalHistoryViewModel, MockGoalRepository, MockRunRepository, MockAthleteRepository) {
        let vm = GoalHistoryViewModel(
            goalRepository: goalRepo,
            runRepository: runRepo,
            athleteRepository: athleteRepo
        )
        return (vm, goalRepo, runRepo, athleteRepo)
    }

    @Test("Load populates weekly and monthly history")
    @MainActor
    func loadPopulatesHistory() async {
        let athlete = makeAthlete()
        let (vm, goalRepo, runRepo, athleteRepo) = makeSUT()

        athleteRepo.savedAthlete = athlete
        runRepo.runs = [makeRun(athleteId: athlete.id)]
        goalRepo.goals = [
            makeGoal(period: .weekly, daysAgo: 0),
            makeGoal(period: .monthly, daysAgo: 0)
        ]

        await vm.load()

        #expect(vm.weeklyHistory.count == 1)
        #expect(vm.monthlyHistory.count == 1)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load sets error when repository throws")
    @MainActor
    func loadSetsErrorOnFailure() async {
        let (vm, goalRepo, _, athleteRepo) = makeSUT()
        athleteRepo.savedAthlete = makeAthlete()
        goalRepo.shouldThrow = true

        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load with no athlete returns empty history")
    @MainActor
    func loadWithNoAthlete() async {
        let (vm, _, _, _) = makeSUT()

        await vm.load()

        #expect(vm.weeklyHistory.isEmpty)
        #expect(vm.monthlyHistory.isEmpty)
    }

    @Test("Load respects goal period filtering")
    @MainActor
    func loadFiltersByPeriod() async {
        let athlete = makeAthlete()
        let (vm, goalRepo, runRepo, athleteRepo) = makeSUT()

        athleteRepo.savedAthlete = athlete
        runRepo.runs = [makeRun(athleteId: athlete.id)]
        goalRepo.goals = [
            makeGoal(period: .weekly, daysAgo: 7),
            makeGoal(period: .weekly, daysAgo: 14),
            makeGoal(period: .monthly, daysAgo: 30)
        ]

        await vm.load()

        #expect(vm.weeklyHistory.count == 2)
        #expect(vm.monthlyHistory.count == 1)
    }

    @Test("Loading state transitions correctly")
    @MainActor
    func loadingStateTransitions() async {
        let athlete = makeAthlete()
        let (vm, _, _, athleteRepo) = makeSUT()
        athleteRepo.savedAthlete = athlete

        #expect(vm.isLoading == false)
        await vm.load()
        #expect(vm.isLoading == false)
    }
}
