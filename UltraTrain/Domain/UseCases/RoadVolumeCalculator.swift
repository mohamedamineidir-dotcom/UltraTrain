import Foundation

/// Calculates weekly training volumes for road race plans using SESSION-FIRST approach.
///
/// ## Architecture (mirrors trail LongRunCurveCalculator)
/// Each session type has its own independent duration formula:
/// - Easy runs: linear growth with hard cap below long run
/// - Intervals: linear growth (includes warm-up/cool-down)
/// - Tempo: linear growth (includes warm-up/cool-down)
/// - Long run: quadratic growth (same pattern as trail)
/// Weekly volume = sum of all session durations (NOT the other way around).
///
/// ## Research basis
/// - **Daniels**: E runs 30-60 min, T sessions 40-60 min work + warm-up/cool-down,
///   I sessions with total work = 8% of weekly volume (10-15 min total reps).
/// - **Pfitzinger**: Easy runs 40-60 min for 18/55 through 18/85 plans.
///   Quality sessions 50-80 min including warm-up/cool-down.
///   Long run: 26-35km peak for marathon.
/// - **Canova**: Progressive increase in specific volume across mesocycles.
///   Quality before quantity.
enum RoadVolumeCalculator {

    // MARK: - Session Duration Parameters

    private struct SessionParams {
        let startMinutes: Double
        let peakMinutes: Double
    }

    /// Easy run durations by experience level.
    /// Daniels: E runs should be 30-75% of longest run, never longer than long run.
    /// Pfitzinger: 40-60 min easy for most plans.
    private static func easyParams(experience: ExperienceLevel) -> SessionParams {
        switch experience {
        case .beginner:     SessionParams(startMinutes: 30, peakMinutes: 42)
        case .intermediate: SessionParams(startMinutes: 35, peakMinutes: 50)
        case .advanced:     SessionParams(startMinutes: 40, peakMinutes: 60)
        case .elite:        SessionParams(startMinutes: 45, peakMinutes: 60)
        }
    }

    /// Interval session durations (total including warm-up + cool-down).
    /// Daniels: warm-up 10-15min, cool-down 5-10min, work portion 10-30min.
    /// Total: 40-75 min depending on phase and experience.
    private static func intervalParams(experience: ExperienceLevel) -> SessionParams {
        switch experience {
        case .beginner:     SessionParams(startMinutes: 40, peakMinutes: 52)
        case .intermediate: SessionParams(startMinutes: 42, peakMinutes: 60)
        case .advanced:     SessionParams(startMinutes: 45, peakMinutes: 70)
        case .elite:        SessionParams(startMinutes: 48, peakMinutes: 78)
        }
    }

    /// Tempo session durations (total including warm-up + cool-down).
    /// Daniels: T work = 10% of weekly volume, typical 20-40min work + warm-up/cool-down.
    private static func tempoParams(experience: ExperienceLevel) -> SessionParams {
        switch experience {
        case .beginner:     SessionParams(startMinutes: 35, peakMinutes: 48)
        case .intermediate: SessionParams(startMinutes: 38, peakMinutes: 55)
        case .advanced:     SessionParams(startMinutes: 42, peakMinutes: 65)
        case .elite:        SessionParams(startMinutes: 45, peakMinutes: 72)
        }
    }

    // MARK: - Public

