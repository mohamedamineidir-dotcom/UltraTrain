import Foundation

enum LongRunCurveCalculator {

    struct WeekDurations: Equatable, Sendable {
        let longRunSeconds: TimeInterval
        let isB2B: Bool
        let b2bDay1Seconds: TimeInterval
        let b2bDay2Seconds: TimeInterval
        let easyRun1Seconds: TimeInterval
        let easyRun2Seconds: TimeInterval
        let intervalSeconds: TimeInterval
        let vgSeconds: TimeInterval
        let totalSeconds: TimeInterval
    }

    // MARK: - Public

    static func durations(
        weekIndex: Int,
        totalWeeks: Int,
        phase: TrainingPhase,
        isRecoveryWeek: Bool,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy,
        raceGoal: RaceGoal = .finish,
        raceDurationSeconds: TimeInterval,
        raceEffectiveKm: Double,
        preferredRunsPerWeek: Int,
        currentWeeklyVolumeKm: Double = 40,
        previousNonRecoveryWeekTotal: TimeInterval = 0,
        taperProfile: TaperProfile? = nil,
        weekNumberInTaper: Int = 0,
        athleteAge: Int = 0,
        personalization: PersonalizationProfile? = nil
    ) -> WeekDurations {
        let planProgress = totalWeeks > 1
            ? Double(weekIndex) / Double(totalWeeks - 1)
            : 1.0

        // --- Long run ---
        let rawLongRun = longRunDuration(
            weekIndex: weekIndex,
            totalWeeks: totalWeeks,
            phase: phase,
            experience: experience,
            philosophy: philosophy,
            raceGoal: raceGoal,
            preferredRunsPerWeek: preferredRunsPerWeek,
            raceEffectiveKm: raceEffectiveKm,
            currentWeeklyVolumeKm: currentWeeklyVolumeKm,
            raceDurationSeconds: raceDurationSeconds,
            taperProfile: taperProfile,
            athleteAge: athleteAge,
            personalization: personalization
        )

        // --- B2B decision ---
        let b2b = isB2BWeek(
            weekIndex: weekIndex,
            totalWeeks: totalWeeks,
            phase: phase,
            isRecoveryWeek: isRecoveryWeek,
            experience: experience,
            raceEffectiveKm: raceEffectiveKm,
            raceDurationSeconds: raceDurationSeconds,
            taperProfile: taperProfile
        )

        // --- Base sessions ---
        let philMultiplier = philosophyBaseMultiplier(philosophy)
        let goalMultiplier = raceGoalBaseMultiplier(raceGoal)
        let combinedMultiplier = philMultiplier * goalMultiplier
        // Don't scale session durations by runs/week. SessionTemplateGenerator
        // handles session count via pool selection. Each session should be its
        // full proper duration, not shrunk when athlete picks fewer sessions.
        var easy1 = baseEasyDuration(planProgress) * combinedMultiplier
        var easy2 = baseEasyDuration(planProgress) * combinedMultiplier
        var interval = baseIntervalDuration(planProgress) * combinedMultiplier
        var vg = baseVGDuration(planProgress) * combinedMultiplier

        // B2B adjustments
        var longRun: TimeInterval
        var b2bDay1: TimeInterval = 0
        var b2bDay2: TimeInterval = 0

        if b2b {
            let combined = b2bCombinedDuration(
                weekIndex: weekIndex,
                totalWeeks: totalWeeks,
                experience: experience,
                philosophy: philosophy,
                raceGoal: raceGoal,
                raceDurationSeconds: raceDurationSeconds,
                raceEffectiveKm: raceEffectiveKm,
                taperProfile: taperProfile,
                athleteAge: athleteAge,
                personalization: personalization
            )
            b2bDay1 = combined * AppConfiguration.Training.b2bDay1Split
            b2bDay2 = combined * AppConfiguration.Training.b2bDay2Split
            longRun = b2bDay1 + b2bDay2

            let easyFloor: TimeInterval = 30 * 60
            let vgFloor: TimeInterval = 40 * 60

            let buildWeekCount = max(totalWeeks - taperWeekEstimate(totalWeeks, taperProfile: taperProfile), 1)
            let halfPoint = buildWeekCount / 2
            let b2bIdx = max(weekIndex - halfPoint, 0) / 2
            let introCount = effectiveIntroCount(totalWeeks: totalWeeks)
            let totalB2B = totalB2BWeekCount(totalWeeks: totalWeeks, taperProfile: taperProfile)
            let isHardest = b2bIdx >= totalB2B - AppConfiguration.Training.b2bHardestWeekCount

            // Compute target-based supporting budget
            let supportingBudget: TimeInterval

            if b2bIdx < introCount {
                // Introduction B2B: ~93.5% of previous non-recovery week volume
                if previousNonRecoveryWeekTotal > 0 {
                    let targetTotal = previousNonRecoveryWeekTotal * AppConfiguration.Training.b2bIntroVolumeRatio
                    supportingBudget = max(targetTotal - combined, 0)
                } else {
                    // Fallback when no previous week data: 15% of combined as supporting
                    supportingBudget = combined * 0.18
                }
            } else {
                // Regular B2B: dynamic B2B fraction of total (70-76%)
                let b2bWeeklyFrac = VolumeCapCalculator.b2bWeeklyFraction(
                    experience: experience,
                    raceEffectiveKm: raceEffectiveKm,
                    philosophy: philosophy
                )
                let rawTarget = combined / b2bWeeklyFrac
                let targetTotal: TimeInterval
                if previousNonRecoveryWeekTotal > 0 {
                    targetTotal = max(rawTarget, previousNonRecoveryWeekTotal * AppConfiguration.Training.b2bMinExceedPreviousRatio)
                } else {
                    targetTotal = rawTarget
                }
                supportingBudget = max(targetTotal - combined, 0)
            }

            // Distribute supporting budget: drop intervals, keep VG (unless hardest)
            interval = 0

            if isHardest {
                // Hardest B2B weeks: all supporting = easy runs
                vg = 0
                easy1 = max(supportingBudget * 0.5, easyFloor)
                easy2 = max(supportingBudget * 0.5, easyFloor)
            } else {
                // Regular/intro B2B: keep VG, rest to easy runs
                vg = max(min(supportingBudget * 0.35, 50 * 60), supportingBudget > vgFloor ? vgFloor : 0)
                let easyBudget = max(supportingBudget - vg, 0)
                easy1 = max(easyBudget * 0.5, easyFloor)
                easy2 = max(easyBudget * 0.5, easyFloor)
            }
            // Cap easy runs during B2B weeks and redistribute excess to B2B days
            let b2bEasyMax = AppConfiguration.Training.b2bEasyRunMaxMinutes * 60
            let excess1 = max(easy1 - b2bEasyMax, 0)
            let excess2 = max(easy2 - b2bEasyMax, 0)
            easy1 = min(easy1, b2bEasyMax)
            easy2 = min(easy2, b2bEasyMax)
            let totalExcess = excess1 + excess2
            if totalExcess > 0 {
                b2bDay1 += totalExcess * AppConfiguration.Training.b2bDay1Split
                b2bDay2 += totalExcess * AppConfiguration.Training.b2bDay2Split
                longRun = b2bDay1 + b2bDay2
            }
        } else {
            longRun = rawLongRun
        }

        // Recovery week reductions. Beginners get deeper cuts: novices
        // benefit from larger reductions due to slower adaptation and
        // higher injury risk. Generic running-coach consensus skews the
        // 10-40% deload range higher for newer runners. Intermediate+
        // stay at the established 25/35% cuts that match Higdon and the
        // mainstream French trail-coaching norm.
        if isRecoveryWeek {
            let easyMult: Double = (experience == .beginner) ? 0.65 : 0.75
            let lrMult: Double = (experience == .beginner) ? 0.55 : 0.65
            easy1 *= easyMult
            easy2 *= easyMult
            interval *= easyMult
            vg *= easyMult
            if b2b {
                // Beginners never reach B2B (gated in isB2BWeek), so this
                // branch is intermediate+ only. Keep current ×0.65.
                b2bDay1 *= 0.65
                b2bDay2 *= 0.65
                longRun = b2bDay1 + b2bDay2
            } else {
                longRun *= lrMult
            }
        }

        // Taper reductions
        if phase == .taper {
            let fraction: Double
            if let profile = taperProfile {
                fraction = profile.volumeFraction(forWeekInTaper: weekNumberInTaper)
            } else {
                let taperProgress = planProgress
                fraction = 0.80 - taperProgress * 0.30 // legacy fallback
            }

            easy1 *= fraction
            easy2 *= fraction
            longRun *= fraction

            if let profile = taperProfile, !profile.isQualityAllowed(forWeekInTaper: weekNumberInTaper) {
                interval = 0
                vg = 0
            } else {
                interval *= fraction
                vg *= fraction
            }

            b2bDay1 = 0
            b2bDay2 = 0
        }

        let total = easy1 + easy2 + interval + vg + longRun

        return WeekDurations(
            longRunSeconds: round(longRun),
            isB2B: b2b && phase != .taper,
            b2bDay1Seconds: round(b2bDay1),
            b2bDay2Seconds: round(b2bDay2),
            easyRun1Seconds: round(easy1),
            easyRun2Seconds: round(easy2),
            intervalSeconds: round(interval),
            vgSeconds: round(vg),
            totalSeconds: round(total)
        )
    }

