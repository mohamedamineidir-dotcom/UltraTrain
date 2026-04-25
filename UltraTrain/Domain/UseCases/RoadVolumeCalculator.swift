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

    /// Easy run durations by experience AND distance.
    ///
    /// Marathon easy runs are LONGER than 10K easy runs at the same experience level.
    /// Pfitzinger 18/70 marathon: GA runs 60-90min. 10K plans: 40-60min.
    /// The aerobic volume requirement scales with race distance.
    private static func easyParams(experience: ExperienceLevel, discipline: RoadRaceDiscipline) -> SessionParams {
        let distanceMultiplier: Double = switch discipline {
        case .road10K:      1.0
        case .roadHalf:     1.15
        case .roadMarathon: 1.35  // Marathon easy runs ~35% longer than 10K
        }
        let base: SessionParams = switch experience {
        case .beginner:     SessionParams(startMinutes: 30, peakMinutes: 42)
        case .intermediate: SessionParams(startMinutes: 35, peakMinutes: 50)
        case .advanced:     SessionParams(startMinutes: 40, peakMinutes: 58)
        case .elite:        SessionParams(startMinutes: 45, peakMinutes: 62)
        }
        return SessionParams(
            startMinutes: base.startMinutes * distanceMultiplier,
            peakMinutes: base.peakMinutes * distanceMultiplier
        )
    }

    /// Interval session durations by experience AND distance.
    /// Marathon intervals (including warm-up/cool-down) are longer because
    /// warm-up is more important and work blocks can be 20-40min at MP.
    private static func intervalParams(experience: ExperienceLevel, discipline: RoadRaceDiscipline) -> SessionParams {
        let distanceMultiplier: Double = switch discipline {
        case .road10K:      1.0
        case .roadHalf:     1.08
        case .roadMarathon: 1.18  // Marathon quality sessions ~18% longer
        }
        let base: SessionParams = switch experience {
        case .beginner:     SessionParams(startMinutes: 40, peakMinutes: 52)
        case .intermediate: SessionParams(startMinutes: 42, peakMinutes: 60)
        case .advanced:     SessionParams(startMinutes: 45, peakMinutes: 70)
        case .elite:        SessionParams(startMinutes: 48, peakMinutes: 78)
        }
        return SessionParams(
            startMinutes: base.startMinutes * distanceMultiplier,
            peakMinutes: base.peakMinutes * distanceMultiplier
        )
    }

    /// Tempo session durations by experience AND distance.
    private static func tempoParams(experience: ExperienceLevel, discipline: RoadRaceDiscipline) -> SessionParams {
        let distanceMultiplier: Double = switch discipline {
        case .road10K:      1.0
        case .roadHalf:     1.10
        case .roadMarathon: 1.20  // Marathon tempo ~20% longer (more threshold work)
        }
        let base: SessionParams = switch experience {
        case .beginner:     SessionParams(startMinutes: 35, peakMinutes: 48)
        case .intermediate: SessionParams(startMinutes: 38, peakMinutes: 55)
        case .advanced:     SessionParams(startMinutes: 42, peakMinutes: 65)
        case .elite:        SessionParams(startMinutes: 45, peakMinutes: 72)
        }
        return SessionParams(
            startMinutes: base.startMinutes * distanceMultiplier,
            peakMinutes: base.peakMinutes * distanceMultiplier
        )
    }

    // MARK: - Public

    static func calculate(
        skeletons: [WeekSkeletonBuilder.WeekSkeleton],
        athlete: Athlete,
        raceDistanceKm: Double,
        taperProfile: TaperProfile,
        raceGoal: RaceGoal = .targetTime(0)
    ) -> [VolumeCalculator.WeekVolume] {
        guard !skeletons.isEmpty else { return [] }

        let experience = athlete.experienceLevel
        let totalWeeks = skeletons.count
        let discipline = RoadRaceDiscipline.from(distanceKm: raceDistanceKm)

        let easyP = easyParams(experience: experience, discipline: discipline)
        let intervalP = intervalParams(experience: experience, discipline: discipline)
        let tempoP = tempoParams(experience: experience, discipline: discipline)

        let avgPaceSecPerKm: Double = switch experience {
        case .beginner:     370
        case .intermediate: 330
        case .advanced:     295
        case .elite:        265
        }
        // RR-7f: weight goal no longer modifies training volume. UltraTrain is
        // a race-training app — the race goal drives the plan, and weight
        // management is a nutrition concern (already handled by the nutrition
        // pipeline's calorie/hour scaling). Letting weightGoal silently
        // inflate or shrink peak km compromised the race prescription for
        // anyone not on .maintain. Race-first.
        let peakKmCeiling = discipline.peakWeeklyKm(experience: experience)

        // RR-1: Anchor Week 1 session volume to the athlete's declared
        // weeklyVolumeKm so the plan starts at their ACTUAL current base,
        // not a tier-generic default. Applied uniformly across all weeks
        // (preserves the progression shape, shifts the whole ramp up/down).
        // BJSM 2018 cohort: most reliable injury predictor is single-week
        // volume jumping more than ~10% above the athlete's recent base.
        let sessionScalingFactor: Double = computeWeek1ScalingFactor(
            athlete: athlete,
            easyP: easyP,
            intervalP: intervalP,
            tempoP: tempoP,
            avgPaceSecPerKm: avgPaceSecPerKm,
            totalWeeks: totalWeeks,
            raceDistanceKm: raceDistanceKm,
            experience: experience,
            peakKmCeiling: peakKmCeiling
        )

        // Master athletes (50+) get a small volume reduction. Stacks
        // multiplicatively on the week-1 anchor, so the whole plan shifts
        // down without changing its shape. Same multiplier as trail.
        let ageScale = VolumeCapCalculator.ageVolumeMultiplier(age: athlete.age)

        var volumes: [VolumeCalculator.WeekVolume] = []
        var taperWeekCounter = 0
        let taperStart = totalWeeks - taperProfile.totalTaperWeeks
        var previousNonRecoveryKm: Double = 0 // Track for 10% cap and post-recovery baseline

        // Track week-in-phase for explicit peak-phase progressive overload
        var peakWeekCounter = 0

        for (index, skeleton) in skeletons.enumerated() {
            // Tiered progress by phase (Daniels/Canova: build fast in base, hold in peak)
            // Base: 0→0.45 progress, Build: 0.45→0.78 progress, Peak: 0.78→1.00
            //
            // Peak was 0.90→1.00 (10% range) which produced near-identical weeks
            // after minute-rounding. Pfitzinger/Daniels peak phases show real
            // week-to-week progression, so we stretch peak to a 22% range.
            let peakWeekIndex = max(taperStart - 1, 1)
            let rawProgress = min(Double(index) / Double(peakWeekIndex), 1.0)
            let progress: Double
            switch skeleton.phase {
            case .base:
                // Accelerated: reach 45% of growth by end of base
                let baseEnd = Double(skeletons.firstIndex { $0.phase != .base } ?? totalWeeks) / Double(peakWeekIndex)
                let inPhaseProgress = min(rawProgress / max(baseEnd, 0.01), 1.0)
                progress = inPhaseProgress * 0.45
            case .build:
                // Steady: 45% → 78% of growth
                progress = 0.45 + (rawProgress - 0.30) / 0.70 * 0.33
            case .peak:
                // Meaningful progression: 78% → 100% across the peak phase
                progress = min(0.78 + (rawProgress - 0.70) / 0.30 * 0.22, 1.0)
            default:
                progress = rawProgress
            }
            let clampedProgress = max(min(progress, 1.0), 0.0)

            // RR-1 anchor (RR-9 correction): the scaling factor shifts only
            // the STARTING point of each session-duration ramp, not the peak.
            // Week 1 lands at the athlete's declared base; peak still reaches
            // the tier ceiling so volume grows naturally over the block. The
            // original implementation applied the factor to both ends, which
            // crushed peak volume for athletes whose declared base was well
            // below tier default (e.g., a 2:40 marathoner declaring 55 km/wk
            // had peaks of ~5 h/week instead of the 8-9 h tier target).
            // ageScale applies to BOTH start and peak — masters need
            // across-the-board volume reduction, not just a low Week 1.
            // sessionScalingFactor only scales start (the anchor) so that
            // a 2:40 marathoner declaring 55 km/wk doesn't get peak weeks
            // crushed too — peak is set by the tier ceiling.
            let scaledEasyParams = SessionParams(
                startMinutes: easyP.startMinutes * sessionScalingFactor * ageScale,
                peakMinutes: easyP.peakMinutes * ageScale
            )
            let scaledIntervalParams = SessionParams(
                startMinutes: intervalP.startMinutes * sessionScalingFactor * ageScale,
                peakMinutes: intervalP.peakMinutes * ageScale
            )
            let scaledTempoParams = SessionParams(
                startMinutes: tempoP.startMinutes * sessionScalingFactor * ageScale,
                peakMinutes: tempoP.peakMinutes * ageScale
            )
            var easy1Seconds = linearDuration(params: scaledEasyParams, progress: clampedProgress)
            var easy2Seconds = linearDuration(params: scaledEasyParams, progress: clampedProgress) * 0.9
            var intervalSeconds = linearDuration(params: scaledIntervalParams, progress: clampedProgress)
            var tempoSeconds = linearDuration(params: scaledTempoParams, progress: clampedProgress)

            // Explicit peak-phase progressive overload on quality sessions.
            // Pfitzinger's LT sessions grow ~1 min/wk in the peak mesocycle;
            // Daniels' Q-workouts grow in total T/I volume each peak week.
            // Without this bump, minute-rounding hides progression entirely.
            //
            // RR-9: bump no longer multiplied by sessionScalingFactor. Peak
            // is already at tier ceiling, so the bump is proportional to the
            // tier target, not the athlete's declared base. Low-base athletes
            // who ramp to tier peak get the same peak progression as athletes
            // starting higher.
            if skeleton.phase == .peak && !skeleton.isRecoveryWeek {
                let bump = Double(peakWeekCounter)
                intervalSeconds += bump * 90   // +1.5 min per non-recovery peak week
                tempoSeconds    += bump * 120  // +2.0 min per non-recovery peak week
                easy1Seconds    += bump * 45   // +0.75 min
                easy2Seconds    += bump * 30   // +0.50 min
                peakWeekCounter += 1
            }

            // Long run: quadratic growth (delegated). Anchored to athlete's
            // declared longestRunKm inside the calculator (RR-1).
            let longRunSeconds = RoadLongRunCalculator.longRunDuration(
                weekIndex: index,
                totalWeeks: totalWeeks,
                phase: skeleton.phase,
                experience: experience,
                raceDistanceKm: raceDistanceKm,
                currentLongestRunKm: athlete.longestRunKm,
                isRecoveryWeek: skeleton.isRecoveryWeek,
                philosophy: athlete.trainingPhilosophy,
                raceGoal: raceGoal
            )

            // HARD CAP: Easy runs must NEVER exceed long run, and absolute max 90min
            let easyAbsoluteMax: TimeInterval = 5400 // 90 min — no easy run should be 2h+
            easy1Seconds = min(easy1Seconds, longRunSeconds * 0.65, easyAbsoluteMax)
            easy2Seconds = min(easy2Seconds, longRunSeconds * 0.58, easyAbsoluteMax)

            // Recovery weeks: Pfitzinger uses ~80-85% of load week volume
            // Keep the reduction gentle — recovery should feel like a lighter week, not a shutdown
            if skeleton.isRecoveryWeek {
                easy1Seconds *= 0.87
                easy2Seconds *= 0.87
                intervalSeconds *= 0.85
                tempoSeconds *= 0.85
            }

            // Taper: Mujika 2003 principle — reduce VOLUME, preserve INTENSITY.
            // Easy runs absorb most of the volume cut; quality sessions either
            // keep a high fraction of their peak duration (intensity intact via
            // pace from the template) or get zeroed out when qualityAllowedPerWeek
            // says so. Race week with qualityAllowed=false → RoadSessionSelector
            // substitutes a dress-rehearsal (short MP segment) in the tempo slot.
            if skeleton.phase == .taper {
                let weekInTaper = taperWeekCounter
                let fraction = taperProfile.volumeFraction(forWeekInTaper: weekInTaper)
                let qualityAllowed = taperProfile.isQualityAllowed(forWeekInTaper: weekInTaper)

                // Easy runs: full volume cut
                easy1Seconds *= fraction
                easy2Seconds *= fraction

                if qualityAllowed {
                    // Preserve intensity: never cut quality volume below 65% of peak.
                    // The athlete keeps hitting 5K pace / LT pace, just with fewer/
                    // shorter reps. Mujika: intensity is the stimulus that matters.
                    let qualityFraction = max(fraction, 0.65)
                    intervalSeconds *= qualityFraction
                    tempoSeconds *= qualityFraction
                } else {
                    // True-taper weeks: no hard intervals. Tempo slot may host a
                    // dress rehearsal instead (handled in RoadSessionSelector); we
                    // leave a minimal tempo budget so the selector can allocate it.
                    intervalSeconds = 0
                    // Leave ~40-50 min for a dress rehearsal session (warm-up +
                    // 15-20 min MP + cool-down). RoadSessionSelector fills this slot.
                    tempoSeconds = min(tempoSeconds * 0.50, 45 * 60)
                }

                taperWeekCounter += 1
            }

            // Round to nearest MINUTE (not 5 minutes — 5min rounding causes identical consecutive weeks)
            easy1Seconds = (easy1Seconds / 60).rounded() * 60
            easy2Seconds = (easy2Seconds / 60).rounded() * 60
            intervalSeconds = (intervalSeconds / 60).rounded() * 60
            tempoSeconds = (tempoSeconds / 60).rounded() * 60

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

    // MARK: - RR-1 Anchor

    /// Computes the scaling factor applied to easy/interval/tempo session
    /// durations so Week 1 of the plan lands at ~85% of the athlete's
    /// declared `weeklyVolumeKm`. Applied uniformly across all weeks — the
    /// progression SHAPE stays the same, the whole ramp just shifts.
    ///
    /// Safety clamps:
    /// - Floor at 50% of tier-default Week 1 (prevents a starving plan if
    ///   the athlete declared an unrealistically low value).
    /// - Ceiling at 80% of tier peak (leaves headroom to grow into peak
    ///   weeks; if an athlete's declared base is already at peak they
    ///   probably should be on a higher-experience plan).
    /// - Falls through to 1.0 when `weeklyVolumeKm <= 0` (no onboarding data).
    private static func computeWeek1ScalingFactor(
        athlete: Athlete,
        easyP: SessionParams,
        intervalP: SessionParams,
        tempoP: SessionParams,
        avgPaceSecPerKm: Double,
        totalWeeks: Int,
        raceDistanceKm: Double,
        experience: ExperienceLevel,
        peakKmCeiling: Double
    ) -> Double {
        guard athlete.weeklyVolumeKm > 0 else { return 1.0 }

        // Unscaled Week 1 non-long-run total (all sessions at startMinutes).
        let unscaledWeek1Seconds =
            easyP.startMinutes * 60
            + easyP.startMinutes * 60 * 0.9
            + intervalP.startMinutes * 60
            + tempoP.startMinutes * 60

        // Unscaled Week 1 long run (may itself be anchored to longestRunKm).
        // Passes athlete's philosophy through so the cap is consistent with
        // the per-week call site above. We don't have raceGoal here, so we
        // pass the default — the cap variation is dominated by philosophy
        // anyway, and this is only used for anchor-ratio computation
        // (philosophy multiplier cancels in numerator/denominator).
        let unscaledWeek1LongRun = RoadLongRunCalculator.longRunDuration(
            weekIndex: 0,
            totalWeeks: totalWeeks,
            phase: .base,
            experience: experience,
            raceDistanceKm: raceDistanceKm,
            currentLongestRunKm: athlete.longestRunKm,
            isRecoveryWeek: false,
            philosophy: athlete.trainingPhilosophy
        )

        let unscaledWeek1TotalKm = (unscaledWeek1Seconds + unscaledWeek1LongRun) / avgPaceSecPerKm
        guard unscaledWeek1TotalKm > 0 else { return 1.0 }

        // RR-12: Floor is an absolute sanity minimum (10 km/wk), not a
        // fraction of the tier-default Week 1. The previous floor of
        // unscaledWeek1TotalKm × 0.5 overrode the athlete's declared value
        // whenever their base was below ~60% of tier default — which is
        // exactly the case we most need to respect (low-base athletes are
        // the ones at injury risk from a plan that starts too high).
        //
        // For a beginner 10K athlete declaring 15 km/wk with tier-default
        // Week 1 ≈ 40 km, the old floor of 20 km forced Week 1 to 33% above
        // declared. 10 km/wk is the floor below which a structured plan isn't
        // really a plan — plan generation itself should warn the athlete to
        // build base first, but we still produce something.
        let targetWeek1Km = athlete.weeklyVolumeKm * 0.85
        let floor: Double = 10  // km/wk absolute minimum
        let ceiling = peakKmCeiling * 0.80
        let clampedTarget = max(floor, min(ceiling, targetWeek1Km))

        // The long run in Week 1 is already anchored separately, so the
        // session scaling factor scales only non-long-run time. Compute
        // what Week 1 non-long-run needs to be to land on clampedTarget:
        let targetNonLongRunKm = max(0, clampedTarget - (unscaledWeek1LongRun / avgPaceSecPerKm))
        let unscaledNonLongRunKm = unscaledWeek1Seconds / avgPaceSecPerKm
        guard unscaledNonLongRunKm > 0 else { return 1.0 }

        return targetNonLongRunKm / unscaledNonLongRunKm
    }
}
