import Foundation
import Testing
@testable import UltraTrain

@Suite("RecoveryHistory ViewModel Tests")
struct RecoveryHistoryViewModelTests {

    private func makeSnapshot(date: Date = .now, score: Int = 75) -> RecoverySnapshot {
        RecoverySnapshot(
            id: UUID(),
            date: date,
            recoveryScore: RecoveryScore(
                id: UUID(),
                date: date,
                overallScore: score,
                sleepQualityScore: score,
                sleepConsistencyScore: score,
                restingHRScore: score,
                trainingLoadBalanceScore: score,
                recommendation: "Good recovery",
                status: .good
            ),
            sleepEntry: nil,
            restingHeartRate: nil,
            hrvReading: nil,
            readinessScore: nil
        )
    }

    private func makeCheckIn(date: Date = .now) -> MorningCheckIn {
        MorningCheckIn(
            id: UUID(),
            date: date,
            perceivedEnergy: 3,
            muscleSoreness: 2,
            mood: 4,
            sleepQualitySubjective: 4,
            notes: nil
        )
    }

    @MainActor
    private func makeSUT(
        recoveryRepo: MockRecoveryRepository = MockRecoveryRepository(),
        checkInRepo: MockMorningCheckInRepository = MockMorningCheckInRepository()
    ) -> (RecoveryHistoryViewModel, MockRecoveryRepository, MockMorningCheckInRepository) {
        let vm = RecoveryHistoryViewModel(
            recoveryRepository: recoveryRepo,
            morningCheckInRepository: checkInRepo
        )
        return (vm, recoveryRepo, checkInRepo)
    }

    @Test("Load populates entries from snapshots")
    @MainActor
    func loadPopulatesEntries() async {
        let (vm, recoveryRepo, _) = makeSUT()
        recoveryRepo.snapshots = [
            makeSnapshot(date: .now),
            makeSnapshot(date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!)
        ]

        await vm.load()

        #expect(vm.entries.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Entries are sorted by date descending")
    @MainActor
    func entriesSortedDescending() async {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let (vm, recoveryRepo, _) = makeSUT()
        recoveryRepo.snapshots = [
            makeSnapshot(date: yesterday),
            makeSnapshot(date: .now)
        ]

        await vm.load()

        #expect(vm.entries.count == 2)
        #expect(vm.entries.first!.date > vm.entries.last!.date)
    }

    @Test("Check-ins are merged with snapshots by day")
    @MainActor
    func checkInsMergedByDay() async {
        let today = Date.now
        let (vm, recoveryRepo, checkInRepo) = makeSUT()
        recoveryRepo.snapshots = [makeSnapshot(date: today)]
        checkInRepo.checkIns = [makeCheckIn(date: today)]

        await vm.load()

        #expect(vm.entries.count == 1)
        #expect(vm.entries.first?.checkIn != nil)
    }

    @Test("Load with empty data returns empty entries")
    @MainActor
    func loadEmpty() async {
        let (vm, _, _) = makeSUT()
        await vm.load()
        #expect(vm.entries.isEmpty)
    }

    @Test("Load sets error on repository failure")
    @MainActor
    func loadSetsErrorOnFailure() async {
        let (vm, recoveryRepo, _) = makeSUT()
        recoveryRepo.shouldThrow = true

        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }
}
