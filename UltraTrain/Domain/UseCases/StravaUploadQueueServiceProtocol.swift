import Foundation

protocol StravaUploadQueueServiceProtocol: Sendable {
    func enqueueUpload(runId: UUID) async throws
    func processQueue() async
    func getQueueStatus(forRunId runId: UUID) async -> StravaQueueItemStatus?
    func getUploadedActivityId(forRunId runId: UUID) async -> Int?
    func getPendingCount() async -> Int
}
