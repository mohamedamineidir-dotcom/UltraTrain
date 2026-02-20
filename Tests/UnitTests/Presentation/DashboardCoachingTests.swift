import Foundation
import Testing
@testable import UltraTrain

@Suite("Dashboard Coaching Integration Tests")
@MainActor
struct DashboardCoachingTests {

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
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeSnapshot(form: Double = 10) -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(),
            date: .now,
            fitness: 50,
            fatigue: 50 - form,
            form: form,
            weeklyVolumeKm: 40,
            weeklyElevationGainM: 800,
            weeklyDuration: 14400,
            acuteToChronicRatio: 1.0,
            monotony: 1.0
        )
    }

    private func makeViewModel(
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        fitnessCalc: MockCalculateFitnessUseCase = MockCalculateFitnessUseCase()
    ) -> DashboardViewModel {
        DashboardViewModel(
            planRepository: MockTrainingPlanRepository(),
            runRepository: runRepo,
            athleteRepository: athleteRepo,
            fitnessRepository: MockFitnessRepository(),
            fitnessCalculator: fitnessCalc,
            raceRepository: MockRaceRepository(),
            finishTimeEstimator: MockEstimateFinishTimeUseCase(),
            finishEstimateRepository: MockFinishEstimateRepository(),
            healthKitService: MockHealthKitService(),
            recoveryRepository: MockRecoveryRepository()
        )
    }

    @Test("Coaching insights empty when no runs")
    func emptyWithNoRuns() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let vm = makeViewModel(athleteRepo: athleteRepo)
        await vm.load()

        #expect(vm.coachingInsights.isEmpty)
    }

    @Test("Coaching insights populated after load with peaking form")
    func insightsWithPeakingForm() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]

        let fitnessCalc = MockCalculateFitnessUseCase()
        fitnessCalc.resultSnapshot = makeSnapshot(form: 20)

        let vm = makeViewModel(runRepo: runRepo, athleteRepo: athleteRepo, fitnessCalc: fitnessCalc)
        await vm.load()

        #expect(!vm.coachingInsights.isEmpty)
        #expect(vm.coachingInsights.contains { $0.type == .formPeaking })
    }

    @Test("Coaching insights include recovery when fatigued")
    func recoveryInsight() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()

        let runRepo = MockRunRepository()
        runRepo.runs = [makeRun()]

        let fitnessCalc = MockCalculateFitnessUseCase()
        fitnessCalc.resultSnapshot = makeSnapshot(form: -20)

        let vm = makeViewModel(runRepo: runRepo, athleteRepo: athleteRepo, fitnessCalc: fitnessCalc)
        await vm.load()

        #expect(vm.coachingInsights.contains { $0.type == .recoveryNeeded })
    }
}
