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
        case .roadMarathon: 1.27  // Marathon easy runs ~27% longer than 10K
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
        case .roadMarathon: 1.11  // Marathon quality sessions ~11% longer
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
        case .roadMarathon: 1.12  // Marathon tempo ~12% longer (more threshold work)
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
        raceGoal: RaceGoal = .targetTime(0),
        preferredRunsPerWeek: Int? = nil
    ) -> [VolumeCalculator.WeekVolume] {
        guard !skeletons.isEmpty else { return [] }

        let experience = athlete.experienceLevel
        let totalWeeks = skeletons.count
        let discipline = RoadRaceDiscipline.from(distanceKm: raceDistanceKm)
        let runsPerWeek = preferredRunsPerWeek ?? athlete.preferredRunsPerWeek

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
        // a race-training app, the race goal drives the plan, and weight
        // management is a nutrition concern (already handled by the nutrition
        // pipeline's calorie/hour scaling). Letting weightGoal silently
        // inflate or shrink peak km compromised the race prescription for
        // anyone not on .maintain. Race-first.
        let tierPeakCeiling = discipline.peakWeeklyKm(experience: experience)

        // RR-32: Base-scale the peak target. The training literature is
        // consistent that a runner's peak weekly volume should sit ~1.3-1.45x
        // their established in-season base, NOT at a fixed tier ceiling:
        //   • Pfitzinger 18/55 (peak 88 km) wants a 48-88 km base; 18/70
        //     (113 km) wants an 88-97 km base — peak ≈ 1.2-1.4x base.
        //   • Hansons "Advanced" peaks ~101-105 km off a ~80 km base.
        //   • Injury research: >30% jump over 2 weeks → 1.6x injury rate;
        //     performance returns flatten past ~80-113 km for non-elites.
        // A fixed ceiling over-ramps low-base athletes (a 45 km base pushed
        // toward 115 km is ~2.6x — an injury trap) and over-cooks our
        // representative advanced case vs the field. Scale to 1.40x the
        // declared base, clamped to [tier x 0.65 (marathon floor), tier
        // ceiling (safety cap for genuinely high-base athletes)].
        let peakKmCeiling: Double = {
            guard athlete.weeklyVolumeKm > 0 else { return tierPeakCeiling }
            let baseScaled = athlete.weeklyVolumeKm * 1.32
            return min(tierPeakCeiling, max(tierPeakCeiling * 0.65, baseScaled))
        }()

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
            peakKmCeiling: peakKmCeiling,
            taperWeeks: taperProfile.totalTaperWeeks,
            runsPerWeek: runsPerWeek,
            discipline: discipline
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

        // B5 final-block overload: a small Canova/Pfitzinger "final specific
        // block" lift over the last three non-recovery peak weeks so they
        // step up rather than all holding at the identical base-scaled peak.
        // Now that the peak is base-scaled (peakScalingFactor lands the raw
        // curve on target), this only needs to be a gentle step — a few
        // percent — not the old large flex that pushed past a flat ceiling.
        let finalBlockCeilingMultiplier: [Int: Double] = {
            let nonRecoveryPeakIndices = skeletons.enumerated().compactMap {
                (idx, sk) -> Int? in
                sk.phase == .peak && !sk.isRecoveryWeek ? idx : nil
            }
            let lastThree = Array(nonRecoveryPeakIndices.suffix(3))
            let multipliers: [Double] = [1.00, 1.015, 1.03]
            let offset = max(0, multipliers.count - lastThree.count)
            var m: [Int: Double] = [:]
            for (i, planIdx) in lastThree.enumerated() {
                m[planIdx] = multipliers[offset + i]
            }
            return m
        }()

        // Peak-week index: the volume curve plateaus a few weeks before taper,
        // in lockstep with the long run. Deterministic across the loop, so
        // compute it once here.
        // RR-26: peakWeekIndex was `taperStart - 1`, placing the volume peak at
        // the last non-taper week (same antipattern we corrected for the LR).
        // Shift to `taperStart - plateauOffset` so it plateaus 3-4 weeks before
        // taper. B7: plateauOffset is experience-aware (beginners get a 4-week
        // buffer; advanced/elite a 2-week buffer so peak LR lands 3-4 weeks out,
        // per Pfitzinger 18/85). Length-scaled floor keeps short plans sane.
        let baseOffset = min(4, max(1, totalWeeks / 5))
        let experienceOffsetAdjustment: Int = switch experience {
        case .beginner:      0
        case .intermediate: -1
        case .advanced:     -2
        case .elite:        -2
        }
        let plateauOffset = max(2, baseOffset + experienceOffsetAdjustment)
        let peakWeekIndex = max(taperStart - plateauOffset, 1)

        // RR-32: base-scale the PEAK end of every non-LR ramp too (mirrors the
        // Week-1 anchor at the other end). Without it, peak weeks pin flat
        // against the base-scaled ceiling instead of rising into it; with it,
        // the curve rises naturally to a base-appropriate peak and the ceiling
        // is just a safety clamp.
        let peakScalingFactor = computePeakScalingFactor(
            athlete: athlete, easyP: easyP, intervalP: intervalP, tempoP: tempoP,
            avgPaceSecPerKm: avgPaceSecPerKm, totalWeeks: totalWeeks,
            raceDistanceKm: raceDistanceKm, experience: experience,
            targetPeakKm: peakKmCeiling, taperWeeks: taperProfile.totalTaperWeeks,
            runsPerWeek: runsPerWeek, discipline: discipline, peakWeekIndex: peakWeekIndex
        )

        for (index, skeleton) in skeletons.enumerated() {
            // Tiered progress by phase (Daniels/Canova: build fast in base, hold
            // in peak). Base 0→0.45, Build 0.45→0.78, Peak 0.78→1.00 (a real
            // 22% peak range so weeks don't collapse to identical after
            // minute-rounding).
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

            // RR-1 / RR-32: both ends of each session ramp are individualised.
            // `sessionScalingFactor` shifts the START to the athlete's declared
            // base (Week 1); `peakScalingFactor` shifts the PEAK to the
            // base-scaled target (~1.35x base, capped by tier ceiling). The
            // ramp then runs from the athlete's real base to a base-appropriate
            // peak instead of a fixed tier ceiling, which previously over-ramped
            // low-base athletes (a 50 km base climbing to a 115 km tier peak is
            // ~2.5x, an injury trap). `ageScale` applies to both ends (masters
            // need across-the-board reduction, not just a low Week 1).
            let scaledEasyParams = SessionParams(
                startMinutes: easyP.startMinutes * sessionScalingFactor * ageScale,
                peakMinutes: easyP.peakMinutes * peakScalingFactor * ageScale
            )
            let scaledIntervalParams = SessionParams(
                startMinutes: intervalP.startMinutes * sessionScalingFactor * ageScale,
                peakMinutes: intervalP.peakMinutes * peakScalingFactor * ageScale
            )
            let scaledTempoParams = SessionParams(
                startMinutes: tempoP.startMinutes * sessionScalingFactor * ageScale,
                peakMinutes: tempoP.peakMinutes * peakScalingFactor * ageScale
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
            // declared longestRunKm inside the calculator (RR-1), with a
            // weeklyVolumeKm-based sanity cap so a trail-background
            // longest run doesn't dominate a road-plan week budget.
            let longRunSeconds = RoadLongRunCalculator.longRunDuration(
                weekIndex: index,
                totalWeeks: totalWeeks,
                phase: skeleton.phase,
                experience: experience,
                raceDistanceKm: raceDistanceKm,
                currentLongestRunKm: athlete.longestRunKm,
                isRecoveryWeek: skeleton.isRecoveryWeek,
                philosophy: athlete.trainingPhilosophy,
                raceGoal: raceGoal,
                weeklyVolumeKm: athlete.weeklyVolumeKm,
                taperWeeks: taperProfile.totalTaperWeeks,
                thresholdPacePerKm: athlete.thresholdPace60MinPerKm
            )

            // HARD CAP: Easy runs must NEVER exceed long run, and absolute max 90min
            let easyAbsoluteMax: TimeInterval = 5400 // 90 min, no easy run should be 2h+
            easy1Seconds = min(easy1Seconds, longRunSeconds * 0.65, easyAbsoluteMax)
            easy2Seconds = min(easy2Seconds, longRunSeconds * 0.58, easyAbsoluteMax)

            // Recovery (deload) weeks: cut volume to ~70% of the load week.
            // RR-31: the old ~15% cut (0.85/0.87) was invisible on the volume
            // chart, so the 3:1 block structure that every periodised plan is
            // built on (and that Campus Coach et al. show as a clean sawtooth)
            // read as a near-flat line. A real deload drops ~25-30% of volume
            // while KEEPING intensity (quality is cut slightly less than easy
            // so the athlete still touches race pace). The long run takes a
            // matching cut inside RoadLongRunCalculator so the whole week
            // troughs together. Trough depth is what makes the progressive
            // overload between blocks legible.
            if skeleton.isRecoveryWeek {
                easy1Seconds *= 0.68
                easy2Seconds *= 0.68
                intervalSeconds *= 0.74
                tempoSeconds *= 0.74
            }

            // Taper: Mujika 2003 principle, reduce VOLUME, preserve INTENSITY.
            // Easy runs absorb most of the volume cut; quality sessions either
            // keep a high fraction of their peak duration (intensity intact via
            // pace from the template) or get zeroed out when qualityAllowedPerWeek
            // says so. Race week with qualityAllowed=false → RoadSessionSelector
            // substitutes a dress-rehearsal (short MP segment) in the tempo slot.
            //
            // RR-26 / M2 note: the LONG RUN is NOT touched here. It is
            // tapered independently inside `RoadLongRunCalculator` (×0.60
            // when `phase == .taper`), so the LR is already the right
            // size by the time we reach this block. The taper fractions
            // below apply only to easy / interval / tempo. If you find
            // this surprising, it isn't a bug: the LR has its own taper
            // shape (flat 60% across all taper weeks) while non-LR
            // sessions follow the TaperProfile's per-week fractions
            // (e.g. 0.75 → 0.55 → 0.35 for marathon). Applying both
            // would double-cut the LR.
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

            // Round to nearest MINUTE (not 5 minutes, 5min rounding causes identical consecutive weeks)
            easy1Seconds = (easy1Seconds / 60).rounded() * 60
            easy2Seconds = (easy2Seconds / 60).rounded() * 60
            intervalSeconds = (intervalSeconds / 60).rounded() * 60
            tempoSeconds = (tempoSeconds / 60).rounded() * 60

            // Weekly total mirrors what RoadSessionSelector will actually
            // place on the calendar for the athlete's chosen frequency.
            // The previous version always summed the 5 fixed slots (LR +
            // 2 easy + interval + tempo) regardless of preferredRunsPerWeek,
            // so a 3-day athlete and a 7-day athlete saw identical km
            // targets even though the selector was adding (6+/wk) or
            // dropping (3-4/wk) sessions on top of that fixed budget.
            let totalSeconds = expectedWeeklySeconds(
                longRunSeconds: longRunSeconds,
                easy1Seconds: easy1Seconds,
                easy2Seconds: easy2Seconds,
                intervalSeconds: intervalSeconds,
                tempoSeconds: tempoSeconds,
                preferredRunsPerWeek: runsPerWeek,
                discipline: discipline,
                phase: skeleton.phase
            )
            var totalKm = totalSeconds / avgPaceSecPerKm

            // Issue #10: Peak volume ceiling, don't exceed discipline target.
            // B5: in the last three non-recovery peak weeks the ceiling is
            // flexed (1.00 / 1.05 / 1.10) so the final specific block has
            // perceptible week-to-week overload instead of plateauing.
            let ceilingMultiplier = finalBlockCeilingMultiplier[index] ?? 1.0
            totalKm = min(totalKm, peakKmCeiling * ceilingMultiplier)

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

    /// Returns the weekly total seconds the SessionSelector will actually
    /// place on the calendar for the athlete's chosen frequency.
    ///
    /// Mirrors RoadSessionSelector.pool composition:
    /// - ≤2 runs: LR + 2 easy (maintenance)
    /// - 3 runs: LR + 1 quality (tempo) + 1 easy
    /// - 4 runs: LR + 2 quality + 1 easy
    /// - 5 runs: LR + 2 quality + 2 easy (marathon swaps Fri easy → MLR)
    /// - 6 runs: LR + 2 quality + 3 easy (marathon / HM at 6+ swaps Wed easy → MLR)
    /// - 7 runs: LR + 2 quality + 4 easy (with optional MLR)
    ///
    /// Research basis: Daniels (Running Formula Ch. 6, 3-day vs 7-day plan
    /// templates), Pfitzinger 18/55 → 18/85 progression (more sessions at
    /// higher peak km), and the standard observation that weekly volume
    /// scales near-linearly with frequency for trained runners (~10-13 km
    /// per supporting session at advanced level).
    private static func expectedWeeklySeconds(
        longRunSeconds: TimeInterval,
        easy1Seconds: TimeInterval,
        easy2Seconds: TimeInterval,
        intervalSeconds: TimeInterval,
        tempoSeconds: TimeInterval,
        preferredRunsPerWeek: Int,
        discipline: RoadRaceDiscipline,
        phase: TrainingPhase
    ) -> TimeInterval {
        // MLR (Pfitzinger's medium-long run) eligibility mirrors
        // RoadSessionSelector exactly: marathon at 5+/wk, HM at 6+/wk,
        // never in the base phase.
        let mlrEligible = phase != .base && (
            (discipline == .roadMarathon && preferredRunsPerWeek >= 5)
            || (discipline == .roadHalf && preferredRunsPerWeek >= 6)
        )
        let mlrSeconds: TimeInterval = mlrEligible
            ? min(longRunSeconds * 0.65, 90 * 60)
            : 0

        switch preferredRunsPerWeek {
        case ...2:
            return longRunSeconds + easy1Seconds + easy2Seconds
        case 3:
            return longRunSeconds + tempoSeconds + easy1Seconds
        case 4:
            return longRunSeconds + intervalSeconds + tempoSeconds + easy1Seconds
        case 5:
            // Marathon at 5/wk: Fri easy becomes the MLR slot (sessionSelector
            // does the same swap). HM / 10K keep both easy runs.
            let easyContribution = (discipline == .roadMarathon)
                ? easy1Seconds + mlrSeconds
                : easy1Seconds + easy2Seconds
            return longRunSeconds + intervalSeconds + tempoSeconds + easyContribution
        case 6:
            // Wed slot is the MLR for marathon (and HM at 6/wk), else a 3rd easy.
            let wedSlot = mlrEligible ? mlrSeconds : easy1Seconds
            return longRunSeconds + intervalSeconds + tempoSeconds
                + easy1Seconds + easy2Seconds + wedSlot
        default: // 7+
            let wedSlot = mlrEligible ? mlrSeconds : easy1Seconds
            return longRunSeconds + intervalSeconds + tempoSeconds
                + easy1Seconds + easy2Seconds + wedSlot + easy2Seconds
        }
    }

    // MARK: - RR-1 Anchor

    /// Computes the scaling factor applied to easy/interval/tempo session
    /// durations so Week 1 of the plan lands at ~85% of the athlete's
    /// declared `weeklyVolumeKm`. Applied uniformly across all weeks, the
    /// progression SHAPE stays the same, the whole ramp just shifts.
    ///
    /// ## Why a single scaling factor?
    /// Sessions are sized in *minutes* by tier-default `startMinutes`
    /// values (e.g. advanced marathon easy run = 40 × 1.35 = 54 min start).
    /// An advanced athlete declaring 80 km/wk and one declaring 50 km/wk
    /// shouldn't get identical Week 1s; this factor scales every non-LR
    /// session up or down so the *total* Week 1 km lands near their
    /// declared base. The LR is anchored separately (RoadLongRunCalculator
    /// uses `currentLongestRunKm`), so this factor only touches non-LR
    /// time.
    ///
    /// ## Worked example (advanced 2h40 marathoner, 80 km/wk, 32 km LR)
    /// - `easyP.startMinutes = 54`, `intervalP.startMinutes = ~50`,
    ///   `tempoP.startMinutes = ~50` (advanced × marathon multipliers)
    /// - Unscaled Week 1 non-LR seconds = 54·60 + 54·60·0.9 + 50·60 + 50·60
    ///   ≈ 12 156 s ≈ 41 km @ 295 s/km
    /// - Unscaled Week 1 LR ≈ 21 km (capped at 35% of weekly volume by
    ///   RoadLongRunCalculator)
    /// - Unscaled Week 1 total ≈ 62 km
    /// - Target Week 1 = 80 × 0.85 = 68 km, clamped to [floor=10,
    ///   ceiling=peakKmCeiling × 0.80 = 92]
    /// - Target non-LR = 68 - 21 = 47 km
    /// - Unscaled non-LR = 41 km
    /// - **Scaling factor = 47 / 41 ≈ 1.146** (sessions scaled up ~15% so
    ///   Week 1 lands at 68 km instead of 62 km)
    ///
    /// ## Safety clamps
    /// - **Floor 10 km/wk** (absolute minimum below which a structured
    ///   plan isn't really a plan; the plan-generator should warn the
    ///   athlete to build base first but we still produce something).
    /// - **Ceiling = peakKmCeiling × 0.80** (leaves headroom to grow into
    ///   peak weeks; if declared base is already at peak the athlete
    ///   probably should be on a higher-experience plan).
    /// - **Returns 1.0 when `weeklyVolumeKm <= 0`** (no onboarding data;
    ///   tier defaults take over).
    /// - **Returns 1.0 when target non-LR ≤ 0** (LR alone exceeds Week 1
    ///   target; the LR cap will sort that out).
    private static func computeWeek1ScalingFactor(
        athlete: Athlete,
        easyP: SessionParams,
        intervalP: SessionParams,
        tempoP: SessionParams,
        avgPaceSecPerKm: Double,
        totalWeeks: Int,
        raceDistanceKm: Double,
        experience: ExperienceLevel,
        peakKmCeiling: Double,
        taperWeeks: Int,
        runsPerWeek: Int,
        discipline: RoadRaceDiscipline
    ) -> Double {
        guard athlete.weeklyVolumeKm > 0 else { return 1.0 }

        // Start-minute session durations (Week 1 sits at the start of every
        // ramp, progress = 0).
        let startEasy1 = easyP.startMinutes * 60
        let startEasy2 = easyP.startMinutes * 60 * 0.9
        let startInterval = intervalP.startMinutes * 60
        let startTempo = tempoP.startMinutes * 60

        // Unscaled Week 1 long run (may itself be anchored to longestRunKm).
        // Passes athlete's philosophy through so the cap is consistent with
        // the per-week call site above. We don't have raceGoal here, so we
        // pass the default, the cap variation is dominated by philosophy
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
            philosophy: athlete.trainingPhilosophy,
            weeklyVolumeKm: athlete.weeklyVolumeKm,
            taperWeeks: taperWeeks,
            thresholdPacePerKm: athlete.thresholdPace60MinPerKm
        )

        // RR-30: the anchor must predict the SAME weekly composition the
        // calculator actually places (via expectedWeeklySeconds), not a
        // fixed LR + 2-easy + 2-quality guess. At 6 runs/week a base week is
        // LR + interval + tempo + 3 easy; the old anchor counted only ~1.9
        // easy runs, so it under-scaled and Week 1 floated ~12 km (one easy
        // run) above the athlete's declared base. Using the real composition
        // lands Week 1 on target and lets the whole ramp breathe.
        let unscaledWeek1TotalSeconds = expectedWeeklySeconds(
            longRunSeconds: unscaledWeek1LongRun,
            easy1Seconds: startEasy1,
            easy2Seconds: startEasy2,
            intervalSeconds: startInterval,
            tempoSeconds: startTempo,
            preferredRunsPerWeek: runsPerWeek,
            discipline: discipline,
            phase: .base
        )
        let unscaledWeek1TotalKm = unscaledWeek1TotalSeconds / avgPaceSecPerKm
        guard unscaledWeek1TotalKm > 0 else { return 1.0 }

        // RR-12: Floor is an absolute sanity minimum (10 km/wk), not a
        // fraction of the tier-default Week 1. The previous floor of
        // unscaledWeek1TotalKm × 0.5 overrode the athlete's declared value
        // whenever their base was below ~60% of tier default, which is
        // exactly the case we most need to respect (low-base athletes are
        // the ones at injury risk from a plan that starts too high).
        //
        // For a beginner 10K athlete declaring 15 km/wk with tier-default
        // Week 1 ≈ 40 km, the old floor of 20 km forced Week 1 to 33% above
        // declared. 10 km/wk is the floor below which a structured plan isn't
        // really a plan, plan generation itself should warn the athlete to
        // build base first, but we still produce something.
        let targetWeek1Km = athlete.weeklyVolumeKm * 0.85
        let floor: Double = 10  // km/wk absolute minimum
        let ceiling = peakKmCeiling * 0.80
        let clampedTarget = max(floor, min(ceiling, targetWeek1Km))

        // The long run in Week 1 is already anchored separately, so the
        // scaling factor scales only the non-long-run sessions. In the base
        // phase there is no MLR (expectedWeeklySeconds gates MLR out of
        // base), so the whole non-LR remainder is scalable easy/quality
        // time. Compute what that remainder must be to land on clampedTarget.
        let targetNonLongRunKm = max(0, clampedTarget - (unscaledWeek1LongRun / avgPaceSecPerKm))
        let unscaledNonLongRunKm = (unscaledWeek1TotalSeconds - unscaledWeek1LongRun) / avgPaceSecPerKm
        guard unscaledNonLongRunKm > 0 else { return 1.0 }

        return targetNonLongRunKm / unscaledNonLongRunKm
    }

    // MARK: - RR-32 Peak Anchor

    /// Scales the PEAK end of every non-long-run session ramp so the peak
    /// week lands on the base-scaled `targetPeakKm`, mirroring the Week-1
    /// anchor at the opposite end of the plan. The long run (and the MLR
    /// derived from it) is anchored separately, so the factor scales only the
    /// easy/interval/tempo remainder. Result is clamped to a sane band so we
    /// never balloon or crush individual session lengths.
    private static func computePeakScalingFactor(
        athlete: Athlete,
        easyP: SessionParams,
        intervalP: SessionParams,
        tempoP: SessionParams,
        avgPaceSecPerKm: Double,
        totalWeeks: Int,
        raceDistanceKm: Double,
        experience: ExperienceLevel,
        targetPeakKm: Double,
        taperWeeks: Int,
        runsPerWeek: Int,
        discipline: RoadRaceDiscipline,
        peakWeekIndex: Int
    ) -> Double {
        // Long run at the peak week (phase .peak, non-recovery).
        let peakLongRun = RoadLongRunCalculator.longRunDuration(
            weekIndex: peakWeekIndex,
            totalWeeks: totalWeeks,
            phase: .peak,
            experience: experience,
            raceDistanceKm: raceDistanceKm,
            currentLongestRunKm: athlete.longestRunKm,
            isRecoveryWeek: false,
            philosophy: athlete.trainingPhilosophy,
            weeklyVolumeKm: athlete.weeklyVolumeKm,
            taperWeeks: taperWeeks,
            thresholdPacePerKm: athlete.thresholdPace60MinPerKm
        )

        // Unscaled peak-week total at the tier peak-minute durations.
        let unscaledTotalSeconds = expectedWeeklySeconds(
            longRunSeconds: peakLongRun,
            easy1Seconds: easyP.peakMinutes * 60,
            easy2Seconds: easyP.peakMinutes * 60 * 0.9,
            intervalSeconds: intervalP.peakMinutes * 60,
            tempoSeconds: tempoP.peakMinutes * 60,
            preferredRunsPerWeek: runsPerWeek,
            discipline: discipline,
            phase: .peak
        )

        // The MLR (when eligible) tracks the long run, so neither it nor the
        // LR are scaled by this factor; only the easy/interval/tempo remainder.
        let mlrEligible = (discipline == .roadMarathon && runsPerWeek >= 5)
            || (discipline == .roadHalf && runsPerWeek >= 6)
        let mlrSeconds: TimeInterval = mlrEligible ? min(peakLongRun * 0.65, 90 * 60) : 0
        let scalableSeconds = unscaledTotalSeconds - peakLongRun - mlrSeconds
        guard scalableSeconds > 0 else { return 1.0 }

        let targetScalableKm = targetPeakKm - (peakLongRun + mlrSeconds) / avgPaceSecPerKm
        let scalableKm = scalableSeconds / avgPaceSecPerKm
        guard scalableKm > 0, targetScalableKm > 0 else { return 1.0 }

        return min(1.25, max(0.55, targetScalableKm / scalableKm))
    }
}
