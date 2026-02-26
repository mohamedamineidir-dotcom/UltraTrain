import Foundation
import Testing
import SwiftData
@testable import UltraTrain

@Suite("SyncedRunRepository Tests", .serialized)
@MainActor
struct SyncedRunRepositoryTests {

    private let athleteId = UUID()

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            CompletedRunSwiftDataModel.self,
            SplitSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeRun(
        id: UUID = UUID(),
        athleteId: UUID? = nil,
        distanceKm: Double = 15.0,
        elevationGainM: Double = 500,
        duration: TimeInterval = 5400,
        notes: String? = nil
    ) -> CompletedRun {
        CompletedRun(
            id: id,
            athleteId: athleteId ?? self.athleteId,
            date: Date(),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 450,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: notes,
            pausedDuration: 0
        )
    }

    private func makeSUT(
        container: ModelContainer? = nil,
        syncService: MockSyncQueueService = MockSyncQueueService(),
        remoteDataSource: RemoteRunDataSource? = nil,
        authService: MockAuthService? = nil,
        restoreService: RunRestoreService? = nil
    ) throws -> (SyncedRunRepository, LocalRunRepository, MockSyncQueueService, MockAuthService?) {
        let cont = try container ?? makeContainer()
        let local = LocalRunRepository(modelContainer: cont)
        let auth = authService ?? MockAuthService()
        let sut = SyncedRunRepository(
            local: local,
            syncService: syncService,
            restoreService: restoreService,
            remoteDataSource: remoteDataSource,
            authService: auth
        )
        return (sut, local, syncService, auth)
    }

    // MARK: - getRuns

    @Test("getRuns returns locally saved runs")
    func getRunsReturnsLocalRuns() async throws {
        let (sut, local, _, _) = try makeSUT()
        let run = makeRun()
        try await local.saveRun(run)

        let result = try await sut.getRuns(for: athleteId)

        #expect(result.count == 1)
        #expect(result[0].id == run.id)
    }

    @Test("getRuns returns empty array when no runs exist and no restore service")
    func getRunsReturnsEmptyWhenNoRunsAndNoRestore() async throws {
        let (sut, _, _, _) = try makeSUT()

        let result = try await sut.getRuns(for: athleteId)

        #expect(result.isEmpty)
    }

    @Test("getRuns filters runs by athlete ID")
    func getRunsFiltersByAthleteId() async throws {
        let (sut, local, _, _) = try makeSUT()
        let otherAthleteId = UUID()
        let run1 = makeRun(athleteId: athleteId)
        let run2 = makeRun(athleteId: otherAthleteId)
        try await local.saveRun(run1)
        try await local.saveRun(run2)

        let result = try await sut.getRuns(for: athleteId)

        #expect(result.count == 1)
        #expect(result[0].athleteId == athleteId)
    }

    // MARK: - getRun

    @Test("getRun returns matching run by ID")
    func getRunReturnsById() async throws {
        let (sut, local, _, _) = try makeSUT()
        let run = makeRun()
        try await local.saveRun(run)

        let result = try await sut.getRun(id: run.id)

        #expect(result != nil)
        #expect(result?.id == run.id)
    }

    @Test("getRun returns nil for unknown ID")
    func getRunReturnsNilForUnknown() async throws {
        let (sut, _, _, _) = try makeSUT()

        let result = try await sut.getRun(id: UUID())

        #expect(result == nil)
    }

    // MARK: - saveRun

    @Test("saveRun persists locally and enqueues upload")
    func saveRunPersistsAndEnqueues() async throws {
        let syncService = MockSyncQueueService()
        let (sut, local, _, _) = try makeSUT(syncService: syncService)
        let run = makeRun()

        try await sut.saveRun(run)

        let saved = try await local.getRun(id: run.id)
        #expect(saved != nil)
        #expect(saved?.distanceKm == 15.0)
        #expect(syncService.enqueuedUploads.contains(run.id))
    }

    @Test("saveRun enqueues upload with correct run ID")
    func saveRunEnqueuesCorrectRunId() async throws {
        let syncService = MockSyncQueueService()
        let (sut, _, _, _) = try makeSUT(syncService: syncService)
        let runId = UUID()
        let run = makeRun(id: runId)

        try await sut.saveRun(run)

        #expect(syncService.enqueuedUploads == [runId])
    }

    // MARK: - updateRun

    @Test("updateRun persists changes locally")
    func updateRunPersistsLocally() async throws {
        let (sut, local, _, _) = try makeSUT()
        let run = makeRun(notes: "original")
        try await local.saveRun(run)

        var updated = run
        updated.notes = "updated notes"
        try await sut.updateRun(updated)

        let fetched = try await local.getRun(id: run.id)
        #expect(fetched?.notes == "updated notes")
    }

    // MARK: - deleteRun

    @Test("deleteRun removes from local storage")
    func deleteRunRemovesLocally() async throws {
        let (sut, local, _, _) = try makeSUT()
        let run = makeRun()
        try await local.saveRun(run)

        try await sut.deleteRun(id: run.id)

        let result = try await local.getRun(id: run.id)
        #expect(result == nil)
    }

    // MARK: - getRecentRuns

    @Test("getRecentRuns respects limit parameter")
    func getRecentRunsRespectsLimit() async throws {
        let (sut, local, _, _) = try makeSUT()
        for i in 0..<5 {
            let run = makeRun(distanceKm: Double(i + 1) * 5)
            try await local.saveRun(run)
        }

        let result = try await sut.getRecentRuns(limit: 3)

        #expect(result.count == 3)
    }

    @Test("getRecentRuns returns empty when no runs exist and no restore service")
    func getRecentRunsReturnsEmptyWithNoRestore() async throws {
        let (sut, _, _, _) = try makeSUT()

        let result = try await sut.getRecentRuns(limit: 5)

        #expect(result.isEmpty)
    }

    // MARK: - updateLinkedSession

    @Test("updateLinkedSession updates local and enqueues sync")
    func updateLinkedSessionUpdatesAndEnqueues() async throws {
        let syncService = MockSyncQueueService()
        let (sut, local, _, _) = try makeSUT(syncService: syncService)
        let run = makeRun()
        try await local.saveRun(run)
        let sessionId = UUID()

        try await sut.updateLinkedSession(runId: run.id, sessionId: sessionId)

        let fetched = try await local.getRun(id: run.id)
        #expect(fetched?.linkedSessionId == sessionId)
        let hasEnqueuedOp = syncService.enqueuedOperations.contains {
            $0.type == .runUpload && $0.entityId == run.id
        }
        #expect(hasEnqueuedOp)
    }
}
