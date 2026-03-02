import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalRecoveryRepository Tests")
@MainActor
struct LocalRecoveryRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([RecoverySnapshotSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeRecoveryScore(
        overallScore: Int = 75,
        sleepQualityScore: Int = 80,
        sleepConsistencyScore: Int = 70,
        restingHRScore: Int = 85,
        trainingLoadBalanceScore: Int = 65,
        recommendation: String = "Light training recommended",
        status: RecoveryStatus = .good
    ) -> RecoveryScore {
        RecoveryScore(
            id: UUID(),
            date: Date(),
            overallScore: overallScore,
            sleepQualityScore: sleepQualityScore,
            sleepConsistencyScore: sleepConsistencyScore,
            restingHRScore: restingHRScore,
            trainingLoadBalanceScore: trainingLoadBalanceScore,
            recommendation: recommendation,
            status: status
        )
    }

    private func makeSnapshot(
        id: UUID = UUID(),
        date: Date = Date(),
        recoveryScore: RecoveryScore? = nil,
        restingHeartRate: Int? = 48
    ) -> RecoverySnapshot {
        RecoverySnapshot(
            id: id,
            date: date,
            recoveryScore: recoveryScore ?? makeRecoveryScore(),
            sleepEntry: nil,
            restingHeartRate: restingHeartRate,
            hrvReading: nil,
            readinessScore: nil
        )
    }

    // MARK: - Save & Fetch Latest

    @Test("Save snapshot and fetch latest returns the saved snapshot")
    func saveAndFetchLatest() async throws {
        let container = try makeContainer()
        let repo = LocalRecoveryRepository(modelContainer: container)
        let score = makeRecoveryScore(overallScore: 85, status: .excellent)
        let snapshot = makeSnapshot(recoveryScore: score)

        try await repo.saveSnapshot(snapshot)
        let fetched = try await repo.getLatestSnapshot()

        #expect(fetched != nil)
        #expect(fetched?.id == snapshot.id)
        #expect(fetched?.recoveryScore.overallScore == 85)
        #expect(fetched?.recoveryScore.status == .excellent)
    }

    @Test("Get latest snapshot returns nil when empty")
    func getLatestReturnsNilWhenEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalRecoveryRepository(modelContainer: container)

        let fetched = try await repo.getLatestSnapshot()
        #expect(fetched == nil)
    }

    @Test("Get latest snapshot returns most recent by date")
    func getLatestReturnsMostRecent() async throws {
        let container = try makeContainer()
        let repo = LocalRecoveryRepository(modelContainer: container)

        let older = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
            recoveryScore: makeRecoveryScore(overallScore: 60, status: .moderate)
        )
        let newer = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
            recoveryScore: makeRecoveryScore(overallScore: 90, status: .excellent)
        )
        try await repo.saveSnapshot(older)
        try await repo.saveSnapshot(newer)

        let fetched = try await repo.getLatestSnapshot()
        #expect(fetched?.recoveryScore.overallScore == 90)
    }

    // MARK: - Date Range Query

    @Test("Get snapshots within date range filters correctly")
    func getSnapshotsInDateRange() async throws {
        let container = try makeContainer()
        let repo = LocalRecoveryRepository(modelContainer: container)

        let now = Date.now
        let snap1 = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -14, to: now)!
        )
        let snap2 = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -5, to: now)!
        )
        let snap3 = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -1, to: now)!
        )
        try await repo.saveSnapshot(snap1)
        try await repo.saveSnapshot(snap2)
        try await repo.saveSnapshot(snap3)

        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let results = try await repo.getSnapshots(from: startDate, to: now)

        #expect(results.count == 2)
    }

    @Test("Get snapshots returns empty for range with no data")
    func getSnapshotsReturnsEmptyForNoData() async throws {
        let container = try makeContainer()
        let repo = LocalRecoveryRepository(modelContainer: container)

        let snapshot = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -30, to: .now)!
        )
        try await repo.saveSnapshot(snapshot)

        let startDate = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
        let results = try await repo.getSnapshots(from: startDate, to: .now)

        #expect(results.isEmpty)
    }

    // MARK: - Recovery Status Round-trip

    @Test("Recovery status preserved through round-trip")
    func recoveryStatusPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalRecoveryRepository(modelContainer: container)

        let poorScore = makeRecoveryScore(overallScore: 30, status: .poor)
        let snapshot = makeSnapshot(recoveryScore: poorScore)

        try await repo.saveSnapshot(snapshot)
        let fetched = try await repo.getLatestSnapshot()

        #expect(fetched?.recoveryScore.status == .poor)
        #expect(fetched?.recoveryScore.overallScore == 30)
    }

    @Test("Resting heart rate preserved through round-trip")
    func restingHeartRatePreserved() async throws {
        let container = try makeContainer()
        let repo = LocalRecoveryRepository(modelContainer: container)

        let snapshot = makeSnapshot(restingHeartRate: 42)
        try await repo.saveSnapshot(snapshot)

        let fetched = try await repo.getLatestSnapshot()
        #expect(fetched?.restingHeartRate == 42)
    }
}
