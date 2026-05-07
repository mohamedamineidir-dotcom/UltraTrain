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
        athleteAge: Int = 0,
        personalization: PersonalizationProfile? = nil
    ) -> [WeekVolume] {
        guard !skeletons.isEmpty else { return [] }

        let totalWeeks = skeletons.count

        // Pick the effective baseline. When PersonalizationProfile has
        // a recentPeak that diverges significantly from the snapshot,
        // we use the demonstrated peak instead — better matches actual
        // current capacity for returning users than a stale onboarding
        // number. Falls through to snapshot when no recent peak data.
        let effectiveCurrentVolumeKm = personalization?
            .effectiveWeeklyVolumeKm(snapshotKm: currentWeeklyVolumeKm)
            ?? currentWeeklyVolumeKm

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
                currentWeeklyVolumeKm: effectiveCurrentVolumeKm,
                previousNonRecoveryWeekTotal: previousNonRecoveryWeekTotal,
                taperProfile: taperProfile,
                weekNumberInTaper: weekInTaper,
                athleteAge: athleteAge,
                personalization: personalization
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
                planProgress: planProgress,
                vgDensityMultiplier: personalization?.vgDensityMultiplier ?? 1.0
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
            painFrequency: painFrequency,
            personalization: personalization
        )
        let week1Multiplier = VolumeCapCalculator.week1VolumeMultiplier(preferredRunsPerWeek: preferredRunsPerWeek)
        let week1Baseline = VolumeCapCalculator.week1MinimumBaseline(experience: experience)
        // Week-1 anchor uses the EFFECTIVE baseline so a returning
        // user with demonstrated higher capacity gets a more
        // appropriate first-week ramp than the stale snapshot would
        // allow. Snapshot still wins when no peak data exists.
        let currentVolumeSeconds = effectiveCurrentVolumeKm * (AppConfiguration.Training.averagePaceSecPerKm[experience.rawValue] ?? 390)
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

        // Round endurance sessions (Long Run, Base Endurance / easy runs,
        // back-to-back long runs) to the nearest 5 minutes — feedback from
        // athlete trial: "31 min" / "47 min" durations on aerobic runs feel
        // arbitrary. Quality work (intervals, vertical-gain) keeps minute-
        // level precision because the prescription itself is structural
        // (e.g. 4×8 min at threshold + warm-up/cool-down) — rounding those
        // would distort the workout. Applied AFTER all scaling so rounded
        // values are what the athlete actually sees.
        for i in capped.indices {
            capped[i] = roundEnduranceSessions(capped[i])
        }

        return capped
    }

    /// Rounds Long Run, easy runs, and B2B day durations to nearest 5 min.
    /// Recomputes `targetDurationSeconds` as the sum of all sessions so the
    /// week total stays consistent with the rounded session breakdown.
    private static func roundEnduranceSessions(_ volume: WeekVolume) -> WeekVolume {
        let lr = roundToNearest5Min(volume.targetLongRunDurationSeconds)
        let e1 = roundToNearest5Min(volume.baseSessionDurations.easyRun1Seconds)
        let e2 = roundToNearest5Min(volume.baseSessionDurations.easyRun2Seconds)
        let b1 = roundToNearest5Min(volume.b2bDay1Seconds)
        let b2 = roundToNearest5Min(volume.b2bDay2Seconds)
        let intervals = volume.baseSessionDurations.intervalSeconds
        let vg = volume.baseSessionDurations.vgSeconds

        // Rebuild week total from the rounded parts. For a B2B week the
        // long-run slot is split across two days, so b2bDay1+b2bDay2
        // replaces targetLongRun in the sum.
        let lrContribution = volume.isB2BWeek ? (b1 + b2) : lr
        let newTotal = e1 + e2 + intervals + vg + lrContribution

        // Keep targetLongRunDurationSeconds consistent with the B2B day
        // split. Without this, `lr` and `b1+b2` can drift up to 5 min
        // apart because each is independently rounded — that breaks any
        // downstream consumer that asserts `b2bDay1 + b2bDay2 ==
        // targetLongRun`. For non-B2B weeks the rounded LR is the truth.
        let displayedLongRun = volume.isB2BWeek ? (b1 + b2) : lr

        return WeekVolume(
            weekNumber: volume.weekNumber,
            targetVolumeKm: volume.targetVolumeKm,
            targetElevationGainM: volume.targetElevationGainM,
            targetDurationSeconds: newTotal,
            targetLongRunDurationSeconds: displayedLongRun,
            isB2BWeek: volume.isB2BWeek,
            b2bDay1Seconds: b1,
            b2bDay2Seconds: b2,
            baseSessionDurations: BaseSessionDurations(
                easyRun1Seconds: e1,
                easyRun2Seconds: e2,
                intervalSeconds: intervals,
                vgSeconds: vg
            ),
            weekNumberInTaper: volume.weekNumberInTaper,
            taperProfile: volume.taperProfile
        )
    }

    private static func roundToNearest5Min(_ seconds: TimeInterval) -> TimeInterval {
        guard seconds > 0 else { return 0 }
        return (seconds / 300.0).rounded() * 300.0
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
        planProgress: Double,
        vgDensityMultiplier: Double = 1.0
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
        // Progressive ramp: 15% density at plan start → 70% at peak,
        // multiplied by athlete VG density personalization (range
        // [0.85, 1.20] from PersonalizationProfile). An experienced
        // mountain runner (5+ ultras, 7+ years) can ramp toward ~84%
        // of race demand at peak; a first-time mountain runner stays
        // closer to 60%. Cap at 0.95 so even the most experienced
        // athlete never trains AT race density (specificity argument
        // says this is the wrong trade-off — race-day stress is for
        // race day).
        let personalizedProgressFactor = min(0.95, (0.15 + 0.55 * planProgress) * vgDensityMultiplier)
        let raw = volume * trainingElevationPerKm * personalizedProgressFactor
        return roundToNearest5(raw)
    }

    /// Rounds a value to the nearest 5 (e.g., 1003→1005, 1101→1100).
    private static func roundToNearest5(_ value: Double) -> Double {
        (value / 5.0).rounded() * 5.0
    }
}