    // MARK: - Long Run Curve (Quadratic)

    static func longRunDuration(
        weekIndex: Int,
        totalWeeks: Int,
        phase: TrainingPhase,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy = .balanced,
        raceGoal: RaceGoal = .finish,
        preferredRunsPerWeek: Int = 5,
        raceEffectiveKm: Double = 0,
        currentWeeklyVolumeKm: Double = 40,
        raceDurationSeconds: TimeInterval,
        taperProfile: TaperProfile? = nil,
        athleteAge: Int = 0,
        personalization: PersonalizationProfile? = nil
    ) -> TimeInterval {
        guard phase != .taper else {
            // Taper base = 85% of peak → then durations() multiplies by weekly fraction
            let peak = peakSingleLongRun(
                experience, raceDurationSeconds: raceDurationSeconds,
                philosophy: philosophy, raceGoal: raceGoal,
                raceEffectiveKm: raceEffectiveKm,
                athleteAge: athleteAge,
                personalization: personalization
            )
            return peak * AppConfiguration.Training.taperLongRunPeakFraction
        }

        let start = longRunStart(
            experience,
            currentWeeklyVolumeKm: currentWeeklyVolumeKm,
            preferredRunsPerWeek: preferredRunsPerWeek
        )
        let peak = peakSingleLongRun(
            experience, raceDurationSeconds: raceDurationSeconds,
            philosophy: philosophy, raceGoal: raceGoal,
            raceEffectiveKm: raceEffectiveKm,
            athleteAge: athleteAge,
            personalization: personalization
        )

        // Build weeks only (base + build + peak, excluding taper)
        let buildWeekCount = max(totalWeeks - taperWeekEstimate(totalWeeks, taperProfile: taperProfile), 1)
        let clampedIndex = min(weekIndex, buildWeekCount - 1)

        let progress: Double
        if buildWeekCount > 1 {
            progress = Double(clampedIndex) / Double(buildWeekCount - 1)
        } else {
            progress = 1.0
        }

        // Fix: if athlete's current long run already exceeds peak (elite + short race),
        // maintain current level rather than regressing
        let adjustedStart = min(start, peak)

        let exponent = AppConfiguration.Training.longRunCurveExponent
        let curved = pow(progress, exponent)
        return adjustedStart + (peak - adjustedStart) * curved
    }

