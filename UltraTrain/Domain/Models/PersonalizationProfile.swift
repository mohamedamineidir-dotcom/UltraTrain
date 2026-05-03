import Foundation

/// Per-athlete multipliers + hard caps that personalize peak training
/// loads beyond the broad strokes of `experience × philosophy × goal ×
/// age × race`. Composed from athlete profile + (in v2) recent
/// training history. All multipliers individually clamped to [0.85,
/// 1.15]; the composite stack is hard-clamped to [0.75, 1.30] so no
/// single signal can blow up the prescription.
///
/// **Default-equivalent**: when the athlete profile yields no
/// personalization signal (a fresh sign-up), every multiplier is 1.0
/// and the hard caps are nil — i.e., the calculators behave exactly
/// as before. The type is therefore safe to thread through with
/// default `nil` parameters across the stack.
struct PersonalizationProfile: Equatable, Sendable {

    // MARK: - Multipliers

    /// Tenure: scales with consistent running years. <1y: 0.92,
    /// 1-3y: 0.95, 3-7y: 1.0, 7-15y: 1.05, 15y+: 1.10.
    let tenureMultiplier: Double

    /// Weight band: <70kg: 1.03, 70-85: 1.00, >85: 0.93. Heavier
    /// athletes carry more impact load on tendons, so peak loads
    /// scale down slightly to reduce injury risk at peak.
    let weightMultiplier: Double

    /// Ultra-distance experience (≥30 km trail finishes). 0 races:
    /// 0.95 (first-timer), 1-2: 1.00, 3-4: 1.05, 5+: 1.10. Only
    /// applied to trail/ultra plans; ignored for road.
    let ultraExperienceMultiplier: Double

    /// Vertical-gain density multiplier for trail plans. Scales the
    /// progressFactor in `VolumeCalculator.elevationForVolume` so an
    /// experienced mountain runner ramps closer to race demand at peak,
    /// while a first-time mountain runner stays conservative. Range
    /// [0.85, 1.20]. Composed from running tenure + ultra count
    /// (proxy for climbing background — true climbing-specific
    /// metric like recent peak D+/km would come from training history
    /// in v2). Applied trail-only; road plans ignore.
    let vgDensityMultiplier: Double

    // MARK: - Hard caps

    /// Athlete's longest completed single run, in seconds, capped at
    /// 1.20× to allow modest stretch above demonstrated tolerance.
    /// Nil when no historical longest run is available. Applied as
    /// a `min(...)` on the computed peak single LR.
    let historicalLongRunCapSeconds: TimeInterval?

    /// Maximum weekly running volume the athlete has actually
    /// completed in the last 90 days, in km. Drives the
    /// `effectiveWeeklyVolumeKm(snapshotKm:)` decision so the plan
    /// generator can anchor off **demonstrated** capacity rather
    /// than the static onboarding snapshot when the two diverge
    /// significantly. Nil when no recent training history is
    /// available (fresh account, generator wired without a
    /// RunRepository, or fewer than 4 weeks of logged data).
    let recentPeakWeeklyVolumeKm: Double?

    // MARK: - Reported injury structures

    /// Recurring injury sites the athlete flagged. Optional refinement
    /// signal — primary injury volume penalty is derived from
    /// `painFrequency` + `injuryCountLastYear` (which onboarding does
    /// collect). When `injuryStructures` is non-empty (v2 onboarding
    /// or profile-edit), it adds a small additional penalty AND will
    /// drive session-selection bias in v2 (avoid VG for ITB-prone, etc.).
    let injuryStructures: Set<InjuryStructure>

    /// Volume-cap dampening from the athlete's injury profile. Computed
    /// in the factory from painFrequency + injuryCountLastYear +
    /// injuryStructures, hard-floored at -2%. Stored (not computed) so
    /// that callers reading the profile see the final value without
    /// re-deriving from the source signals.
    let injuryVolumeCapPenalty: Double

    // MARK: - Composite

    /// Convenience: the trail/ultra composite multiplier (tenure ×
    /// weight × ultraExperience), hard-clamped to [0.75, 1.30].
    /// Use this for peak LR / B2B prescriptions in trail plans.
    var trailComposite: Double {
        clamp(tenureMultiplier * weightMultiplier * ultraExperienceMultiplier)
    }

    /// Road composite: tenure × weight only. Ultra experience is
    /// not relevant for road plans (a 100-mile finish does not
    /// directly translate to road readiness).
    var roadComposite: Double {
        clamp(tenureMultiplier * weightMultiplier)
    }

    private func clamp(_ value: Double) -> Double {
        max(0.75, min(1.30, value))
    }

