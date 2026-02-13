import Foundation

struct Athlete: Identifiable, Equatable, Sendable {
    let id: UUID
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var weightKg: Double
    var heightCm: Double
    var restingHeartRate: Int
    var maxHeartRate: Int
    var experienceLevel: ExperienceLevel
    var weeklyVolumeKm: Double
    var longestRunKm: Double
    var preferredUnit: UnitPreference

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 0
    }
}

enum ExperienceLevel: String, CaseIterable, Sendable {
    case beginner
    case intermediate
    case advanced
    case elite
}

enum UnitPreference: String, CaseIterable, Sendable {
    case metric
    case imperial
}
