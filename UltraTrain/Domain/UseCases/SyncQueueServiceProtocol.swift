import Foundation

protocol SyncQueueServiceProtocol: Sendable {
    func enqueueUpload(runId: UUID) async throws
    func enqueueOperation(_ type: SyncOperationType, entityId: UUID) async throws
    func processQueue() async
    func getQueueStatus(forRunId runId: UUID) async -> SyncQueueItemStatus?
    func getPendingCount() async -> Int
    func getFailedCount() async -> Int
    func getFailedItems() async -> [SyncQueueItem]
    func retryItem(id: UUID) async
    func discardItem(id: UUID) async
    func retryAllFailed() async
    func discardAllFailed() async
}