    static func calculate(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        athlete: Athlete,
        raceDistanceKm: Double,
        taperProfile: TaperProfile
    ) -> [VolumeCalculator.WeekVolume] {
        guard !skeletons.isEmpty else { return [] }

        let experience = athlete.experienceLevel
        let totalWeeks = skeletons.count

        let easyP = easyParams(experience: experience)
        let intervalP = intervalParams(experience: experience)
        let tempoP = tempoParams(experience: experience)

        let avgPaceSecPerKm: Double = switch experience {
        case .beginner:     370
        case .intermediate: 330
        case .advanced:     295
        case .elite:        265
        }

        let discipline = RoadRaceDiscipline.from(distanceKm: raceDistanceKm)
        let peakKmCeiling = discipline.peakWeeklyKm(experience: experience)

        var volumes: [VolumeCalculator.WeekVolume] = []
        var taperWeekCounter = 0
        let taperStart = totalWeeks - taperProfile.totalTaperWeeks
        var previousNonRecoveryKm: Double = 0 // Track for 10% cap and post-recovery baseline

        for (index, skeleton) in skeletons.enumerated() {
            // Tiered progress by phase (Daniels/Canova: build fast in base, hold in peak)
            // Base: 0→0.5 progress, Build: 0.5→0.9 progress, Peak: 0.9→1.0 (near-hold)
            let peakWeekIndex = max(taperStart - 1, 1)
            let rawProgress = min(Double(index) / Double(peakWeekIndex), 1.0)
            let progress: Double
            switch skeleton.phase {
            case .base:
                // Accelerated: reach 50% of growth by end of base
                let baseEnd = Double(skeletons.firstIndex { $0.phase != .base } ?? totalWeeks) / Double(peakWeekIndex)
                let inPhaseProgress = min(rawProgress / max(baseEnd, 0.01), 1.0)
                progress = inPhaseProgress * 0.50
            case .build:
                // Steady: 50% → 90% of growth
                progress = 0.50 + (rawProgress - 0.30) / 0.70 * 0.40
            case .peak:
                // Near-hold: 90% → 100%
                progress = min(0.90 + (rawProgress - 0.70) / 0.30 * 0.10, 1.0)
            default:
                progress = rawProgress
            }
            let clampedProgress = max(min(progress, 1.0), 0.0)

            // Compute each session duration with tiered progress
            var easy1Seconds = linearDuration(params: easyP, progress: clampedProgress)
            var easy2Seconds = linearDuration(params: easyP, progress: clampedProgress) * 0.9
            var intervalSeconds = linearDuration(params: intervalP, progress: clampedProgress)
            var tempoSeconds = linearDuration(params: tempoP, progress: clampedProgress)

            // Long run: quadratic growth (delegated)
            let longRunSeconds = RoadLongRunCalculator.longRunDuration(
                weekIndex: index,
                totalWeeks: totalWeeks,
                phase: skeleton.phase,
                experience: experience,
                raceDistanceKm: raceDistanceKm,
                currentWeeklyVolumeKm: athlete.weeklyVolumeKm,
                isRecoveryWeek: skeleton.isRecoveryWeek
            )

            // HARD CAP: Easy runs must NEVER exceed long run
            easy1Seconds = min(easy1Seconds, longRunSeconds * 0.75)
            easy2Seconds = min(easy2Seconds, longRunSeconds * 0.70)

            // Recovery weeks: reduce from current level, not from peak
            if skeleton.isRecoveryWeek {
                easy1Seconds *= 0.80
                easy2Seconds *= 0.80
                intervalSeconds *= 0.70
                tempoSeconds *= 0.70
            }

            // Taper: apply profile fractions
            if skeleton.phase == .taper {
                let weekInTaper = taperWeekCounter
                let fraction = taperProfile.volumeFraction(forWeekInTaper: weekInTaper)
                easy1Seconds *= fraction
                easy2Seconds *= fraction
                intervalSeconds *= fraction
                tempoSeconds *= fraction
                taperWeekCounter += 1
            }

            // Round to nearest 5 minutes
            easy1Seconds = roundTo5Min(easy1Seconds)
            easy2Seconds = roundTo5Min(easy2Seconds)
            intervalSeconds = roundTo5Min(intervalSeconds)
            tempoSeconds = roundTo5Min(tempoSeconds)

            // Weekly total = sum of all sessions
            let totalSeconds = easy1Seconds + easy2Seconds + intervalSeconds + tempoSeconds + longRunSeconds
            var totalKm = totalSeconds / avgPaceSecPerKm

            // Issue #10: Peak volume ceiling — don't exceed discipline target
            totalKm = min(totalKm, peakKmCeiling)

            // Issue #2: 10% weekly growth cap (Canova: "never >10% week-on-week")
            // Issue #11: Post-recovery uses pre-recovery baseline, not recovery volume
            if !skeleton.isRecoveryWeek && skeleton.phase != .taper {
                if previousNonRecoveryKm > 0 {
                    let maxAllowed = previousNonRecoveryKm * 1.10
                    totalKm = min(totalKm, maxAllowed)
                }
                previousNonRecoveryKm = totalKm
            }

            // Recalculate totalSeconds if km was capped
            let finalTotalSeconds = totalKm * avgPaceSecPerKm

            volumes.append(VolumeCalculator.WeekVolume(
                weekNumber: skeleton.weekNumber,
                targetVolumeKm: round(totalKm * 10) / 10,
                targetElevationGainM: 0,
                targetDurationSeconds: round(finalTotalSeconds),
                targetLongRunDurationSeconds: round(longRunSeconds),
                isB2BWeek: false,
                b2bDay1Seconds: 0,
                b2bDay2Seconds: 0,
                baseSessionDurations: VolumeCalculator.BaseSessionDurations(
                    easyRun1Seconds: round(easy1Seconds),
                    easyRun2Seconds: round(easy2Seconds),
                    intervalSeconds: round(intervalSeconds),
                    vgSeconds: round(tempoSeconds)  // Repurposed: tempo for road
                ),
                weekNumberInTaper: skeleton.phase == .taper ? taperWeekCounter - 1 : 0,
                taperProfile: skeleton.phase == .taper ? taperProfile : nil
            ))
        }

        return volumes
    }

    // MARK: - Helpers

    /// Linear interpolation from start to peak based on plan progress.
    private static func linearDuration(params: SessionParams, progress: Double) -> TimeInterval {
        let minutes = params.startMinutes + (params.peakMinutes - params.startMinutes) * progress
        return minutes * 60
    }

    /// Rounds seconds to nearest 5-minute boundary.
    private static func roundTo5Min(_ seconds: TimeInterval) -> TimeInterval {
        (seconds / 300).rounded() * 300
    }
}