    /// Returns the weekly volume baseline that should drive plan
    /// generation, picking between the athlete's onboarding snapshot
    /// and the demonstrated recent peak based on which best reflects
    /// current capacity.
    ///
    /// Decision rules:
    /// - `recentPeak >= snapshot × 1.15` → athlete is more capable
    ///   than they reported (often: returning user generating a new
    ///   plan after months of training) → use recentPeak so the
    ///   ramp matches current ability
    /// - `recentPeak <= snapshot × 0.70` → athlete has detrained
    ///   (often: returning after injury / long break) → use recentPeak
    ///   so we don't ramp from a stale higher baseline
    /// - otherwise → snapshot still matches reality, use it
    ///
    /// Falls through to snapshot when no recent peak is available.
    func effectiveWeeklyVolumeKm(snapshotKm: Double) -> Double {
        guard let peak = recentPeakWeeklyVolumeKm,
              peak > 0,
              snapshotKm > 0 else {
            return snapshotKm
        }
        let ratio = peak / snapshotKm
        if ratio >= 1.15 || ratio <= 0.70 {
            return peak
        }
        return snapshotKm
    }

    // MARK: - Default

    /// Profile that has no effect — all multipliers 1.0, no caps,
    /// no injury structures, zero injury penalty. Use as fallback
    /// when athlete data yields no signal.
    static let neutral = PersonalizationProfile(
        tenureMultiplier: 1.0,
        weightMultiplier: 1.0,
        ultraExperienceMultiplier: 1.0,
        vgDensityMultiplier: 1.0,
        historicalLongRunCapSeconds: nil,
        recentPeakWeeklyVolumeKm: nil,
        injuryStructures: [],
        injuryVolumeCapPenalty: 0
    )
}

// MARK: - Factory

extension PersonalizationProfile {

    /// Builds a personalization profile from an athlete. Pace
    /// estimate is used to convert `longestRunKm` into a hard
    /// cap on peak LR seconds; defaults to 7.5 min/km which is a
    /// reasonable ultra-pace baseline. Pass a faster pace (e.g.
    /// 6.0 min/km) for road athletes when you have one.
    ///
    /// Onboarding-derivation strategy: today's onboarding doesn't
    /// ask for `runningYears` or `injuryStructures` directly — both
    /// fall back to fields that ARE collected (experienceLevel +
    /// painFrequency + injuryCountLastYear). Athletes who later
    /// fill in the explicit fields via profile-edit get more precise
    /// personalization; everyone else gets a defensible derivation.
    static func from(
        athlete: Athlete,
        ultraFinishCount: Int = 0,
        recentRuns: [CompletedRun] = [],
        estimatedLongRunPaceSecondsPerKm: Double = 450, // 7:30 min/km
        now: Date = .now
    ) -> PersonalizationProfile {
        // Use explicit runningYears when set; otherwise infer from
        // experience tier. Explicit > inferred so power users can
        // refine via profile-edit later.
        let effectiveYears: Double = athlete.runningYears > 0
            ? athlete.runningYears
            : yearsProxy(for: athlete.experienceLevel)

        let tenure = tenureMultiplier(years: effectiveYears)
        let weight = weightMultiplier(weightKg: athlete.weightKg)
        let ultra = ultraExperienceMultiplier(count: ultraFinishCount)
        let vgDensity = vgDensityMultiplier(years: effectiveYears, ultraCount: ultraFinishCount)
        let injuryPenalty = computeInjuryVolumeCapPenalty(
            painFrequency: athlete.painFrequency,
            injuryCount: athlete.injuryCountLastYear,
            structures: athlete.injuryStructures
        )

        let cap: TimeInterval?
        if athlete.longestRunKm > 0 {
            // Allow 20% above what they've demonstrated. This is the
            // "stretch but don't fabricate" bound from coaching practice.
            cap = athlete.longestRunKm * 1.20 * estimatedLongRunPaceSecondsPerKm
        } else {
            cap = nil
        }

        let recentPeak = computeRecentPeakWeeklyVolumeKm(
            runs: recentRuns,
            now: now
        )

        return PersonalizationProfile(
            tenureMultiplier: tenure,
            weightMultiplier: weight,
            ultraExperienceMultiplier: ultra,
            vgDensityMultiplier: vgDensity,
            historicalLongRunCapSeconds: cap,
            recentPeakWeeklyVolumeKm: recentPeak,
            injuryStructures: athlete.injuryStructures,
            injuryVolumeCapPenalty: injuryPenalty
        )
    }

    /// Aggregates running activities from the last `windowDays` into
    /// ISO weekly buckets and returns the maximum weekly km. Returns
    /// nil when fewer than `minWeeks` of data are available — peaks
    /// from a thin history aren't reliable signal.
    ///
    /// Only running activities (`run` / `trailRunning`) with positive
    /// distance are counted. Cross-training and gear-only logs are
    /// ignored — the goal is demonstrated *running* capacity.
    static func computeRecentPeakWeeklyVolumeKm(
        runs: [CompletedRun],
        now: Date = .now,
        windowDays: Int = 90,
        minWeeks: Int = 4
    ) -> Double? {
        guard let windowStart = Calendar.current.date(
            byAdding: .day, value: -windowDays, to: now
        ) else { return nil }

        let runningOnly = runs.filter {
            $0.isRunningActivity
                && $0.date >= windowStart
                && $0.date <= now
                && $0.distanceKm > 0
        }

        let calendar = Calendar.current
        var weekTotals: [Date: Double] = [:]
        for run in runningOnly {
            guard let weekStart = calendar.dateInterval(
                of: .weekOfYear, for: run.date
            )?.start else { continue }
            weekTotals[weekStart, default: 0] += run.distanceKm
        }

        guard weekTotals.count >= minWeeks else { return nil }
        return weekTotals.values.max()
    }

