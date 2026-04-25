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
        raceType: RaceType = .trail,
        painFrequency: PainFrequency = .never,
        taperProfile: TaperProfile? = nil,
        athleteAge: Int = 0
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
                weekNumberInTaper: weekInTaper,
                athleteAge: athleteAge
            )

            if skeleton.phase == .taper {
                taperWeekCounter += 1
            }

            if !skeleton.isRecoveryWeek {
                previousNonRecoveryWeekTotal = durations.totalSeconds
            }

            // Derive km from duration using experience-based pace
            let avgPaceSecPerKm = AppConfiguration.Training.averagePaceSecPerKm[experience.rawValue] ?? 390
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
        // Post-process: enforce volume cap and week-1 anchoring
        let volumeCap = VolumeCapCalculator.weeklyVolumeCap(
            experience: experience,
            raceType: raceType,
            raceEffectiveKm: raceEffectiveKm,
            philosophy: philosophy,
            painFrequency: painFrequency
        )
        let week1Multiplier = VolumeCapCalculator.week1VolumeMultiplier(preferredRunsPerWeek: preferredRunsPerWeek)
        let week1Baseline = VolumeCapCalculator.week1MinimumBaseline(experience: experience)
        let currentVolumeSeconds = currentWeeklyVolumeKm * (AppConfiguration.Training.averagePaceSecPerKm[experience.rawValue] ?? 390)
        let week1MaxTotal = max(currentVolumeSeconds * week1Multiplier, week1Baseline)

        var capped = volumes
        for i in capped.indices {
            let skeleton = skeletons[i]
            let isRecovery = skeleton.isRecoveryWeek
            let isTaper = skeleton.phase == .taper

            // Week 1 anchoring: don't exceed dynamic multiplier of current volume
            if i == 0 && capped[i].targetDurationSeconds > week1MaxTotal {
                let ratio = week1MaxTotal / capped[i].targetDurationSeconds
                capped[i] = scaleVolume(capped[i], by: ratio)
            }

            // Volume cap: non-recovery, non-taper weeks
            if i > 0 && !isRecovery && !isTaper {
                let prevWasRecovery = skeletons[i - 1].isRecoveryWeek
                // After recovery week: compare against last non-recovery week (skip the dip)
                let referenceTotal: TimeInterval
                if prevWasRecovery, let lastNonRecIdx = (0..<i).reversed().first(where: { !skeletons[$0].isRecoveryWeek }) {
                    referenceTotal = capped[lastNonRecIdx].targetDurationSeconds
                } else {
                    referenceTotal = capped[i - 1].targetDurationSeconds
                }

                let maxAllowed = referenceTotal * (1.0 + volumeCap / 100.0)
                if capped[i].targetDurationSeconds > maxAllowed && referenceTotal > 0 {
                    let ratio = maxAllowed / capped[i].targetDurationSeconds
                    capped[i] = scaleVolume(capped[i], by: ratio)
                }
            }
        }

        return capped
    }

    private static func scaleVolume(_ volume: WeekVolume, by ratio: Double) -> WeekVolume {
        WeekVolume(
            weekNumber: volume.weekNumber,
            targetVolumeKm: (volume.targetVolumeKm * ratio * 10).rounded() / 10,
            targetElevationGainM: volume.targetElevationGainM * ratio,
            targetDurationSeconds: volume.targetDurationSeconds * ratio,
            targetLongRunDurationSeconds: volume.targetLongRunDurationSeconds * ratio,
            isB2BWeek: volume.isB2BWeek,
            b2bDay1Seconds: volume.b2bDay1Seconds * ratio,
            b2bDay2Seconds: volume.b2bDay2Seconds * ratio,
            baseSessionDurations: BaseSessionDurations(
                easyRun1Seconds: volume.baseSessionDurations.easyRun1Seconds * ratio,
                easyRun2Seconds: volume.baseSessionDurations.easyRun2Seconds * ratio,
                intervalSeconds: volume.baseSessionDurations.intervalSeconds * ratio,
                vgSeconds: volume.baseSessionDurations.vgSeconds * ratio
            ),
            weekNumberInTaper: volume.weekNumberInTaper,
            taperProfile: volume.taperProfile
        )
    }

    private static func elevationForVolume(
        _ volume: Double,
        raceDistanceKm: Double,
        raceElevationGainM: Double,
        planProgress: Double
    ) -> Double {
        guard raceDistanceKm > 0 else { return 0 }
        let raceElevationPerKm = raceElevationGainM / raceDistanceKm
        // Cap training density at 75 m/km (was 60). The previous cap meant
        // any race above 60 m/km was trained at LESS density than the race
        // itself — wrong for vertical races (Hardrock, Madeira Sky Race,
        // Sky Skouts where race density runs 80-100+ m/km). New cap lets
        // training match races up to 75 m/km and stay close for steeper
        // ones, while still preventing pathological values for short
        // races like a 13 km / 1500 D+ vert kilometre.
        let trainingElevationPerKm = min(raceElevationPerKm, 75.0)
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
