import Foundation

protocol SyncQueueRepository: Sendable {
    func getPendingItems() async throws -> [SyncQueueItem]
    func getItem(forRunId runId: UUID) async throws -> SyncQueueItem?
    func saveItem(_ item: SyncQueueItem) async throws
    func updateItem(_ item: SyncQueueItem) async throws
    func deleteItem(id: UUID) async throws
    func getPendingCount() async throws -> Int
    func getFailedCount() async throws -> Int
}
