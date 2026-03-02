import Foundation
@testable import UltraTrain

final class MockSyncQueueService: SyncQueueServiceProtocol, @unchecked Sendable {
    var enqueuedUploads: [UUID] = []
    var enqueuedOperations: [(type: SyncOperationType, entityId: UUID)] = []
    var processQueueCallCount = 0
    var shouldThrow = false

    var stubbedPendingCount: Int?
    var stubbedFailedCount: Int = 0
    var stubbedFailedItems: [SyncQueueItem] = []
    var retryItemCallCount = 0
    var discardItemCallCount = 0
    var retryAllCallCount = 0
    var discardAllCallCount = 0

    func enqueueUpload(runId: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        enqueuedUploads.append(runId)
    }

    func enqueueOperation(_ type: SyncOperationType, entityId: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        enqueuedOperations.append((type: type, entityId: entityId))
    }

    func processQueue() async {
        processQueueCallCount += 1
    }

    func getQueueStatus(forRunId runId: UUID) async -> SyncQueueItemStatus? {
        nil
    }

    func getPendingCount() async -> Int {
        stubbedPendingCount ?? (enqueuedOperations.count + enqueuedUploads.count)
    }

    func getFailedCount() async -> Int {
        stubbedFailedCount
    }

    func getFailedItems() async -> [SyncQueueItem] {
        stubbedFailedItems
    }

    func retryItem(id: UUID) async { retryItemCallCount += 1 }
    func discardItem(id: UUID) async { discardItemCallCount += 1 }
    func retryAllFailed() async { retryAllCallCount += 1 }
    func discardAllFailed() async { discardAllCallCount += 1 }
}
