import Foundation
@testable import UltraTrain

final class MockStravaUploadQueueService: StravaUploadQueueServiceProtocol, @unchecked Sendable {
    var enqueuedRunIds: [UUID] = []
    var processQueueCalled = false
    var shouldThrow = false
    var queueStatuses: [UUID: StravaQueueItemStatus] = [:]
    var pendingCount = 0

    func enqueueUpload(runId: UUID) async throws {
        if shouldThrow { throw DomainError.stravaUploadFailed(reason: "Mock error") }
        enqueuedRunIds.append(runId)
    }

    func processQueue() async {
        processQueueCalled = true
    }

    func getQueueStatus(forRunId runId: UUID) async -> StravaQueueItemStatus? {
        queueStatuses[runId]
    }

    func getPendingCount() async -> Int {
        pendingCount
    }
}
