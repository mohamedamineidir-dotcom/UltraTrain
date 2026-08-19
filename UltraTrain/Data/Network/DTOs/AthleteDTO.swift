import Foundation

struct AthleteDTO: Codable, Sendable {
    let id: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String
    let weightKg: Double
    let heightCm: Double
    let restingHeartRate: Int
    let maxHeartRate: Int
    let experienceLevel: String
    let weeklyVolumeKm: Double
    let longestRunKm: Double
    var itraIndex: Double?
    var itraIndexUpdatedAt: String?
    var previousItraIndex: Double?
    var previousItraIndexUpdatedAt: String?
    var utmbIndex: Double?
    var utmbIndexUpdatedAt: String?
    var previousUtmbIndex: Double?
    var previousUtmbIndexUpdatedAt: String?
}
