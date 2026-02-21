import Foundation

enum ActivityType: String, Sendable, CaseIterable {
    case completedRun
    case personalRecord
    case challengeCompleted
    case raceFinished
    case weeklyGoalMet
    case friendJoined
}

struct ActivityFeedItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var athleteProfileId: String
    var athleteDisplayName: String
    var athletePhotoData: Data?
    var activityType: ActivityType
    var title: String
    var subtitle: String?
    var stats: ActivityStats?
    var timestamp: Date
    var likeCount: Int
    var isLikedByMe: Bool
}

struct ActivityStats: Equatable, Sendable {
    var distanceKm: Double?
    var elevationGainM: Double?
    var duration: TimeInterval?
    var averagePace: Double?
}
