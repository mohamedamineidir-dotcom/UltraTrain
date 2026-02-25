import Foundation

struct SyncQueueItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var runId: UUID
    var operationType: SyncOperationType
    var entityId: UUID
    var status: SyncQueueItemStatus
    var retryCount: Int
    var lastAttempt: Date?
    var errorMessage: String?
    var createdAt: Date

    var hasReachedMaxRetries: Bool {
        retryCount >= 5
    }

    var nextRetryDelay: TimeInterval {
        [10, 60, 300, 900, 1800][min(retryCount, 4)]
    }
}
