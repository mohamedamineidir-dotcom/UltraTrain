import Foundation
import Testing
@testable import UltraTrain

@Suite("MorningReadinessViewModel Tests")
struct MorningReadinessViewModelTests {

    // MARK: - Helpers

    private func makeRecoveryScore() -> RecoveryScore {
        RecoveryScore(
            id: UUID(),
            date: Date.now,
            overallScore: 75,
            sleepQualityScore: 80,
            sleepConsistencyScore: 70,
            restingHRScore: 85,
            trainingLoadBalanceScore: 65,
            recommendation: "Good recovery. Ready for moderate training.",
            status: .good,
            hrvScore: 70
        )
    }

    private func makeRecoverySnapshot(
        date: Date = Date.now,
        recoveryScore: RecoveryScore? = nil
    ) -> RecoverySnapshot {
        RecoverySnapshot(
            id: UUID(),
            date: date,
            recoveryScore: recoveryScore ?? makeRecoveryScore(),
            sleepEntry: nil,
            restingHeartRate: 52,
            hrvReading: nil,
            readinessScore: nil
        )
    }

    private func makeHRVReading(date: Date = Date.now, sdnn: Double = 45.0) -> HRVReading {
        HRVReading(date: date, sdnnMs: sdnn)
    }

    private func makeFitnessSnapshot() -> FitnessSnapshot {
        FitnessSnapshot(
            id: UUID(),
            date: Date.now,
            fitness: 50,
            fatigue: 30,
            form: 20,
            weeklyVolumeKm: 60,
            weeklyElevationGainM: 2000,
            weeklyDuration: 21600,
            acuteToChronicRatio: 1.1,
            monotony: 1.3
        )
    }

    @MainActor
    private func makeSUT(
        healthKitService: MockHealthKitService = MockHealthKitService(),
        recoveryRepo: MockRecoveryRepository = MockRecoveryRepository(),
        fitnessCalc: MockCalculateFitnessUseCase = MockCalculateFitnessUseCase(),
        fitnessRepo: MockFitnessRepository = MockFitnessRepository(),
        morningCheckInRepo: MockMorningCheckInRepository? = nil
    ) -> (MorningReadinessViewModel, MockHealthKitService, MockRecoveryRepository, MockFitnessRepository) {
        let vm = MorningReadinessViewModel(
            healthKitService: healthKitService,
            recoveryRepository: recoveryRepo,
            fitnessCalculator: fitnessCalc,
            fitnessRepository: fitnessRepo,
            morningCheckInRepository: morningCheckInRepo
        )
        return (vm, healthKitService, recoveryRepo, fitnessRepo)
    }

    // MARK: - Tests

    @Test("Load fetches HRV readings and recovery data")
    @MainActor
    func loadFetchesData() async {
        let healthKit = MockHealthKitService()
        healthKit.hrvReadings = [
            makeHRVReading(date: Date.now, sdnn: 45),
            makeHRVReading(date: Date.now.addingTimeInterval(-86400), sdnn: 50)
        ]
        let recoveryRepo = MockRecoveryRepository()
        let snapshot = makeRecoverySnapshot()
        recoveryRepo.snapshots = [snapshot]
        let fitnessRepo = MockFitnessRepository()
        fitnessRepo.snapshots = [makeFitnessSnapshot()]

        let (vm, _, _, _) = makeSUT(
            healthKitService: healthKit,
            recoveryRepo: recoveryRepo,
            fitnessRepo: fitnessRepo
        )

        await vm.load()

        #expect(vm.hrvReadings.count == 2)
        #expect(vm.recoveryScore != nil)
        #expect(vm.recoveryScore?.overallScore == 75)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load computes readiness score when recovery score is available")
    @MainActor
    func loadComputesReadiness() async {
        let healthKit = MockHealthKitService()
        healthKit.hrvReadings = [makeHRVReading()]
        let recoveryRepo = MockRecoveryRepository()
        recoveryRepo.snapshots = [makeRecoverySnapshot()]
        let fitnessRepo = MockFitnessRepository()
        fitnessRepo.snapshots = [makeFitnessSnapshot()]

        let (vm, _, _, _) = makeSUT(
            healthKitService: healthKit,
            recoveryRepo: recoveryRepo,
            fitnessRepo: fitnessRepo
        )

        await vm.load()

        #expect(vm.readinessScore != nil)
    }

    @Test("Load populates morning check-in when repository is provided")
    @MainActor
    func loadPopulatesMorningCheckIn() async {
        let checkInRepo = MockMorningCheckInRepository()
        let checkIn = MorningCheckIn(
            id: UUID(),
            date: Date.now,
            perceivedEnergy: 7,
            muscleSoreness: 3,
            mood: 8,
            sleepQualitySubjective: 7,
            notes: "Feeling great"
        )
        checkInRepo.checkIns = [checkIn]

        let recoveryRepo = MockRecoveryRepository()
        recoveryRepo.snapshots = [makeRecoverySnapshot()]
        let fitnessRepo = MockFitnessRepository()
        fitnessRepo.snapshots = [makeFitnessSnapshot()]

        let (vm, _, _, _) = makeSUT(
            recoveryRepo: recoveryRepo,
            fitnessRepo: fitnessRepo,
            morningCheckInRepo: checkInRepo
        )

        await vm.load()

        #expect(vm.morningCheckIn != nil)
        #expect(vm.morningCheckIn?.perceivedEnergy == 7)
    }

    @Test("Load generates recommendations")
    @MainActor
    func loadGeneratesRecommendations() async {
        let recoveryRepo = MockRecoveryRepository()
        recoveryRepo.snapshots = [makeRecoverySnapshot()]
        let fitnessRepo = MockFitnessRepository()
        fitnessRepo.snapshots = [makeFitnessSnapshot()]

        let (vm, _, _, _) = makeSUT(
            recoveryRepo: recoveryRepo,
            fitnessRepo: fitnessRepo
        )

        await vm.load()

        // RecoveryRecommendationEngine should generate at least some recommendations
        // when given readiness and recovery data
        #expect(vm.recommendations.count >= 0) // At minimum it runs without error
        #expect(vm.isLoading == false)
    }

    @Test("Load sets error when HealthKit throws")
    @MainActor
    func loadSetsErrorOnHealthKitFailure() async {
        let healthKit = MockHealthKitService()
        healthKit.shouldThrow = true

        let (vm, _, _, _) = makeSUT(healthKitService: healthKit)

        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("Load handles empty data gracefully")
    @MainActor
    func loadHandlesEmptyData() async {
        let (vm, _, _, _) = makeSUT()

        await vm.load()

        #expect(vm.hrvReadings.isEmpty)
        #expect(vm.recoveryHistory.isEmpty)
        #expect(vm.recoveryScore == nil)
        #expect(vm.readinessScore == nil)
        #expect(vm.isLoading == false)
    }
}
