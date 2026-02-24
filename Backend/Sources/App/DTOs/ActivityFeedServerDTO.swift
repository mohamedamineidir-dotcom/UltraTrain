import Vapor

struct PublishActivityRequest: Content, Validatable {
    let activityType: String
    let title: String
    let subtitle: String?
    let distanceKm: Double?
    let elevationGainM: Double?
    let duration: Double?
    let averagePace: Double?
    let timestamp: String
    let idempotencyKey: String

    static func validations(_ validations: inout Validations) {
        validations.add("activityType", as: String.self, is: .in(
            "completedRun", "personalRecord", "challengeCompleted",
            "raceFinished", "weeklyGoalMet", "friendJoined"
        ))
        validations.add("title", as: String.self, is: !.empty)
        validations.add("idempotencyKey", as: String.self, is: !.empty)
    }
}

struct ActivityFeedItemResponse: Content {
    let id: String
    let athleteProfileId: String
    let athleteDisplayName: String
    let activityType: String
    let title: String
    let subtitle: String?
    let distanceKm: Double?
    let elevationGainM: Double?
    let duration: Double?
    let averagePace: Double?
    let timestamp: String
    let likeCount: Int
    let isLikedByMe: Bool
}

struct LikeResponse: Content {
    let liked: Bool
    let likeCount: Int
}

struct ActivityStatsJSON: Codable {
    let distanceKm: Double?
    let elevationGainM: Double?
    let duration: Double?
    let averagePace: Double?
}
