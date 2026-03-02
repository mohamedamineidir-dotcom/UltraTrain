import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalFitnessRepository Tests")
@MainActor
struct LocalFitnessRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([FitnessSnapshotSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeSnapshot(
        id: UUID = UUID(),
        date: Date = Date(),
        fitness: Double = 45.0,
        fatigue: Double = 30.0,
        form: Double = 15.0,
        weeklyVolumeKm: Double = 80,
        weeklyElevationGainM: Double = 3000,
        weeklyDuration: TimeInterval = 36000,
        acuteToChronicRatio: Double = 1.1,
        monotony: Double = 1.5
    ) -> FitnessSnapshot {
        FitnessSnapshot(
            id: id,
            date: date,
            fitness: fitness,
            fatigue: fatigue,
            form: form,
            weeklyVolumeKm: weeklyVolumeKm,
            weeklyElevationGainM: weeklyElevationGainM,
            weeklyDuration: weeklyDuration,
            acuteToChronicRatio: acuteToChronicRatio,
            monotony: monotony
        )
    }

    // MARK: - Save & Fetch

    @Test("Save snapshot and fetch latest returns the saved snapshot")
    func saveAndFetchLatest() async throws {
        let container = try makeContainer()
        let repo = LocalFitnessRepository(modelContainer: container)
        let snapshot = makeSnapshot(fitness: 55.0, fatigue: 35.0, form: 20.0)

        try await repo.saveSnapshot(snapshot)
        let fetched = try await repo.getLatestSnapshot()

        #expect(fetched != nil)
        #expect(fetched?.id == snapshot.id)
        #expect(fetched?.fitness == 55.0)
        #expect(fetched?.fatigue == 35.0)
        #expect(fetched?.form == 20.0)
        #expect(fetched?.weeklyVolumeKm == 80)
    }

    @Test("Get latest snapshot returns nil when empty")
    func getLatestReturnsNilWhenEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalFitnessRepository(modelContainer: container)

        let fetched = try await repo.getLatestSnapshot()
        #expect(fetched == nil)
    }

    @Test("Get latest snapshot returns most recent by date")
    func getLatestReturnsMostRecent() async throws {
        let container = try makeContainer()
        let repo = LocalFitnessRepository(modelContainer: container)

        let older = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -7, to: .now)!,
            fitness: 40.0
        )
        let newer = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
            fitness: 50.0
        )
        try await repo.saveSnapshot(older)
        try await repo.saveSnapshot(newer)

        let fetched = try await repo.getLatestSnapshot()
        #expect(fetched?.fitness == 50.0)
    }

    // MARK: - Date Range Query

    @Test("Get snapshots within date range filters correctly")
    func getSnapshotsInDateRange() async throws {
        let container = try makeContainer()
        let repo = LocalFitnessRepository(modelContainer: container)

        let now = Date.now
        let snapshot1 = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -10, to: now)!,
            fitness: 30.0
        )
        let snapshot2 = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -5, to: now)!,
            fitness: 40.0
        )
        let snapshot3 = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
            fitness: 50.0
        )
        try await repo.saveSnapshot(snapshot1)
        try await repo.saveSnapshot(snapshot2)
        try await repo.saveSnapshot(snapshot3)

        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let endDate = now
        let results = try await repo.getSnapshots(from: startDate, to: endDate)

        #expect(results.count == 2)
    }

    @Test("Get snapshots returns empty array for range with no data")
    func getSnapshotsReturnsEmptyForNoData() async throws {
        let container = try makeContainer()
        let repo = LocalFitnessRepository(modelContainer: container)

        let snapshot = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -30, to: .now)!
        )
        try await repo.saveSnapshot(snapshot)

        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        let endDate = Date.now
        let results = try await repo.getSnapshots(from: startDate, to: endDate)

        #expect(results.isEmpty)
    }

    @Test("Get snapshots returns results sorted by date ascending")
    func getSnapshotsSortedByDate() async throws {
        let container = try makeContainer()
        let repo = LocalFitnessRepository(modelContainer: container)

        let now = Date.now
        let snapshot1 = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -3, to: now)!,
            fitness: 40.0
        )
        let snapshot2 = makeSnapshot(
            date: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
            fitness: 50.0
        )
        try await repo.saveSnapshot(snapshot2)
        try await repo.saveSnapshot(snapshot1)

        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let results = try await repo.getSnapshots(from: startDate, to: now)

        #expect(results.count == 2)
        #expect(results[0].fitness == 40.0)
        #expect(results[1].fitness == 50.0)
    }

    // MARK: - Round-trip Values

    @Test("All fields preserved through save and fetch round-trip")
    func allFieldsPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalFitnessRepository(modelContainer: container)

        let snapshot = makeSnapshot(
            fitness: 62.5,
            fatigue: 40.3,
            form: 22.2,
            weeklyVolumeKm: 105.7,
            weeklyElevationGainM: 4500,
            weeklyDuration: 54000,
            acuteToChronicRatio: 1.35,
            monotony: 1.8
        )
        try await repo.saveSnapshot(snapshot)
        let fetched = try await repo.getLatestSnapshot()

        #expect(fetched?.weeklyElevationGainM == 4500)
        #expect(fetched?.weeklyDuration == 54000)
        #expect(fetched?.acuteToChronicRatio == 1.35)
        #expect(fetched?.monotony == 1.8)
    }
}
