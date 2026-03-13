import Foundation

enum VolumeCalculator {

    struct BaseSessionDurations: Equatable, Sendable {
        let easyRun1Seconds: TimeInterval
        let easyRun2Seconds: TimeInterval
        let intervalSeconds: TimeInterval
        let vgSeconds: TimeInterval
    }

    struct WeekVolume: Equatable, Sendable {
        let weekNumber: Int
        let targetVolumeKm: Double
        let targetElevationGainM: Double
        let targetDurationSeconds: TimeInterval
        let targetLongRunDurationSeconds: TimeInterval
        let isB2BWeek: Bool
        let b2bDay1Seconds: TimeInterval
        let b2bDay2Seconds: TimeInterval
        let baseSessionDurations: BaseSessionDurations
    }

    static func calculate(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        currentWeeklyVolumeKm: Double,
        raceDistanceKm: Double,
        raceElevationGainM: Double,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy = .balanced,
        raceDurationSeconds: TimeInterval = 0,
        raceEffectiveKm: Double = 0,
        preferredRunsPerWeek: Int = 5,
        maxIncreasePercent: Double = AppConfiguration.Training.maxWeeklyVolumeIncreasePercent,
        recoveryReductionPercent: Double = AppConfiguration.Training.recoveryWeekVolumeReductionPercent
    ) -> [WeekVolume] {
        guard !skeletons.isEmpty else { return [] }

        let totalWeeks = skeletons.count

        // Compute duration-based volumes via LongRunCurveCalculator
        var volumes: [WeekVolume] = []

        for (index, skeleton) in skeletons.enumerated() {
            let durations = LongRunCurveCalculator.durations(
                weekIndex: index,
                totalWeeks: totalWeeks,
                phase: skeleton.phase,
                isRecoveryWeek: skeleton.isRecoveryWeek,
                experience: experience,
                philosophy: philosophy,
                raceDurationSeconds: raceDurationSeconds,
                raceEffectiveKm: raceEffectiveKm,
                preferredRunsPerWeek: preferredRunsPerWeek
            )

            // Derive km from duration using average pace (~6.5 min/km)
            let avgPaceSecPerKm: Double = 390 // 6.5 min/km
            let derivedKm = durations.totalSeconds / avgPaceSecPerKm

            // Elevation: proportional to derived km with race elevation density
            let elevation = elevationForVolume(
                derivedKm,
                raceDistanceKm: raceDistanceKm,
                raceElevationGainM: raceElevationGainM
            )

            volumes.append(WeekVolume(
                weekNumber: skeleton.weekNumber,
                targetVolumeKm: (derivedKm * 10).rounded() / 10,
                targetElevationGainM: (elevation * 10).rounded() / 10,
                targetDurationSeconds: durations.totalSeconds,
                targetLongRunDurationSeconds: durations.longRunSeconds,
                isB2BWeek: durations.isB2B,
                b2bDay1Seconds: durations.b2bDay1Seconds,
                b2bDay2Seconds: durations.b2bDay2Seconds,
                baseSessionDurations: BaseSessionDurations(
                    easyRun1Seconds: durations.easyRun1Seconds,
                    easyRun2Seconds: durations.easyRun2Seconds,
                    intervalSeconds: durations.intervalSeconds,
                    vgSeconds: durations.vgSeconds
                )
            ))
        }
        return volumes
    }

    private static func elevationForVolume(_ volume: Double, raceDistanceKm: Double, raceElevationGainM: Double) -> Double {
        guard raceDistanceKm > 0 else { return 0 }
        let raceElevationPerKm = raceElevationGainM / raceDistanceKm
        // Cap training elevation density at 60 m/km to prevent extreme values
        // for short, steep races (e.g., 13km/1500D+ = 115 m/km)
        let trainingElevationPerKm = min(raceElevationPerKm, 60.0)
        return volume * trainingElevationPerKm
    }
}
