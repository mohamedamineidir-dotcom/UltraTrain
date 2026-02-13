import Foundation
import Testing
@testable import UltraTrain

@Suite("Progress ViewModel Tests")
struct ProgressViewModelTests {

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

    private func makeRun(daysAgo: Int = 0, distanceKm: Double = 10) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: Date.now.adding(days: -daysAgo),
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
            notes: nil
        )
    }

    private func makePlan(completedCount: Int, totalCount: Int) -> TrainingPlan {
        var sessions: [TrainingSession] = []
        for i in 0..<totalCount {
            sessions.append(TrainingSession(
                id: UUID(),
                date: Date.now.adding(days: i),
                type: .tempo,
                plannedDistanceKm: 10,
                plannedElevationGainM: 200,
                plannedDuration: 3600,
                intensity: .moderate,
                description: "Session \(i)",
                nutritionNotes: nil,
                isCompleted: i < completedCount,
                linkedRunId: nil
            ))
        }
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date.now.startOfWeek,
            endDate: Date.now.startOfWeek.adding(days: 6),
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
            intermediateRaceIds: []
        )
    }

    @MainActor
    private func makeViewModel(
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository()
    ) -> ProgressViewModel {
        ProgressViewModel(
            runRepository: runRepo,
            athleteRepository: athleteRepo,
            planRepository: planRepo
        )
    }

    // MARK: - Tests

    @Test("Load computes weekly volumes from runs")
    @MainActor
    func loadComputesWeeklyVolumes() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun(daysAgo: 0), makeRun(daysAgo: 1)]

        let vm = makeViewModel(runRepo: runRepo, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.weeklyVolumes.count == 8)
        #expect(vm.totalRuns == 2)
        #expect(vm.isLoading == false)
    }

    @Test("Empty runs produces empty volumes")
    @MainActor
    func emptyRunsEmptyVolumes() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.weeklyVolumes.count == 8)
        #expect(vm.totalRuns == 0)
        let totalKm = vm.weeklyVolumes.reduce(0.0) { $0 + $1.distanceKm }
        #expect(totalKm == 0)
    }

    @Test("Plan adherence counts correctly")
    @MainActor
    func planAdherenceCorrect() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = makePlan(completedCount: 3, totalCount: 5)

        let vm = makeViewModel(athleteRepo: athleteRepo, planRepo: planRepo)
        await vm.load()

        #expect(vm.planAdherence.completed == 3)
        #expect(vm.planAdherence.total == 5)
        #expect(vm.adherencePercent == 60)
    }

    @Test("No plan gives zero adherence")
    @MainActor
    func noPlanZeroAdherence() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.planAdherence.completed == 0)
        #expect(vm.planAdherence.total == 0)
        #expect(vm.adherencePercent == 0)
    }

    @Test("Handles repository error")
    @MainActor
    func handlesError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("Average weekly km computed from active weeks")
    @MainActor
    func averageWeeklyKm() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [
            makeRun(daysAgo: 0, distanceKm: 10),
            makeRun(daysAgo: 0, distanceKm: 5),
            makeRun(daysAgo: 7, distanceKm: 20)
        ]

        let vm = makeViewModel(runRepo: runRepo, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.totalRuns == 3)
        #expect(vm.averageWeeklyKm > 0)
    }
}