    // MARK: - B2B Scheduling

    static func isB2BWeek(
        weekIndex: Int,
        totalWeeks: Int,
        phase: TrainingPhase,
        isRecoveryWeek: Bool,
        experience: ExperienceLevel,
        raceEffectiveKm: Double,
        raceDurationSeconds: TimeInterval,
        taperProfile: TaperProfile? = nil
    ) -> Bool {
        // Never in base or taper
        guard phase == .build || phase == .peak else { return false }
        guard !isRecoveryWeek else { return false }

        // Beginners don't get B2B
        guard experience != .beginner else { return false }

        // Race must be long enough
        let minEffectiveKm: Double
        switch experience {
        case .beginner: return false
        case .intermediate: minEffectiveKm = 80
        case .advanced: minEffectiveKm = 60
        case .elite: minEffectiveKm = 50
        }
        guard raceEffectiveKm >= minEffectiveKm else { return false }

        // Only in second half of non-taper weeks
        let buildWeekCount = max(totalWeeks - taperWeekEstimate(totalWeeks, taperProfile: taperProfile), 1)
        let halfPoint = buildWeekCount / 2
        guard weekIndex >= halfPoint else { return false }

        // Alternate: every other eligible week
        let indexFromHalf = weekIndex - halfPoint
        return indexFromHalf % 2 == 0
    }

