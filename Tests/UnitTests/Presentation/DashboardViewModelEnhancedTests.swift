import Foundation
import Testing
@testable import UltraTrain

@Suite("Dashboard ViewModel Enhanced Tests")
@MainActor
struct DashboardViewModelEnhancedTests {

    private func makeRun(
        date: Date = .now,
        distanceKm: Double = 10,
        athleteId: UUID = UUID()
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: date,
            distanceKm: distanceKm,
            elevationGainM: 200,
            elevationLossM: 200,
            duration: 3600,
            averageHeartRate: 150,
            maxHeartRate: 170,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0
        )
    }

    private func makeRace(
        name: String = "Test Race",
        date: Date = .now.adding(days: 30),
        priority: RacePriority = .aRace
    ) -> Race {
        Race(
            id: UUID(),
            name: name,
            date: date,
            distanceKm: 80,
            elevationGainM: 4000,
            elevationLossM: 4000,
            priority: priority,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    private func makePlan(phase: TrainingPhase = .build) -> TrainingPlan {
        let session = TrainingSession(
            id: UUID(),
            date: .now,
            type: .longRun,
            plannedDistanceKm: 25,
            plannedElevationGainM: 800,
            plannedDuration: 7200,
            intensity: .moderate,
            description: "Long run",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date.now.startOfWeek,
            endDate: Date.now.startOfWeek.adding(days: 6),
            phase: phase,
            sessions: [session],
            isRecoveryWeek: false,
            targetVolumeKm: 60,
            targetElevationGainM: 1500
        )
        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: []
        )
    }

    private func makeVM(
        runRepo: MockRunRepository = MockRunRepository(),
        raceRepo: MockRaceRepository = MockRaceRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository()
    ) -> DashboardViewModel {
        DashboardViewModel(
            planRepository: planRepo,
            runRepository: runRepo,
            athleteRepository: MockAthleteRepository(),
            fitnessRepository: MockFitnessRepository(),
            fitnessCalculator: MockCalculateFitnessUseCase(),
            raceRepository: raceRepo,
            finishTimeEstimator: MockEstimateFinishTimeUseCase(),
            finishEstimateRepository: MockFinishEstimateRepository()
        )
    }

    @Test("lastRun loads from recent runs")
    func lastRunLoads() async {
        let runRepo = MockRunRepository()
        let run = makeRun()
        runRepo.runs = [run]

        let vm = makeVM(runRepo: runRepo)
        await vm.load()

        #expect(vm.lastRun?.id == run.id)
    }

    @Test("upcomingRaces sorted by date and filters past")
    func upcomingRacesSorted() async {
        let raceRepo = MockRaceRepository()
        let past = makeRace(name: "Past", date: .now.adding(days: -5))
        let soon = makeRace(name: "Soon", date: .now.adding(days: 10))
        let later = makeRace(name: "Later", date: .now.adding(days: 60))
        raceRepo.races = [later, past, soon]

        let vm = makeVM(raceRepo: raceRepo)
        await vm.load()

        #expect(vm.upcomingRaces.count == 2)
        #expect(vm.upcomingRaces.first?.name == "Soon")
        #expect(vm.upcomingRaces.last?.name == "Later")
    }

    @Test("upcomingRaces limited to 3")
    func upcomingRacesLimited() async {
        let raceRepo = MockRaceRepository()
        for i in 1...5 {
            raceRepo.races.append(makeRace(name: "Race \(i)", date: .now.adding(days: i * 10)))
        }

        let vm = makeVM(raceRepo: raceRepo)
        await vm.load()

        #expect(vm.upcomingRaces.count == 3)
    }

    @Test("currentPhase from current week")
    func currentPhase() async {
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = makePlan(phase: .peak)

        let vm = makeVM(planRepo: planRepo)
        await vm.load()

        #expect(vm.currentPhase == .peak)
    }

    @Test("weekly targets from current week")
    func weeklyTargets() async {
        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = makePlan()

        let vm = makeVM(planRepo: planRepo)
        await vm.load()

        #expect(vm.weeklyTargetDistanceKm == 60)
        #expect(vm.weeklyTargetElevationM == 1500)
    }

    @Test("recentFormHistory filters to 14 days")
    func recentFormHistory() {
        let vm = makeVM()
        vm.fitnessHistory = (0..<28).map { i in
            FitnessSnapshot(
                id: UUID(),
                date: Date.now.adding(days: -i),
                fitness: 40,
                fatigue: 30,
                form: 10,
                weeklyVolumeKm: 50,
                weeklyElevationGainM: 1000,
                weeklyDuration: 18000,
                acuteToChronicRatio: 1.0,
                monotony: 1.5
            )
        }

        let recent = vm.recentFormHistory
        #expect(recent.count >= 14 && recent.count <= 15) // ~14 days window
        #expect(recent.count < 28) // definitely filtered
    }
}
