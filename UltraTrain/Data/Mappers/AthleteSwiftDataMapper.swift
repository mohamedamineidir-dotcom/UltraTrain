import Foundation

enum AthleteSwiftDataMapper {
    static func toDomain(_ model: AthleteSwiftDataModel) -> Athlete? {
        guard let level = ExperienceLevel(rawValue: model.experienceLevelRaw),
              let unit = UnitPreference(rawValue: model.preferredUnitRaw) else {
            return nil
        }
        return Athlete(
            id: model.id,
            firstName: model.firstName,
            lastName: model.lastName,
            dateOfBirth: model.dateOfBirth,
            weightKg: model.weightKg,
            heightCm: model.heightCm,
            restingHeartRate: model.restingHeartRate,
            maxHeartRate: model.maxHeartRate,
            experienceLevel: level,
            weeklyVolumeKm: model.weeklyVolumeKm,
            longestRunKm: model.longestRunKm,
            preferredUnit: unit
        )
    }

    static func toSwiftData(_ athlete: Athlete) -> AthleteSwiftDataModel {
        AthleteSwiftDataModel(
            id: athlete.id,
            firstName: athlete.firstName,
            lastName: athlete.lastName,
            dateOfBirth: athlete.dateOfBirth,
            weightKg: athlete.weightKg,
            heightCm: athlete.heightCm,
            restingHeartRate: athlete.restingHeartRate,
            maxHeartRate: athlete.maxHeartRate,
            experienceLevelRaw: athlete.experienceLevel.rawValue,
            weeklyVolumeKm: athlete.weeklyVolumeKm,
            longestRunKm: athlete.longestRunKm,
            preferredUnitRaw: athlete.preferredUnit.rawValue
        )
    }
}
