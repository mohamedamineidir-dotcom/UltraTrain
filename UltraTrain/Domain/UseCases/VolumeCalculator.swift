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
        let weekNumberInTaper: Int
        let taperProfile: TaperProfile?
    }

    static func calculate(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        currentWeeklyVolumeKm: Double,
        raceDistanceKm: Double,
        raceElevationGainM: Double,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy = .balanced,
        raceGoal: RaceGoal = .finish,
        raceDurationSeconds: TimeInterval = 0,
        raceEffectiveKm: Double = 0,
        preferredRunsPerWeek: Int = 5,
        maxIncreasePercent: Double = AppConfiguration.Training.maxWeeklyVolumeIncreasePercent,
        recoveryReductionPercent: Double = AppConfiguration.Training.recoveryWeekVolumeReductionPercent,
        taperProfile: TaperProfile? = nil
    ) -> [WeekVolume] {
        guard !skeletons.isEmpty else { return [] }

        let totalWeeks = skeletons.count

        // Compute duration-based volumes via LongRunCurveCalculator
        var volumes: [WeekVolume] = []
        var previousNonRecoveryWeekTotal: TimeInterval = 0
        var taperWeekCounter = 0

        for (index, skeleton) in skeletons.enumerated() {
            let weekInTaper = skeleton.phase == .taper ? taperWeekCounter : 0

            let durations = LongRunCurveCalculator.durations(
                weekIndex: index,
                totalWeeks: totalWeeks,
                phase: skeleton.phase,
                isRecoveryWeek: skeleton.isRecoveryWeek,
                experience: experience,
                philosophy: philosophy,
                raceGoal: raceGoal,
                raceDurationSeconds: raceDurationSeconds,
                raceEffectiveKm: raceEffectiveKm,
                preferredRunsPerWeek: preferredRunsPerWeek,
                currentWeeklyVolumeKm: currentWeeklyVolumeKm,
                previousNonRecoveryWeekTotal: previousNonRecoveryWeekTotal,
                taperProfile: taperProfile,
                weekNumberInTaper: weekInTaper
            )

            if skeleton.phase == .taper {
                taperWeekCounter += 1
            }

            if !skeleton.isRecoveryWeek {
                previousNonRecoveryWeekTotal = durations.totalSeconds
            }

            // Derive km from duration using average pace (~6.5 min/km)
            let avgPaceSecPerKm: Double = 390 // 6.5 min/km
            let derivedKm = durations.totalSeconds / avgPaceSecPerKm

            // Elevation: proportional to derived km with race elevation density
            // Progressive ramp prevents excessive D+ in early low-volume weeks
            let planProgress = totalWeeks > 1
                ? Double(index) / Double(totalWeeks - 1) : 1.0
            let elevation = elevationForVolume(
                derivedKm,
                raceDistanceKm: raceDistanceKm,
                raceElevationGainM: raceElevationGainM,
                planProgress: planProgress
            )

            volumes.append(WeekVolume(
                weekNumber: skeleton.weekNumber,
                targetVolumeKm: (derivedKm * 10).rounded() / 10,
                targetElevationGainM: elevation,
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
                ),
                weekNumberInTaper: weekInTaper,
                taperProfile: taperProfile
            ))
        }
        return volumes
    }

    private static func elevationForVolume(
        _ volume: Double,
        raceDistanceKm: Double,
        raceElevationGainM: Double,
        planProgress: Double
    ) -> Double {
        guard raceDistanceKm > 0 else { return 0 }
        let raceElevationPerKm = raceElevationGainM / raceDistanceKm
        // Cap training elevation density at 60 m/km to prevent extreme values
        // for short, steep races (e.g., 13km/1500D+ = 115 m/km)
        let trainingElevationPerKm = min(raceElevationPerKm, 60.0)
        // Progressive ramp: 15% density at plan start → 70% at peak
        // Keeps D+ manageable through build/peak phases
        let progressFactor = 0.15 + 0.55 * planProgress
        let raw = volume * trainingElevationPerKm * progressFactor
        return roundToNearest5(raw)
    }

    /// Rounds a value to the nearest 5 (e.g., 1003→1005, 1101→1100).
    private static func roundToNearest5(_ value: Double) -> Double {
        (value / 5.0).rounded() * 5.0
    }
}
