import Foundation
import SwiftData

@Model
final class AthleteSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var weightKg: Double
    var heightCm: Double
    var restingHeartRate: Int
    var maxHeartRate: Int
    var experienceLevelRaw: String
    var weeklyVolumeKm: Double
    var longestRunKm: Double
    var preferredUnitRaw: String

    init(
        id: UUID,
        firstName: String,
        lastName: String,
        dateOfBirth: Date,
        weightKg: Double,
        heightCm: Double,
        restingHeartRate: Int,
        maxHeartRate: Int,
        experienceLevelRaw: String,
        weeklyVolumeKm: Double,
        longestRunKm: Double,
        preferredUnitRaw: String
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
    }
}
