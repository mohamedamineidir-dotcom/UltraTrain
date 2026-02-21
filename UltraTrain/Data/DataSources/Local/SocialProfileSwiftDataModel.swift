import Foundation
import SwiftData

@Model
final class SocialProfileSwiftDataModel {
    var id: String = ""
    var displayName: String = ""
    var bio: String?
    @Attribute(.externalStorage) var profilePhotoData: Data?
    var experienceLevelRaw: String = "beginner"
    var totalDistanceKm: Double = 0
    var totalElevationGainM: Double = 0
    var totalRuns: Int = 0
    var joinedDate: Date = Date()
    var isPublicProfile: Bool = false

    init(
        id: String = "",
        displayName: String = "",
        bio: String? = nil,
        profilePhotoData: Data? = nil,
        experienceLevelRaw: String = "beginner",
        totalDistanceKm: Double = 0,
        totalElevationGainM: Double = 0,
        totalRuns: Int = 0,
        joinedDate: Date = Date(),
        isPublicProfile: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.bio = bio
        self.profilePhotoData = profilePhotoData
        self.experienceLevelRaw = experienceLevelRaw
        self.totalDistanceKm = totalDistanceKm
        self.totalElevationGainM = totalElevationGainM
        self.totalRuns = totalRuns
        self.joinedDate = joinedDate
        self.isPublicProfile = isPublicProfile
    }
}