    /// Proxy mapping from experience tier → years of consistent
    /// running. Used as a default when `runningYears` is unset (the
    /// onboarding flow doesn't ask for years today). Mapping picks
    /// the centre of each tier's typical range so the corresponding
    /// `tenureMultiplier` lands on the expected bracket:
    ///   .beginner     → 1.0 yrs → 0.95 multiplier
    ///   .intermediate → 4.0 yrs → 1.00 multiplier
    ///   .advanced     → 9.0 yrs → 1.05 multiplier
    ///   .elite        → 16.0 yrs → 1.10 multiplier
    static func yearsProxy(for level: ExperienceLevel) -> Double {
        switch level {
        case .beginner:     return 1.0
        case .intermediate: return 4.0
        case .advanced:     return 9.0
        case .elite:        return 16.0
        }
    }

    /// Volume-cap dampening from the athlete's injury profile.
    /// Composes the FREQUENCY (painFrequency: never/rarely/sometimes/
    /// often) with the COUNT (injuryCountLastYear: none/one/two/3+)
    /// — both already collected at onboarding — plus an optional
    /// refinement from `injuryStructures` if the athlete has
    /// explicitly flagged structures via profile-edit.
    /// Hard floor at -2.0% so even the worst-case injury profile
    /// doesn't completely cripple the volume cap.
    ///
    /// Worst case: often (-1.0) + 3+ (-0.75) + 4 structures (-1.0)
    /// = -2.75 → clamped to -2.0
    /// Common: rarely (-0.25) + one (-0.25) = -0.5
    /// Healthy: never (0) + none (0) = 0
    static func computeInjuryVolumeCapPenalty(
        painFrequency: PainFrequency,
        injuryCount: InjuryCount,
        structures: Set<InjuryStructure>
    ) -> Double {
        var penalty = 0.0
        switch painFrequency {
        case .never:     penalty += 0
        case .rarely:    penalty += -0.25
        case .sometimes: penalty += -0.5
        case .often:     penalty += -1.0
        }
        switch injuryCount {
        case .none:        penalty += 0
        case .one:         penalty += -0.25
        case .two:         penalty += -0.5
        case .threeOrMore: penalty += -0.75
        }
        // Specific structures add a small additional penalty on top —
        // capped contribution so this stays a refinement signal.
        let structureCount = min(structures.count, 4)
        penalty += -0.25 * Double(structureCount)
        return max(penalty, -2.0)
    }

    static func tenureMultiplier(years: Double) -> Double {
        switch years {
        case ..<1:    return 0.92
        case ..<3:    return 0.95
        case ..<7:    return 1.00
        case ..<15:   return 1.05
        default:      return 1.10
        }
    }

    static func weightMultiplier(weightKg: Double) -> Double {
        switch weightKg {
        case ..<70:  return 1.03
        case ..<85:  return 1.00
        default:     return 0.93
        }
    }

    static func ultraExperienceMultiplier(count: Int) -> Double {
        switch count {
        case ..<1:   return 0.95
        case 1...2:  return 1.00
        case 3...4:  return 1.05
        default:     return 1.10
        }
    }

    /// Vertical-gain density multiplier for trail plans. Composes
    /// running tenure (proxy for general aerobic + tendon tolerance)
    /// with ultra finish count (proxy for actual mountain experience),
    /// hard-clamped to [0.85, 1.20]. The clamp keeps even an
    /// extremely experienced mountain runner inside a sensible band
    /// — VG density above 1.20× of the curve approaches race-day
    /// stress in training, which is the wrong trade-off.
    ///
    /// True climbing-specific signals (recent peak D+/km in actual
    /// training history, weekly vertical hours) are deferred to
    /// Personalization v2 alongside `recentPeakHours` and the
    /// adaptation signal.
    static func vgDensityMultiplier(years: Double, ultraCount: Int) -> Double {
        var mult = 1.0
        // Tenure proxy: more years = better tendon/ligament tolerance
        // for steep + sustained climbing
        switch years {
        case ..<3:  mult *= 0.92
        case ..<7:  mult *= 1.00
        default:    mult *= 1.05
        }
        // Ultra-mountain count proxy: athletes who've finished mountain
        // ultras have demonstrated they tolerate sustained vertical
        switch ultraCount {
        case ..<1:  mult *= 0.95
        case 1...2: mult *= 1.00
        case 3...4: mult *= 1.05
        default:    mult *= 1.10
        }
        return max(0.85, min(1.20, mult))
    }
}