    static func b2bCombinedDuration(
        weekIndex: Int,
        totalWeeks: Int,
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy = .balanced,
        raceGoal: RaceGoal = .finish,
        raceDurationSeconds: TimeInterval,
        raceEffectiveKm: Double = 100,
        taperProfile: TaperProfile? = nil,
        athleteAge: Int = 0,
        personalization: PersonalizationProfile? = nil
    ) -> TimeInterval {
        let startCombined = AppConfiguration.Training.b2bStartCombinedHours * 3600
        let maxCapHours = AppConfiguration.Training.peakB2BMaxHours[experience.rawValue] ?? 16.0

        // Dynamic B2B peak fraction (58-68% of race duration)
        let b2bFraction = VolumeCapCalculator.b2bPeakFraction(
            experience: experience,
            philosophy: philosophy,
            raceEffectiveKm: raceEffectiveKm
        )

        let philMult = AppConfiguration.Training.philosophyPeakMultiplier[philosophy.rawValue] ?? 1.0
        let goalMult = AppConfiguration.Training.goalPeakMultiplier[raceGoalConfigKey(raceGoal)] ?? 1.0
        let ageMult = VolumeCapCalculator.ageVolumeMultiplier(age: athleteAge)
        // Personalization composite (tenure × weight × ultra). Defaults
        // to 1.0 when no profile provided. Stacks on top of philosophy /
        // goal / age, matching peakSingleLongRun behaviour so peak LR
        // and B2B cap stay consistent.
        let persMult = personalization?.trailComposite ?? 1.0

        // Philosophy + age aware B2B cap. Performance (×1.15) lifts the
        // ceiling — an intermediate-for-performance HK100 athlete gets
        // ~14.95 h B2B instead of being clipped at 13 h, matching what
        // pro-coached training packages actually prescribe. Enjoyment
        // (×0.80) drops the ceiling so casual athletes never see a
        // brutal week. Master athletes (50+) trim further per
        // ageVolumeMultiplier. Goal type doesn't move the cap.
        let personalizedCapHours = maxCapHours * philMult * ageMult * persMult

        let peakCombined = min(
            raceDurationSeconds * b2bFraction * philMult * goalMult * ageMult * persMult,
            personalizedCapHours * 3600
        )

        let buildWeekCount = max(totalWeeks - taperWeekEstimate(totalWeeks, taperProfile: taperProfile), 1)
        let halfPoint = buildWeekCount / 2
        let b2bWeekIndex = max(weekIndex - halfPoint, 0)
        let b2bTotalWeeks = max(buildWeekCount - halfPoint, 1)

        let progress: Double
        if b2bTotalWeeks > 1 {
            progress = Double(b2bWeekIndex) / Double(b2bTotalWeeks - 1)
        } else {
            progress = 1.0
        }

        let exponent = AppConfiguration.Training.longRunCurveExponent
        let curved = pow(progress, exponent)
        return startCombined + (peakCombined - startCombined) * curved
    }

