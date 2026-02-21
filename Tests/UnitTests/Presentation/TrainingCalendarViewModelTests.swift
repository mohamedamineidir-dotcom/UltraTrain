import Foundation
import Testing
@testable import UltraTrain

@Suite("Training Calendar ViewModel Tests")
@MainActor
struct TrainingCalendarViewModelTests {

    // MARK: - Helpers

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

    private func makeSession(
        date: Date,
        type: SessionType = .tempo,
        isCompleted: Bool = false
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: date,
            type: type,
            plannedDistanceKm: type == .rest ? 0 : 10,
            plannedElevationGainM: type == .rest ? 0 : 200,
            plannedDuration: type == .rest ? 0 : 3600,
            intensity: .moderate,
            description: "\(type.rawValue) session",
            nutritionNotes: nil,
            isCompleted: isCompleted,
            isSkipped: false,
            linkedRunId: nil
        )
    }

    private func makePlan(
        athleteId: UUID = UUID(),
        sessions: [TrainingSession]
    ) -> TrainingPlan {
        let weekStart = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 9))!
        let weekEnd = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!

        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: weekStart,
            endDate: weekEnd,
            phase: .base,
            sessions: sessions,
            isRecoveryWeek: false,
            targetVolumeKm: 40,
            targetElevationGainM: 800
        )

        return TrainingPlan(
            id: UUID(),
            athleteId: athleteId,
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    private func makeRun(
        athleteId: UUID,
        date: Date,
        distanceKm: Double = 10
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: date,
            distanceKm: distanceKm,
            elevationGainM: 200,
            elevationLossM: 180,
            duration: 3600,
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

    private func makeViewModel(
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository()
    ) -> TrainingCalendarViewModel {
        TrainingCalendarViewModel(
            planRepository: planRepo,
            runRepository: runRepo,
            athleteRepository: athleteRepo
        )
    }

    // MARK: - Tests

    @Test("Load fetches plan and runs from repositories")
    func loadFetchesPlanAndRuns() async {
        let athlete = makeAthlete()
        let testDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let session = makeSession(date: testDate)
        let plan = makePlan(athleteId: athlete.id, sessions: [session])
        let run = makeRun(athleteId: athlete.id, date: testDate)

        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan
        let runRepo = MockRunRepository()
        runRepo.runs = [run]
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = athlete

        let vm = makeViewModel(planRepo: planRepo, runRepo: runRepo, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.plan != nil)
        #expect(vm.plan?.id == plan.id)
        #expect(vm.completedRuns.count == 1)
        #expect(vm.completedRuns.first?.id == run.id)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Day status returns noActivity when no sessions and no runs")
    func dayStatusNoActivity() {
        let testDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let otherDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 14))!
        let session = makeSession(date: otherDate)
        let plan = makePlan(sessions: [session])

        let vm = makeViewModel()
        vm.plan = plan
        vm.completedRuns = []

        let status = vm.dayStatus(testDate)
        #expect(status == .noActivity)
    }

    @Test("Day status returns rest when only rest session exists")
    func dayStatusRest() {
        let testDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let restSession = makeSession(date: testDate, type: .rest)
        let plan = makePlan(sessions: [restSession])

        let vm = makeViewModel()
        vm.plan = plan
        vm.completedRuns = []

        let status = vm.dayStatus(testDate)
        #expect(status == .rest)
    }

    @Test("Day status returns planned when sessions exist but none completed")
    func dayStatusPlanned() {
        let testDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let session1 = makeSession(date: testDate, type: .tempo, isCompleted: false)
        let session2 = makeSession(date: testDate, type: .intervals, isCompleted: false)
        let plan = makePlan(sessions: [session1, session2])

        let vm = makeViewModel()
        vm.plan = plan
        vm.completedRuns = []

        let status = vm.dayStatus(testDate)
        #expect(status == .planned(sessionCount: 2))
    }

    @Test("Day status returns completed when all sessions are completed")
    func dayStatusCompleted() {
        let testDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let session = makeSession(date: testDate, type: .tempo, isCompleted: true)
        let plan = makePlan(sessions: [session])

        let vm = makeViewModel()
        vm.plan = plan
        vm.completedRuns = []

        let status = vm.dayStatus(testDate)
        #expect(status == .completed(sessionCount: 1))
    }

    @Test("Day status returns partial when some sessions are completed")
    func dayStatusPartial() {
        let testDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let completed = makeSession(date: testDate, type: .tempo, isCompleted: true)
        let notCompleted = makeSession(date: testDate, type: .intervals, isCompleted: false)
        let plan = makePlan(sessions: [completed, notCompleted])

        let vm = makeViewModel()
        vm.plan = plan
        vm.completedRuns = []

        let status = vm.dayStatus(testDate)
        #expect(status == .partial(completed: 1, total: 2))
    }

    @Test("Day status returns ranWithoutPlan when no sessions but has a run")
    func dayStatusRanWithoutPlan() {
        let testDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let otherDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 14))!
        let session = makeSession(date: otherDate, type: .tempo)
        let plan = makePlan(sessions: [session])
        let run = makeRun(athleteId: UUID(), date: testDate)

        let vm = makeViewModel()
        vm.plan = plan
        vm.completedRuns = [run]

        let status = vm.dayStatus(testDate)
        #expect(status == .ranWithoutPlan)
    }
}
