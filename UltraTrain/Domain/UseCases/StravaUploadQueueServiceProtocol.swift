import Foundation

protocol StravaUploadQueueServiceProtocol: Sendable {
    func enqueueUpload(runId: UUID) async throws
    func processQueue() async
    func getQueueStatus(forRunId runId: UUID) async -> StravaQueueItemStatus?
    func getPendingCount() async -> Int
}
