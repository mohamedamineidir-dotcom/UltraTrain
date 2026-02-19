import Foundation
import Testing
@testable import UltraTrain

@Suite("StravaUploadQueueService Tests")
struct StravaUploadQueueServiceTests {

    private let athleteId = UUID()

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
            gpsTrack: [
                TrackPoint(latitude: 45.0, longitude: 6.0, altitudeM: 1000, timestamp: Date.now, heartRate: 140)
            ],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeDependencies() -> (
        queueRepo: MockStravaUploadQueueRepository,
        runRepo: MockRunRepository,
        uploadService: MockStravaUploadService,
        sut: StravaUploadQueueService
    ) {
        let queueRepo = MockStravaUploadQueueRepository()
        let runRepo = MockRunRepository()
        let uploadService = MockStravaUploadService()
        let sut = StravaUploadQueueService(
            queueRepository: queueRepo,
            runRepository: runRepo,
            uploadService: uploadService
        )
        return (queueRepo, runRepo, uploadService, sut)
    }

    // MARK: - Enqueue

    @Test("Enqueue creates a pending item")
    func enqueueCreatesPendingItem() async throws {
        let (queueRepo, _, _, sut) = makeDependencies()
        let runId = UUID()

        try await sut.enqueueUpload(runId: runId)

        #expect(queueRepo.items.count == 1)
        #expect(queueRepo.items[0].runId == runId)
        #expect(queueRepo.items[0].status == .pending)
    }

    @Test("Enqueue skips if item already pending")
    func enqueueSkipsExistingPending() async throws {
        let (queueRepo, _, _, sut) = makeDependencies()
        let runId = UUID()

        try await sut.enqueueUpload(runId: runId)
        try await sut.enqueueUpload(runId: runId)

        #expect(queueRepo.items.count == 1)
    }

    @Test("Enqueue resets failed item for retry")
    func enqueueResetsFailedItem() async throws {
        let (queueRepo, _, _, sut) = makeDependencies()
        let runId = UUID()
        let failedItem = StravaUploadQueueItem(
            id: UUID(),
            runId: runId,
            status: .failed,
            retryCount: 2,
            lastAttempt: Date.now,
            stravaActivityId: nil,
            errorMessage: "Network error",
            createdAt: Date.now
        )
        queueRepo.items = [failedItem]

        try await sut.enqueueUpload(runId: runId)

        #expect(queueRepo.items.count == 1)
        #expect(queueRepo.items[0].status == .pending)
        #expect(queueRepo.items[0].retryCount == 0)
        #expect(queueRepo.items[0].errorMessage == nil)
    }

    // MARK: - Process Queue

    @Test("Process queue uploads successfully and updates run")
    func processQueueSuccess() async throws {
        let (queueRepo, runRepo, uploadService, sut) = makeDependencies()
        let run = makeRun()
        runRepo.runs = [run]
        uploadService.returnedActivityId = 99999
        let item = StravaUploadQueueItem(
            id: UUID(),
            runId: run.id,
            status: .pending,
            retryCount: 0,
            lastAttempt: nil,
            stravaActivityId: nil,
            errorMessage: nil,
            createdAt: Date.now
        )
        queueRepo.items = [item]

        await sut.processQueue()

        #expect(queueRepo.items[0].status == .completed)
        #expect(queueRepo.items[0].stravaActivityId == 99999)
        #expect(runRepo.updatedRun?.stravaActivityId == 99999)
    }

    @Test("Process queue marks item failed on upload error")
    func processQueueFailure() async throws {
        let (queueRepo, runRepo, uploadService, sut) = makeDependencies()
        let run = makeRun()
        runRepo.runs = [run]
        uploadService.shouldThrow = true
        let item = StravaUploadQueueItem(
            id: UUID(),
            runId: run.id,
            status: .pending,
            retryCount: 0,
            lastAttempt: nil,
            stravaActivityId: nil,
            errorMessage: nil,
            createdAt: Date.now
        )
        queueRepo.items = [item]

        await sut.processQueue()

        #expect(queueRepo.items[0].status == .failed)
        #expect(queueRepo.items[0].retryCount == 1)
        #expect(queueRepo.items[0].errorMessage != nil)
    }

    @Test("Process queue skips items that reached max retries")
    func processQueueSkipsMaxRetries() async throws {
        let (queueRepo, _, uploadService, sut) = makeDependencies()
        let item = StravaUploadQueueItem(
            id: UUID(),
            runId: UUID(),
            status: .failed,
            retryCount: 3,
            lastAttempt: nil,
            stravaActivityId: nil,
            errorMessage: "Previous error",
            createdAt: Date.now
        )
        queueRepo.items = [item]

        await sut.processQueue()

        #expect(uploadService.uploadedRun == nil)
        #expect(queueRepo.items[0].status == .failed)
    }

    @Test("Process queue deletes orphaned items when run not found")
    func processQueueDeletesOrphans() async throws {
        let (queueRepo, _, _, sut) = makeDependencies()
        let item = StravaUploadQueueItem(
            id: UUID(),
            runId: UUID(),
            status: .pending,
            retryCount: 0,
            lastAttempt: nil,
            stravaActivityId: nil,
            errorMessage: nil,
            createdAt: Date.now
        )
        queueRepo.items = [item]

        await sut.processQueue()

        #expect(queueRepo.items.isEmpty)
    }

    @Test("Process queue respects retry delay")
    func processQueueRespectsRetryDelay() async throws {
        let (queueRepo, runRepo, uploadService, sut) = makeDependencies()
        let run = makeRun()
        runRepo.runs = [run]
        let item = StravaUploadQueueItem(
            id: UUID(),
            runId: run.id,
            status: .failed,
            retryCount: 1,
            lastAttempt: Date.now,
            stravaActivityId: nil,
            errorMessage: "Timeout",
            createdAt: Date.now
        )
        queueRepo.items = [item]

        await sut.processQueue()

        // lastAttempt is now, nextRetryDelay is 30s, so it should be skipped
        #expect(uploadService.uploadedRun == nil)
    }

    // MARK: - Get Pending Count

    @Test("Get pending count returns pending and failed items")
    func getPendingCount() async throws {
        let (queueRepo, _, _, sut) = makeDependencies()
        queueRepo.items = [
            StravaUploadQueueItem(id: UUID(), runId: UUID(), status: .pending, retryCount: 0, lastAttempt: nil, stravaActivityId: nil, errorMessage: nil, createdAt: Date.now),
            StravaUploadQueueItem(id: UUID(), runId: UUID(), status: .failed, retryCount: 1, lastAttempt: nil, stravaActivityId: nil, errorMessage: "err", createdAt: Date.now),
            StravaUploadQueueItem(id: UUID(), runId: UUID(), status: .completed, retryCount: 0, lastAttempt: nil, stravaActivityId: 123, errorMessage: nil, createdAt: Date.now)
        ]

        let count = await sut.getPendingCount()

        #expect(count == 2)
    }
}
