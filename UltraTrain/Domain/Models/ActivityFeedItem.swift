import Foundation

struct ActivityFeedItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var athleteProfileId: String
    var athleteDisplayName: String
    var athletePhotoData: Data?
    var activityType: FeedActivityType
    var title: String
    var subtitle: String?
    var stats: ActivityStats?
    var timestamp: Date
    var likeCount: Int
    var isLikedByMe: Bool
}
