import Foundation

enum AthleteSwiftDataMapper {
    static func toDomain(_ model: AthleteSwiftDataModel) -> Athlete? {
        guard let level = ExperienceLevel(rawValue: model.experienceLevelRaw),
              let unit = UnitPreference(rawValue: model.preferredUnitRaw) else {
            return nil
        }
        let customZones: [Int]? = model.customZoneThresholdsRaw.flatMap { raw in
            let parts = raw.split(separator: ",").compactMap { Int($0) }
            return parts.count == 4 ? parts : nil
        }
        let personalBests: [PersonalBest] = model.personalBestsRaw.flatMap { raw in
            guard let data = raw.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode([PersonalBest].self, from: data)
        } ?? []
        let trailPersonalBests: [TrailPersonalBest] = model.trailPersonalBestsRaw.flatMap { raw in
            guard let data = raw.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode([TrailPersonalBest].self, from: data)
        } ?? []
        let philosophy = TrainingPhilosophy(rawValue: model.trainingPhilosophyRaw) ?? .balanced
        let weightGoal = WeightGoal(rawValue: model.weightGoalRaw) ?? .maintain
        let biologicalSex = BiologicalSex(rawValue: model.biologicalSexRaw) ?? .male
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
            preferredUnit: unit,
            customZoneThresholds: customZones,
            personalBests: personalBests,
            trailPersonalBests: trailPersonalBests,
            trainingPhilosophy: philosophy,
            preferredRunsPerWeek: model.preferredRunsPerWeek ?? 5,
            displayName: model.displayName,
            bio: model.bio,
            profilePhotoData: model.profilePhotoData,
            isPublicProfile: model.isPublicProfile,
            weightGoal: weightGoal,
            biologicalSex: biologicalSex,
            verticalGainEnvironment: VerticalGainEnvironment(rawValue: model.verticalGainEnvironmentRaw) ?? .mountain,
            painFrequency: PainFrequency(rawValue: model.painFrequencyRaw) ?? .never,
            injuryCountLastYear: InjuryCount(rawValue: model.injuryCountLastYearRaw) ?? .none,
            hasRecentInjury: model.hasRecentInjury,
            strengthTrainingPreference: StrengthTrainingPreference(rawValue: model.strengthTrainingPreferenceRaw) ?? .no,
            strengthTrainingLocation: StrengthTrainingLocation(rawValue: model.strengthTrainingLocationRaw) ?? .home,
            runningTerrain: TerrainType(rawValue: model.runningTerrainRaw) ?? .trail,
            uphillDuration: model.uphillDurationRaw.flatMap { UphillDuration(rawValue: $0) },
            treadmillMaxIncline: model.treadmillMaxInclineRaw.flatMap { TreadmillIncline(rawValue: $0) },
            intervalFocus: IntervalFocus(rawValue: model.intervalFocusRaw) ?? .mixed,
            vo2max: model.vo2max,
            vmaKmh: model.vmaKmh,
            thresholdPace60MinPerKm: model.thresholdPace60MinPerKm,
            thresholdPace30MinPerKm: model.thresholdPace30MinPerKm
        )
    }

    static func toSwiftData(_ athlete: Athlete) -> AthleteSwiftDataModel {
        let pbRaw: String? = athlete.personalBests.isEmpty ? nil : {
            guard let data = try? JSONEncoder().encode(athlete.personalBests) else { return nil }
            return String(data: data, encoding: .utf8)
        }()
        let trailPbRaw: String? = athlete.trailPersonalBests.isEmpty ? nil : {
            guard let data = try? JSONEncoder().encode(athlete.trailPersonalBests) else { return nil }
            return String(data: data, encoding: .utf8)
        }()
        return AthleteSwiftDataModel(
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
            preferredUnitRaw: athlete.preferredUnit.rawValue,
            customZoneThresholdsRaw: athlete.customZoneThresholds?.map(String.init).joined(separator: ","),
            personalBestsRaw: pbRaw,
            trainingPhilosophyRaw: athlete.trainingPhilosophy.rawValue,
            preferredRunsPerWeek: athlete.preferredRunsPerWeek,
            displayName: athlete.displayName,
            bio: athlete.bio,
            profilePhotoData: athlete.profilePhotoData,
            isPublicProfile: athlete.isPublicProfile,
            weightGoalRaw: athlete.weightGoal.rawValue,
            biologicalSexRaw: athlete.biologicalSex.rawValue,
            vo2max: athlete.vo2max,
            vmaKmh: athlete.vmaKmh,
            thresholdPace60MinPerKm: athlete.thresholdPace60MinPerKm,
            thresholdPace30MinPerKm: athlete.thresholdPace30MinPerKm,
            verticalGainEnvironmentRaw: athlete.verticalGainEnvironment.rawValue,
            painFrequencyRaw: athlete.painFrequency.rawValue,
            injuryCountLastYearRaw: athlete.injuryCountLastYear.rawValue,
            hasRecentInjury: athlete.hasRecentInjury,
            strengthTrainingPreferenceRaw: athlete.strengthTrainingPreference.rawValue,
            strengthTrainingLocationRaw: athlete.strengthTrainingLocation.rawValue,
            runningTerrainRaw: athlete.runningTerrain.rawValue,
            uphillDurationRaw: athlete.uphillDuration?.rawValue,
            treadmillMaxInclineRaw: athlete.treadmillMaxIncline?.rawValue,
            trailPersonalBestsRaw: trailPbRaw,
            intervalFocusRaw: athlete.intervalFocus.rawValue
        )
    }
}
