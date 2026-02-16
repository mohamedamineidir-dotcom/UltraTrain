import Foundation
import Testing
@testable import UltraTrain

@Suite("Training Load ViewModel Tests")
struct TrainingLoadViewModelTests {

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

    private func makeSummary(
        currentLoad: Double = 25,
        previousLoad: Double = 20,
        monotony: Double = 1.2,
        acr: Double = 1.0
    ) -> TrainingLoadSummary {
        let now = Date.now
        let currentWeek = WeeklyLoadData(
            weekStartDate: now.startOfWeek,
            actualLoad: currentLoad,
            distanceKm: 20,
            elevationGainM: 500,
            duration: 7200
        )
        let previousWeek = WeeklyLoadData(
            weekStartDate: now.adding(weeks: -1).startOfWeek,
            actualLoad: previousLoad
        )
        let history = [previousWeek, currentWeek]
        let acrTrend = [ACRDataPoint(date: now, value: acr)]

        return TrainingLoadSummary(
            currentWeekLoad: currentWeek,
            weeklyHistory: history,
            acrTrend: acrTrend,
            monotony: monotony,
            monotonyLevel: MonotonyLevel(monotony: monotony)
        )
    }

    @MainActor
    private func makeViewModel(
        calc: MockCalculateTrainingLoadUseCase = MockCalculateTrainingLoadUseCase(),
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository()
    ) -> TrainingLoadViewModel {
        TrainingLoadViewModel(
            trainingLoadCalculator: calc,
            runRepository: runRepo,
            athleteRepository: athleteRepo,
            planRepository: planRepo
        )
    }

    // MARK: - Loading

    @Test("Load populates summary")
    @MainActor
    func loadPopulatesSummary() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]
        let calc = MockCalculateTrainingLoadUseCase()
        calc.resultSummary = makeSummary()

        let vm = makeViewModel(calc: calc, runRepo: runRepo, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.summary != nil)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load with no athlete returns nil summary")
    @MainActor
    func loadNoAthlete() async {
        let vm = makeViewModel()
        await vm.load()

        #expect(vm.summary == nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load handles error gracefully")
    @MainActor
    func loadHandlesError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let calc = MockCalculateTrainingLoadUseCase()
        calc.shouldThrow = true

        let vm = makeViewModel(calc: calc, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.summary == nil)
        #expect(vm.error != nil)
    }

    // MARK: - Computed Properties

    @Test("Current load formatted shows effort value")
    @MainActor
    func currentLoadFormatted() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let calc = MockCalculateTrainingLoadUseCase()
        calc.resultSummary = makeSummary(currentLoad: 42.7)

        let vm = makeViewModel(calc: calc, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.currentLoadFormatted == "43")
    }

    @Test("Load trend shows up when increasing")
    @MainActor
    func loadTrendUp() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let calc = MockCalculateTrainingLoadUseCase()
        calc.resultSummary = makeSummary(currentLoad: 30, previousLoad: 20)

        let vm = makeViewModel(calc: calc, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.loadTrend == .up)
    }

    @Test("Load trend shows down when decreasing")
    @MainActor
    func loadTrendDown() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let calc = MockCalculateTrainingLoadUseCase()
        calc.resultSummary = makeSummary(currentLoad: 15, previousLoad: 30)

        let vm = makeViewModel(calc: calc, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.loadTrend == .down)
    }

    @Test("ACR status shows injury risk above 1.5")
    @MainActor
    func acrInjuryRisk() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let calc = MockCalculateTrainingLoadUseCase()
        calc.resultSummary = makeSummary(acr: 1.8)

        let vm = makeViewModel(calc: calc, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.acrStatusLabel == "Injury Risk")
    }

    @Test("ACR status shows optimal in range")
    @MainActor
    func acrOptimal() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let calc = MockCalculateTrainingLoadUseCase()
        calc.resultSummary = makeSummary(acr: 1.0)

        let vm = makeViewModel(calc: calc, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.acrStatusLabel == "Optimal")
    }

    @Test("Monotony description for high monotony warns user")
    @MainActor
    func monotonyHighDescription() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let calc = MockCalculateTrainingLoadUseCase()
        calc.resultSummary = makeSummary(monotony: 2.5)

        let vm = makeViewModel(calc: calc, athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.monotonyDescription.contains("repetitive"))
    }
}
