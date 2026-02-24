import Foundation
import os

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

        guard InputValidator.isValidWeight(dto.weightKg) else {
            Logger.validation.warning("AthleteMapper: invalid weight \(dto.weightKg)")
            return nil
        }
        guard InputValidator.isValidHeight(dto.heightCm) else {
            Logger.validation.warning("AthleteMapper: invalid height \(dto.heightCm)")
            return nil
        }

        if !InputValidator.isValidHeartRate(dto.restingHeartRate) {
            Logger.validation.warning("AthleteMapper: invalid restingHR \(dto.restingHeartRate)")
        }
        if !InputValidator.isValidHeartRate(dto.maxHeartRate) {
            Logger.validation.warning("AthleteMapper: invalid maxHR \(dto.maxHeartRate)")
        }
        if dto.maxHeartRate <= dto.restingHeartRate {
            Logger.validation.warning("AthleteMapper: maxHR (\(dto.maxHeartRate)) <= restingHR (\(dto.restingHeartRate))")
        }

        return Athlete(
            id: id,
            firstName: InputValidator.sanitizeName(dto.firstName),
            lastName: InputValidator.sanitizeName(dto.lastName),
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
