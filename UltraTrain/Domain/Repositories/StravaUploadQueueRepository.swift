import Foundation

protocol StravaUploadQueueRepository: Sendable {
    func getPendingItems() async throws -> [StravaUploadQueueItem]
    func getItem(forRunId runId: UUID) async throws -> StravaUploadQueueItem?
    func saveItem(_ item: StravaUploadQueueItem) async throws
    func updateItem(_ item: StravaUploadQueueItem) async throws
    func deleteItem(id: UUID) async throws
    func getPendingCount() async throws -> Int
}
