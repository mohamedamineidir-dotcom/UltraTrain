import Foundation
import SwiftData

@Model
final class AthleteSwiftDataModel {
    var id: UUID = UUID()
    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: Date = Date.distantPast
    var weightKg: Double = 0
    var heightCm: Double = 0
    var restingHeartRate: Int = 60
    var maxHeartRate: Int = 180
    var experienceLevelRaw: String = "beginner"
    var weeklyVolumeKm: Double = 0
    var longestRunKm: Double = 0
    var preferredUnitRaw: String = "metric"
    var customZoneThresholdsRaw: String? = nil
    var updatedAt: Date = Date()
    var displayName: String? = nil
    var bio: String? = nil
    @Attribute(.externalStorage) var profilePhotoData: Data? = nil
    var isPublicProfile: Bool = false

    init(
        id: UUID = UUID(),
        firstName: String = "",
        lastName: String = "",
        dateOfBirth: Date = Date.distantPast,
        weightKg: Double = 0,
        heightCm: Double = 0,
        restingHeartRate: Int = 60,
        maxHeartRate: Int = 180,
        experienceLevelRaw: String = "beginner",
        weeklyVolumeKm: Double = 0,
        longestRunKm: Double = 0,
        preferredUnitRaw: String = "metric",
        customZoneThresholdsRaw: String? = nil,
        updatedAt: Date = Date(),
        displayName: String? = nil,
        bio: String? = nil,
        profilePhotoData: Data? = nil,
        isPublicProfile: Bool = false
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.restingHeartRate = restingHeartRate
        self.maxHeartRate = maxHeartRate
        self.experienceLevelRaw = experienceLevelRaw
        self.weeklyVolumeKm = weeklyVolumeKm
        self.longestRunKm = longestRunKm
        self.preferredUnitRaw = preferredUnitRaw
        self.customZoneThresholdsRaw = customZoneThresholdsRaw
        self.updatedAt = updatedAt
        self.displayName = displayName
        self.bio = bio
        self.profilePhotoData = profilePhotoData
        self.isPublicProfile = isPublicProfile
    }
}
