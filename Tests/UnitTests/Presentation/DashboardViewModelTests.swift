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
            acuteToChronicRatio: acr
        )
    }

    @MainActor
    private func makeViewModel(
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        fitnessRepo: MockFitnessRepository = MockFitnessRepository(),
        fitnessCalc: MockCalculateFitnessUseCase = MockCalculateFitnessUseCase()
    ) -> DashboardViewModel {
        DashboardViewModel(
            planRepository: planRepo,
            runRepository: runRepo,
            athleteRepository: athleteRepo,
            fitnessRepository: fitnessRepo,
            fitnessCalculator: fitnessCalc
        )
    }

    // MARK: - Fitness Loading

    @Test("Load with no runs shows nil fitness")
    @MainActor
    func loadNoRuns() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.fitnessSnapshot == nil)
        #expect(vm.fitnessError == nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load with runs populates fitness snapshot")
    @MainActor
    func loadWithRuns() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let calc = MockCalculateFitnessUseCase()
        calc.resultSnapshot = makeSnapshot()

        let vm = makeViewModel(runRepo: runRepo, athleteRepo: athleteRepo, fitnessCalc: calc)
        await vm.load()

        #expect(vm.fitnessSnapshot != nil)
        #expect(vm.fitnessSnapshot?.fitness == 50)
    }

    @Test("Load saves snapshot to repository")
    @MainActor
    func loadSavesSnapshot() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let calc = MockCalculateFitnessUseCase()
        calc.resultSnapshot = makeSnapshot()
        let fitnessRepo = MockFitnessRepository()

        let vm = makeViewModel(runRepo: runRepo, athleteRepo: athleteRepo, fitnessRepo: fitnessRepo, fitnessCalc: calc)
        await vm.load()

        #expect(fitnessRepo.savedSnapshot != nil)
    }

    @Test("Load handles fitness error gracefully")
    @MainActor
    func loadHandlesFitnessError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let calc = MockCalculateFitnessUseCase()
        calc.shouldThrow = true

        let vm = makeViewModel(runRepo: runRepo, athleteRepo: athleteRepo, fitnessCalc: calc)
        await vm.load()

        #expect(vm.fitnessSnapshot == nil)
        #expect(vm.fitnessError != nil)
    }

    @Test("Plan loads independently of fitness errors")
    @MainActor
    func planLoadsIndependently() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true
        let planRepo = MockTrainingPlanRepository()
        let plan = TrainingPlan(
            id: UUID(), athleteId: UUID(), targetRaceId: UUID(),
            createdAt: .now, weeks: [], intermediateRaceIds: []
        )
        planRepo.activePlan = plan

        let vm = makeViewModel(planRepo: planRepo, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.plan != nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Fitness Status

    @Test("Fitness status returns noData when nil")
    @MainActor
    func statusNoData() {
        let vm = makeViewModel()
        #expect(vm.fitnessStatus == .noData)
    }

    @Test("Fitness status returns optimal for ACR in range")
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

    @Test("Fitness status returns detraining for ACR below 0.8")
    @MainActor
    func statusDetraining() {
        let vm = makeViewModel()
        vm.fitnessSnapshot = makeSnapshot(acr: 0.5)
        #expect(vm.fitnessStatus == .detraining)
    }

    // MARK: - Form Description

    @Test("Form description shows Fresh for positive form")
    @MainActor
    func formFresh() {
        let vm = makeViewModel()
        vm.fitnessSnapshot = FitnessSnapshot(
            id: UUID(), date: .now,
            fitness: 50, fatigue: 30, form: 20,
            weeklyVolumeKm: 0, weeklyElevationGainM: 0,
            weeklyDuration: 0, acuteToChronicRatio: 0.6
        )
        #expect(vm.formDescription == "Fresh")
    }

    @Test("Form description shows Fatigued for negative form")
    @MainActor
    func formFatigued() {
        let vm = makeViewModel()
        vm.fitnessSnapshot = FitnessSnapshot(
            id: UUID(), date: .now,
            fitness: 30, fatigue: 50, form: -20,
            weeklyVolumeKm: 0, weeklyElevationGainM: 0,
            weeklyDuration: 0, acuteToChronicRatio: 1.67
        )
        #expect(vm.formDescription == "Fatigued")
    }
}
