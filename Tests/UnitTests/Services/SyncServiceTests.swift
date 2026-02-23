import Foundation
import Testing
@testable import UltraTrain

@Suite("SyncService Tests", .serialized)
struct SyncServiceTests {

    private let athleteId = UUID()

    // MARK: - Helpers

    private func makeRun(id: UUID = UUID()) -> CompletedRun {
        CompletedRun(
            id: id,
            athleteId: athleteId,
            date: Date.now,
            distanceKm: 10,
            elevationGainM: 200,
            elevationLossM: 180,
            duration: 3600,
            averageHeartRate: 145,
            maxHeartRate: 170,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeItem(
        operationType: SyncOperationType = .runUpload,
        entityId: UUID = UUID(),
        status: SyncQueueItemStatus = .pending,
        retryCount: Int = 0,
        lastAttempt: Date? = nil
    ) -> SyncQueueItem {
        SyncQueueItem(
            id: UUID(),
            runId: operationType == .runUpload ? entityId : UUID(),
            operationType: operationType,
            entityId: entityId,
            status: status,
            retryCount: retryCount,
            lastAttempt: lastAttempt,
            errorMessage: nil,
            createdAt: Date()
        )
    }

    private func makeSUT(
        queueRepo: MockSyncQueueRepository = MockSyncQueueRepository(),
        runRepo: MockRunRepository = MockRunRepository(),
        authenticated: Bool = true
    ) -> (MockSyncQueueRepository, MockRunRepository, MockAuthService, SyncService) {
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated

        let stubURL = URL(string: "https://stub.test")!
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SyncTestURLProtocol.self]
        let session = URLSession(configuration: config)
        let apiClient = APIClient(
            baseURL: stubURL,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )

        let remoteRunDS = RemoteRunDataSource(apiClient: apiClient)

        let sut = SyncService(
            queueRepository: queueRepo,
            localRunRepository: runRepo as any RunRepository,
            remoteRunDataSource: remoteRunDS,
            authService: auth
        )
        return (queueRepo, runRepo, auth, sut)
    }

    // MARK: - enqueueOperation (use unauthenticated so processQueue is no-op)

    @Test("enqueueOperation creates a queue item")
    func enqueueCreatesItem() async throws {
        let (queueRepo, _, _, sut) = makeSUT(authenticated: false)
        let entityId = UUID()

        try await sut.enqueueOperation(.runUpload, entityId: entityId)

        let saved = queueRepo.items.first { $0.entityId == entityId }
        #expect(saved != nil)
        #expect(saved?.operationType == .runUpload)
        #expect(saved?.status == .pending)
    }

    @Test("enqueueOperation deduplicates existing pending item")
    func enqueueDeduplicates() async throws {
        let (queueRepo, _, _, sut) = makeSUT(authenticated: false)
        let entityId = UUID()

        try await sut.enqueueOperation(.athleteSync, entityId: entityId)
        try await sut.enqueueOperation(.athleteSync, entityId: entityId)

        let matching = queueRepo.items.filter {
            $0.entityId == entityId && $0.operationType == .athleteSync
        }
        #expect(matching.count == 1)
    }

    @Test("enqueueOperation resets failed item to pending")
    func enqueueResetsFailedItem() async throws {
        let (queueRepo, _, _, sut) = makeSUT(authenticated: false)
        let entityId = UUID()
        let failedItem = SyncQueueItem(
            id: UUID(),
            runId: UUID(),
            operationType: .raceSync,
            entityId: entityId,
            status: .failed,
            retryCount: 3,
            lastAttempt: Date.now,
            errorMessage: "Server error",
            createdAt: Date()
        )
        queueRepo.items = [failedItem]

        try await sut.enqueueOperation(.raceSync, entityId: entityId)

        let item = queueRepo.items.first { $0.entityId == entityId }
        #expect(item?.status == .pending)
        #expect(item?.retryCount == 0)
        #expect(item?.errorMessage == nil)
    }

    @Test("enqueueUpload sets operationType to runUpload and runId")
    func enqueueUploadSetsRunType() async throws {
        let (queueRepo, _, _, sut) = makeSUT(authenticated: false)
        let runId = UUID()

        try await sut.enqueueUpload(runId: runId)

        let item = queueRepo.items.first { $0.entityId == runId }
        #expect(item != nil)
        #expect(item?.operationType == .runUpload)
        #expect(item?.runId == runId)
    }

    @Test("enqueueOperation stores correct operation types")
    func enqueueStoresCorrectTypes() async throws {
        let (queueRepo, _, _, sut) = makeSUT(authenticated: false)

        try await sut.enqueueOperation(.runUpload, entityId: UUID())
        try await sut.enqueueOperation(.athleteSync, entityId: UUID())
        try await sut.enqueueOperation(.raceSync, entityId: UUID())
        try await sut.enqueueOperation(.raceDelete, entityId: UUID())
        try await sut.enqueueOperation(.trainingPlanSync, entityId: UUID())

        #expect(queueRepo.items.count == 5)
        let types = Set(queueRepo.items.map(\.operationType))
        #expect(types.contains(.runUpload))
        #expect(types.contains(.athleteSync))
        #expect(types.contains(.raceSync))
        #expect(types.contains(.raceDelete))
        #expect(types.contains(.trainingPlanSync))
    }

    // MARK: - processQueue

    @Test("processQueue skips when not authenticated")
    func processQueueSkipsWhenNotAuthenticated() async {
        let (queueRepo, _, _, sut) = makeSUT(authenticated: false)
        let item = makeItem()
        queueRepo.items = [item]

        await sut.processQueue()

        #expect(queueRepo.items[0].status == .pending)
    }

    @Test("processQueue respects retry delay")
    func processQueueRespectsRetryDelay() async {
        let (queueRepo, _, _, sut) = makeSUT()
        let item = makeItem(retryCount: 1, lastAttempt: Date.now)
        queueRepo.items = [item]

        await sut.processQueue()

        // lastAttempt = now, nextRetryDelay = 60s, should be skipped
        #expect(queueRepo.items[0].status == .pending)
    }

    @Test("processQueue removes orphaned run items")
    func processQueueRemovesOrphanedRunItems() async {
        let (queueRepo, _, _, sut) = makeSUT()
        let orphanRunId = UUID()
        let item = makeItem(operationType: .runUpload, entityId: orphanRunId)
        queueRepo.items = [item]

        SyncTestURLProtocol.responseData = nil
        SyncTestURLProtocol.statusCode = 200

        await sut.processQueue()

        // Run not found locally → item deleted from queue
        #expect(queueRepo.items.isEmpty)
    }

    @Test("processQueue completes run upload on success")
    func processQueueCompletesRunUpload() async {
        let (queueRepo, runRepo, _, sut) = makeSUT()
        let run = makeRun()
        runRepo.runs = [run]
        let item = makeItem(operationType: .runUpload, entityId: run.id)
        queueRepo.items = [item]

        // Stub a success response with snake_case keys
        let json = """
        {
            "id": "\(run.id.uuidString)",
            "date": "2026-02-20T08:30:00Z",
            "distance_km": 10,
            "elevation_gain_m": 200,
            "elevation_loss_m": 180,
            "duration": 3600,
            "average_heart_rate": 145,
            "max_heart_rate": 170,
            "average_pace_seconds_per_km": 360,
            "gps_track": [],
            "splits": [],
            "notes": null,
            "linked_session_id": null,
            "created_at": null,
            "updated_at": null
        }
        """
        SyncTestURLProtocol.responseData = Data(json.utf8)
        SyncTestURLProtocol.statusCode = 201

        await sut.processQueue()

        let updated = queueRepo.items.first { $0.entityId == run.id }
        #expect(updated?.status == .completed)
    }

    // MARK: - getPendingCount / getFailedCount / getQueueStatus

    @Test("getPendingCount returns correct count")
    func getPendingCountReturnsCorrectCount() async {
        let (queueRepo, _, _, sut) = makeSUT()
        queueRepo.items = [
            makeItem(status: .pending),
            makeItem(status: .failed),
            makeItem(status: .completed),
            makeItem(status: .uploading)
        ]

        let count = await sut.getPendingCount()
        #expect(count == 2)
    }

    @Test("getFailedCount returns correct count")
    func getFailedCountReturnsCorrectCount() async {
        let (queueRepo, _, _, sut) = makeSUT()
        queueRepo.items = [
            makeItem(status: .pending),
            makeItem(status: .failed),
            makeItem(status: .failed),
            makeItem(status: .completed)
        ]

        let count = await sut.getFailedCount()
        #expect(count == 2)
    }

    @Test("getQueueStatus returns status for run")
    func getQueueStatusReturnsStatus() async {
        let (queueRepo, _, _, sut) = makeSUT()
        let runId = UUID()
        var item = makeItem(operationType: .runUpload, entityId: runId)
        item.runId = runId
        queueRepo.items = [item]

        let status = await sut.getQueueStatus(forRunId: runId)
        #expect(status == .pending)
    }

    @Test("getQueueStatus returns nil for unknown run")
    func getQueueStatusReturnsNilForUnknown() async {
        let (_, _, _, sut) = makeSUT()

        let status = await sut.getQueueStatus(forRunId: UUID())
        #expect(status == nil)
    }
}

// MARK: - Stub URL Protocol for SyncService tests

private final class SyncTestURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseData: Data?
    nonisolated(unsafe) static var statusCode: Int = 200

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = Self.responseData {
            client?.urlProtocol(self, didLoad: data)
        } else {
            client?.urlProtocol(self, didLoad: Data("{}".utf8))
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
