import Foundation

protocol SyncQueueServiceProtocol: Sendable {
    func enqueueUpload(runId: UUID) async throws
    func enqueueOperation(_ type: SyncOperationType, entityId: UUID) async throws
    func processQueue() async
    func getQueueStatus(forRunId runId: UUID) async -> SyncQueueItemStatus?
    func getPendingCount() async -> Int
    func getFailedCount() async -> Int
}
