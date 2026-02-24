import Foundation

struct PublishActivityRequestDTO: Encodable, Sendable {
    let activityType: String
    let title: String
    let subtitle: String?
    let distanceKm: Double?
    let elevationGainM: Double?
    let duration: Double?
    let averagePace: Double?
    let timestamp: String
    let idempotencyKey: String
}

struct ActivityFeedItemResponseDTO: Decodable, Sendable {
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

struct LikeResponseDTO: Decodable, Sendable {
    let liked: Bool
    let likeCount: Int
}