    // MARK: - B2B Helpers

    static func effectiveIntroCount(totalWeeks: Int) -> Int {
        totalWeeks <= 18 ? 1 : AppConfiguration.Training.b2bIntroductionWeekCount
    }

    static func totalB2BWeekCount(totalWeeks: Int, taperProfile: TaperProfile? = nil) -> Int {
        let buildWeekCount = max(totalWeeks - taperWeekEstimate(totalWeeks, taperProfile: taperProfile), 1)
        let halfPoint = buildWeekCount / 2
        let eligibleRange = buildWeekCount - halfPoint
        // B2B alternates every other week
        return max((eligibleRange + 1) / 2, 1)
    }

    // MARK: - Base Session Durations

    private static func baseEasyDuration(_ planProgress: Double) -> TimeInterval {
        let minutes = AppConfiguration.Training.easyRunStartMinutes
            + AppConfiguration.Training.easyRunGrowthMinutes * planProgress
        return minutes * 60
    }

    private static func baseIntervalDuration(_ planProgress: Double) -> TimeInterval {
        let minutes = AppConfiguration.Training.intervalStartMinutes
            + AppConfiguration.Training.intervalGrowthMinutes * planProgress
        return minutes * 60
    }

    private static func baseVGDuration(_ planProgress: Double) -> TimeInterval {
        let minutes = AppConfiguration.Training.vgStartMinutes
            + AppConfiguration.Training.vgGrowthMinutes * planProgress
        return minutes * 60
    }

    // MARK: - Helpers

    private static func longRunStart(
        _ experience: ExperienceLevel,
        currentWeeklyVolumeKm: Double = 40,
        preferredRunsPerWeek: Int = 5
    ) -> TimeInterval {
        let baseMinutes = AppConfiguration.Training.longRunStartMinutes[experience.rawValue] ?? 60

        // Estimate current long run as ~30% of weekly volume at 6.5 min/km pace
        let estimatedCurrentLRMinutes = currentWeeklyVolumeKm * 0.30 * 6.5

        // Use the higher of base or estimated current, so we don't regress
        let startMinutes = max(baseMinutes, estimatedCurrentLRMinutes)

        // Scale by runs/week: fewer runs → longer each run (cap at 1.3×)
        let runsScale = 5.0 / max(Double(preferredRunsPerWeek), 3.0)
        let scaled = startMinutes * min(runsScale, 1.3)

        return scaled * 60
    }

