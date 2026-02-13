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
}
