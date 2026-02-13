import Foundation

enum AthleteMapper {
    static func toDomain(_ dto: AthleteDTO) -> Athlete? {
        guard let id = UUID(uuidString: dto.id),
              let level = ExperienceLevel(rawValue: dto.experienceLevel) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        guard let dob = formatter.date(from: dto.dateOfBirth) else {
            return nil
        }

        return Athlete(
            id: id,
            firstName: dto.firstName,
            lastName: dto.lastName,
            dateOfBirth: dob,
            weightKg: dto.weightKg,
            heightCm: dto.heightCm,
            restingHeartRate: dto.restingHeartRate,
            maxHeartRate: dto.maxHeartRate,
            experienceLevel: level,
            weeklyVolumeKm: dto.weeklyVolumeKm,
            longestRunKm: dto.longestRunKm,
            preferredUnit: .metric
        )
    }

    static func toDTO(_ athlete: Athlete) -> AthleteDTO {
        let formatter = ISO8601DateFormatter()
        return AthleteDTO(
            id: athlete.id.uuidString,
            firstName: athlete.firstName,
            lastName: athlete.lastName,
            dateOfBirth: formatter.string(from: athlete.dateOfBirth),
            weightKg: athlete.weightKg,
            heightCm: athlete.heightCm,
            restingHeartRate: athlete.restingHeartRate,
            maxHeartRate: athlete.maxHeartRate,
            experienceLevel: athlete.experienceLevel.rawValue,
            weeklyVolumeKm: athlete.weeklyVolumeKm,
            longestRunKm: athlete.longestRunKm
        )
    }
}
