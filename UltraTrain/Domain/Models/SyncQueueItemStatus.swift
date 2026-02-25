import Foundation

enum SyncQueueItemStatus: String, Sendable, Equatable {
    case pending
    case uploading
    case failed
    case completed
}
