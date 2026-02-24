import Foundation

struct SocialProfileUpdateRequestDTO: Encodable, Sendable {
    let displayName: String
    let bio: String?
    let isPublicProfile: Bool
}

struct SocialProfileResponseDTO: Decodable, Sendable {
    let id: String
    let displayName: String
    let bio: String?
    let experienceLevel: String
    let isPublicProfile: Bool
    let totalDistanceKm: Double
    let totalElevationGainM: Double
    let totalRuns: Int
    let joinedDate: String
}
