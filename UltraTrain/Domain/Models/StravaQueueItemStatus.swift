import Foundation

enum StravaQueueItemStatus: String, Sendable, Equatable {
    case pending
    case uploading
    case failed
    case completed
}