    private static func peakSingleLongRun(
        _ experience: ExperienceLevel,
        raceDurationSeconds: TimeInterval,
        philosophy: TrainingPhilosophy = .balanced,
        raceGoal: RaceGoal = .finish,
        raceEffectiveKm: Double = 0,
        athleteAge: Int = 0,
        personalization: PersonalizationProfile? = nil
    ) -> TimeInterval {
        let key = experience.rawValue
        let fraction = AppConfiguration.Training.peakSingleLRFraction[key] ?? 0.50
        let maxSeconds = (AppConfiguration.Training.peakSingleLRMaxHours[key] ?? 10.0) * 3600

        let philMult = AppConfiguration.Training.philosophyPeakMultiplier[philosophy.rawValue] ?? 1.0
        let goalMult = AppConfiguration.Training.goalPeakMultiplier[raceGoalConfigKey(raceGoal)] ?? 1.0
        // Master athletes (50+) get a small volume reduction to match
        // slower recovery. Stacks on top of philosophy + goal so a
        // performance-mode 55-year-old still gets a meaningful cap
        // bump over balanced-mode but below their 35-year-old self.
        let ageMult = VolumeCapCalculator.ageVolumeMultiplier(age: athleteAge)
        // Personalization multiplier (tenure × weight × ultra-experience),
        // hard-clamped to [0.75, 1.30]. Stacks on top of philosophy / goal
        // / age. Defaults to 1.0 when no profile is provided so existing
        // call sites are unaffected.
        let persMult = personalization?.trailComposite ?? 1.0
        let personalizedFraction = fraction * philMult * goalMult * ageMult * persMult

        // Philosophy-aware absolute cap. Performance lifts the ceiling
        // (intermediate from 8h to ~9.2h — matches what real coaches
        // prescribe for performance-mode 100K prep, e.g. HK100 with a
        // 9-hour single long run). Enjoyment drops it (~6.4h). Goal
        // type doesn't move the cap. Age also scales the cap.
        let personalizedCapSeconds = maxSeconds * philMult * ageMult * persMult

        var peak = min(raceDurationSeconds * personalizedFraction, personalizedCapSeconds)

        // Historical-data cap: never prescribe a peak LR more than 20%
        // above what the athlete has actually completed before. This
        // protects against tier-label / fraction math producing a peak
        // the athlete has no demonstrated tolerance for. Only applies
        // when we have a credible longest-run number.
        if let historicalCap = personalization?.historicalLongRunCapSeconds,
           historicalCap > 0 {
            peak = min(peak, historicalCap)
        }

        // When B2B is eligible, cap the single LR so B2B weeks are always
        // the biggest volume weeks. Single LR should not exceed B2B Day 1.
        let b2bEligible = experience != .beginner && raceEffectiveKm >= (
            experience == .intermediate ? 80 : experience == .advanced ? 60 : 50
        )
        if b2bEligible && raceDurationSeconds > 0 {
            let b2bFraction = VolumeCapCalculator.b2bPeakFraction(
                experience: experience,
                philosophy: philosophy,
                raceEffectiveKm: raceEffectiveKm
            )
            // B2B cap also philosophy + age + personalization aware so
            // the inline guard stays in sync with the standalone B2B
            // calculation in `b2bCombinedDuration`.
            let b2bMaxSeconds = (AppConfiguration.Training.peakB2BMaxHours[key] ?? 16.0) * philMult * ageMult * persMult * 3600
            let b2bCombinedPeak = min(
                raceDurationSeconds * b2bFraction * philMult * goalMult * ageMult * persMult,
                b2bMaxSeconds
            )
            let b2bDay1Peak = b2bCombinedPeak * AppConfiguration.Training.b2bDay1Split
            // Single LR capped at B2B Day 1 so B2B weeks stay the biggest
            peak = min(peak, b2bDay1Peak * 1.15) // allow slight overshoot for non-B2B peak week
        }

        return peak
    }

    static func taperWeekEstimate(_ totalWeeks: Int, taperProfile: TaperProfile? = nil) -> Int {
        if let profile = taperProfile {
            return min(profile.totalTaperWeeks, totalWeeks / 2)
        }
        // Legacy: ~10-15% of plan, min 2 weeks
        return max(Int(Double(totalWeeks) * 0.12), 2)
    }

    private static func philosophyBaseMultiplier(_ philosophy: TrainingPhilosophy) -> Double {
        switch philosophy {
        case .enjoyment:   0.85
        case .balanced:    1.00
        case .performance: 1.10
        }
    }

    private static func raceGoalBaseMultiplier(_ goal: RaceGoal) -> Double {
        switch goal {
        case .finish:          0.90  // Conservative — focus on completing
        case .targetTime:      1.00  // Moderate — balanced approach
        case .targetRanking:   1.10  // Aggressive — competitive volume
        }
    }

    private static func raceGoalConfigKey(_ goal: RaceGoal) -> String {
        switch goal {
        case .finish:          "finish"
        case .targetTime:      "targetTime"
        case .targetRanking:   "targetRanking"
        }
    }
}
