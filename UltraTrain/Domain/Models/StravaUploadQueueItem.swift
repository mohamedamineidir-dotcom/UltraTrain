import Foundation

enum StravaQueueItemStatus: String, Sendable, Equatable {
    case pending
    case uploading
    case failed
    case completed
}

struct StravaUploadQueueItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var runId: UUID
    var status: StravaQueueItemStatus
    var retryCount: Int
    var lastAttempt: Date?
    var stravaActivityId: Int?
    var errorMessage: String?
    var createdAt: Date

    var hasReachedMaxRetries: Bool {
        retryCount >= 3
    }

    var nextRetryDelay: TimeInterval {
        [5, 30, 120][min(retryCount, 2)]
    }
}
