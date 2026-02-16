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
            notes: nil,
            pausedDuration: 0
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
                isCompleted: i < completedCount, isSkipped: false,
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

    private func makeMultiWeekPlan() -> TrainingPlan {
        let weeks = (0..<4).map { i -> TrainingWeek in
            let weekStart = Date.now.adding(weeks: -(3 - i)).startOfWeek
            let sessions: [TrainingSession] = (0..<5).map { j in
                let isRest = j == 4
                return TrainingSession(
                    id: UUID(),
                    date: weekStart.adding(days: j),
                    type: isRest ? .rest : .tempo,
                    plannedDistanceKm: 10,
                    plannedElevationGainM: 200,
                    plannedDuration: 3600,
                    intensity: .moderate,
                    description: "W\(i+1)S\(j+1)",
                    nutritionNotes: nil,
                    isCompleted: j < (i + 1),
                    isSkipped: false,
                    linkedRunId: nil
                )
            }
            return TrainingWeek(
                id: UUID(),
                weekNumber: i + 1,
                startDate: weekStart,
                endDate: weekStart.adding(days: 7),
                phase: .base,
                sessions: sessions,
                isRecoveryWeek: false,
                targetVolumeKm: 40,
                targetElevationGainM: 800
            )
        }
        return TrainingPlan(
            id: UUID(),
            athleteId: athleteId,
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: weeks,
            intermediateRaceIds: []
        )
    }

    @MainActor
    private func makeViewModel(
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        fitnessCalc: MockCalculateFitnessUseCase = MockCalculateFitnessUseCase(),
        fitnessRepo: MockFitnessRepository = MockFitnessRepository()
    ) -> ProgressViewModel {
        ProgressViewModel(
            runRepository: runRepo,
            athleteRepository: athleteRepo,
            planRepository: planRepo,
            fitnessCalculator: fitnessCalc,
            fitnessRepository: fitnessRepo
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

    // MARK: - Weekly Adherence Trend

    @Test("Weekly adherence computed for multi-week plan")
    @MainActor
    func weeklyAdherenceMultiWeek() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = makeMultiWeekPlan()

        let vm = makeViewModel(athleteRepo: athleteRepo, planRepo: planRepo)
        await vm.load()

        // 4 weeks, all in the past or current → 4 data points
        #expect(vm.weeklyAdherence.count == 4)
        // Week 1: 1 of 4 active completed (rest excluded) = 25%
        #expect(vm.weeklyAdherence[0].completed == 1)
        #expect(vm.weeklyAdherence[0].total == 4)
        #expect(vm.weeklyAdherence[0].percent == 25)
        // Week 4: 4 of 4 active completed = 100%
        #expect(vm.weeklyAdherence[3].completed == 4)
        #expect(vm.weeklyAdherence[3].percent == 100)
    }

    @Test("Future weeks excluded from adherence trend")
    @MainActor
    func futureWeeksExcluded() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let futureWeek = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date.now.adding(weeks: 2).startOfWeek,
            endDate: Date.now.adding(weeks: 2).startOfWeek.adding(days: 7),
            phase: .base,
            sessions: [TrainingSession(
                id: UUID(),
                date: Date.now.adding(weeks: 2),
                type: .tempo,
                plannedDistanceKm: 10,
                plannedElevationGainM: 200,
                plannedDuration: 3600,
                intensity: .moderate,
                description: "Future",
                nutritionNotes: nil,
                isCompleted: false,
                isSkipped: false,
                linkedRunId: nil
            )],
            isRecoveryWeek: false,
            targetVolumeKm: 40,
            targetElevationGainM: 800
        )
        let plan = TrainingPlan(
            id: UUID(),
            athleteId: athleteId,
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: [futureWeek],
            intermediateRaceIds: []
        )
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let vm = makeViewModel(athleteRepo: athleteRepo, planRepo: planRepo)
        await vm.load()

        #expect(vm.weeklyAdherence.isEmpty)
    }

    @Test("No plan gives empty adherence trend")
    @MainActor
    func noPlanEmptyAdherenceTrend() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.weeklyAdherence.isEmpty)
    }

    @Test("Rest sessions excluded from adherence counts")
    @MainActor
    func restSessionsExcluded() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let weekStart = Date.now.startOfWeek
        let sessions = [
            TrainingSession(
                id: UUID(), date: weekStart, type: .tempo,
                plannedDistanceKm: 10, plannedElevationGainM: 200,
                plannedDuration: 3600, intensity: .moderate,
                description: "Tempo", nutritionNotes: nil,
                isCompleted: true, isSkipped: false, linkedRunId: nil
            ),
            TrainingSession(
                id: UUID(), date: weekStart.adding(days: 1), type: .rest,
                plannedDistanceKm: 0, plannedElevationGainM: 0,
                plannedDuration: 0, intensity: .easy,
                description: "Rest", nutritionNotes: nil,
                isCompleted: false, isSkipped: false, linkedRunId: nil
            ),
            TrainingSession(
                id: UUID(), date: weekStart.adding(days: 2), type: .longRun,
                plannedDistanceKm: 20, plannedElevationGainM: 500,
                plannedDuration: 7200, intensity: .moderate,
                description: "Long Run", nutritionNotes: nil,
                isCompleted: false, isSkipped: false, linkedRunId: nil
            ),
        ]
        let week = TrainingWeek(
            id: UUID(), weekNumber: 1, startDate: weekStart,
            endDate: weekStart.adding(days: 7), phase: .base,
            sessions: sessions, isRecoveryWeek: false,
            targetVolumeKm: 30, targetElevationGainM: 700
        )
        let plan = TrainingPlan(
            id: UUID(), athleteId: athleteId, targetRaceId: UUID(),
            createdAt: .now, weeks: [week], intermediateRaceIds: []
        )
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let vm = makeViewModel(athleteRepo: athleteRepo, planRepo: planRepo)
        await vm.load()

        #expect(vm.weeklyAdherence.count == 1)
        // 1 completed out of 2 active (rest excluded) = 50%
        #expect(vm.weeklyAdherence[0].total == 2)
        #expect(vm.weeklyAdherence[0].completed == 1)
        #expect(vm.weeklyAdherence[0].percent == 50)
    }

    // MARK: - Fitness / Form Status

    @Test("Fitness snapshots loaded when runs exist")
    @MainActor
    func fitnessSnapshotsLoaded() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun(daysAgo: 0), makeRun(daysAgo: 3)]
        let fitnessCalc = MockCalculateFitnessUseCase()
        fitnessCalc.resultSnapshot = FitnessSnapshot(
            id: UUID(), date: .now, fitness: 40, fatigue: 30, form: 10,
            weeklyVolumeKm: 20, weeklyElevationGainM: 400, weeklyDuration: 7200,
            acuteToChronicRatio: 0.75, monotony: 1.5
        )

        let vm = makeViewModel(
            runRepo: runRepo, athleteRepo: athleteRepo,
            fitnessCalc: fitnessCalc
        )
        await vm.load()

        #expect(vm.currentFitnessSnapshot != nil)
        #expect(vm.currentFitnessSnapshot?.fitness == 40)
        #expect(vm.currentFitnessSnapshot?.form == 10)
    }

    @Test("Form status returns correct values for TSB ranges")
    @MainActor
    func formStatusValues() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun(daysAgo: 0)]

        // TSB = 20 → raceReady
        let fitnessCalc = MockCalculateFitnessUseCase()
        fitnessCalc.resultSnapshot = FitnessSnapshot(
            id: UUID(), date: .now, fitness: 50, fatigue: 30, form: 20,
            weeklyVolumeKm: 10, weeklyElevationGainM: 200, weeklyDuration: 3600,
            acuteToChronicRatio: 0.6, monotony: 1.0
        )

        let vm = makeViewModel(
            runRepo: runRepo, athleteRepo: athleteRepo,
            fitnessCalc: fitnessCalc
        )
        await vm.load()
        #expect(vm.formStatus == .raceReady)

        // TSB = 5 → fresh
        fitnessCalc.resultSnapshot = FitnessSnapshot(
            id: UUID(), date: .now, fitness: 40, fatigue: 35, form: 5,
            weeklyVolumeKm: 10, weeklyElevationGainM: 200, weeklyDuration: 3600,
            acuteToChronicRatio: 0.88, monotony: 1.0
        )
        await vm.load()
        #expect(vm.formStatus == .fresh)

        // TSB = -10 → building
        fitnessCalc.resultSnapshot = FitnessSnapshot(
            id: UUID(), date: .now, fitness: 30, fatigue: 40, form: -10,
            weeklyVolumeKm: 10, weeklyElevationGainM: 200, weeklyDuration: 3600,
            acuteToChronicRatio: 1.33, monotony: 1.0
        )
        await vm.load()
        #expect(vm.formStatus == .building)

        // TSB = -20 → fatigued
        fitnessCalc.resultSnapshot = FitnessSnapshot(
            id: UUID(), date: .now, fitness: 30, fatigue: 50, form: -20,
            weeklyVolumeKm: 10, weeklyElevationGainM: 200, weeklyDuration: 3600,
            acuteToChronicRatio: 1.67, monotony: 1.0
        )
        await vm.load()
        #expect(vm.formStatus == .fatigued)
    }

    @Test("Fitness snapshots empty when no runs")
    @MainActor
    func fitnessEmptyNoRuns() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.currentFitnessSnapshot == nil)
        #expect(vm.fitnessSnapshots.isEmpty)
        #expect(vm.formStatus == .noData)
    }
}
