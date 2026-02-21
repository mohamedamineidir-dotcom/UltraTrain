import Foundation

struct SocialProfile: Identifiable, Equatable, Sendable {
    let id: String
    var displayName: String
    var bio: String?
    var profilePhotoData: Data?
    var experienceLevel: ExperienceLevel
    var totalDistanceKm: Double
    var totalElevationGainM: Double
    var totalRuns: Int
    var joinedDate: Date
    var isPublicProfile: Bool
}
