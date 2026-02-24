import Foundation

enum SyncQueueItemStatus: String, Sendable, Equatable {
    case pending
    case uploading
    case failed
    case completed
}

enum SyncOperationType: String, Sendable, Equatable {
    case runUpload
    case athleteSync
    case raceSync
    case raceDelete
    case trainingPlanSync
    case socialProfileSync
    case activityPublish
    case shareRevoke
}

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
