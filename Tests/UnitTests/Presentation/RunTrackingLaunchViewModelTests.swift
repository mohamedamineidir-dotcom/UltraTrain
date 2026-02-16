import Foundation
import Testing
@testable import UltraTrain

@Suite("RunTrackingLaunch ViewModel Tests")
struct RunTrackingLaunchViewModelTests {

    private func makeAthlete() -> Athlete {
        Athlete(
            id: UUID(),
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

    private func makePlanWithTodaySession(
        completed: Bool = false,
        type: SessionType = .longRun
    ) -> TrainingPlan {
        let today = Date.now
        let calendar = Calendar.current
        let weekStart = calendar.date(byAdding: .day, value: -1, to: today)!
        let weekEnd = calendar.date(byAdding: .day, value: 5, to: today)!

        let session = TrainingSession(
            id: UUID(),
            date: today,
            type: type,
            plannedDistanceKm: 15,
            plannedElevationGainM: 500,
            plannedDuration: 5400,
            intensity: .moderate,
            description: "Test run",
            nutritionNotes: nil,
            isCompleted: completed, isSkipped: false,
            linkedRunId: nil
        )

        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: weekStart,
            endDate: weekEnd,
            phase: .build,
            sessions: [session],
            isRecoveryWeek: false,
            targetVolumeKm: 50,
            targetElevationGainM: 1500
        )

        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: Date.now,
            weeks: [week],
            intermediateRaceIds: []
        )
    }

    @MainActor
    private func makeViewModel(
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        runRepo: MockRunRepository = MockRunRepository(),
        settingsRepo: MockAppSettingsRepository = MockAppSettingsRepository()
    ) -> RunTrackingLaunchViewModel {
        RunTrackingLaunchViewModel(
            athleteRepository: athleteRepo,
            planRepository: planRepo,
            runRepository: runRepo,
            appSettingsRepository: settingsRepo
        )
    }

    // MARK: - Load

    @Test("Load fetches athlete and today's sessions")
    @MainActor
    func loadFetchesData() async {
        let athlete = makeAthlete()
        let plan = makePlanWithTodaySession()

        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let vm = makeViewModel(athleteRepo: athleteRepo, planRepo: planRepo)
        await vm.load()

        #expect(vm.athlete != nil)
        #expect(vm.todaysSessions.count == 1)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load with no active plan has empty sessions")
    @MainActor
    func loadNoActivePlan() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.athlete != nil)
        #expect(vm.todaysSessions.isEmpty)
        #expect(vm.error == nil)
    }

    @Test("Load filters out completed sessions")
    @MainActor
    func loadFiltersCompleted() async {
        let plan = makePlanWithTodaySession(completed: true)
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let vm = makeViewModel(planRepo: planRepo)
        await vm.load()

        #expect(vm.todaysSessions.isEmpty)
    }

    @Test("Load filters out rest sessions")
    @MainActor
    func loadFiltersRest() async {
        let plan = makePlanWithTodaySession(type: .rest)
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let vm = makeViewModel(planRepo: planRepo)
        await vm.load()

        #expect(vm.todaysSessions.isEmpty)
    }

    @Test("Load handles error")
    @MainActor
    func loadHandlesError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Selection

    @Test("Select session updates selectedSession")
    @MainActor
    func selectSession() {
        let session = makePlanWithTodaySession().weeks[0].sessions[0]
        let vm = makeViewModel()

        vm.selectSession(session)
        #expect(vm.selectedSession?.id == session.id)

        vm.selectSession(nil)
        #expect(vm.selectedSession == nil)
    }

    @Test("Start run sets showActiveRun")
    @MainActor
    func startRun() {
        let vm = makeViewModel()
        vm.startRun()
        #expect(vm.showActiveRun == true)
    }
}
