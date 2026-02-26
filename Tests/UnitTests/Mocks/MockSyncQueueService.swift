import Foundation
@testable import UltraTrain

final class MockSyncQueueService: SyncQueueServiceProtocol, @unchecked Sendable {
    var enqueuedUploads: [UUID] = []
    var enqueuedOperations: [(type: SyncOperationType, entityId: UUID)] = []
    var processQueueCallCount = 0
    var shouldThrow = false

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
        enqueuedOperations.count + enqueuedUploads.count
    }

    func getFailedCount() async -> Int {
        0
    }

    func getFailedItems() async -> [SyncQueueItem] {
        []
    }

    func retryItem(id: UUID) async {}
    func discardItem(id: UUID) async {}
    func retryAllFailed() async {}
    func discardAllFailed() async {}
}
