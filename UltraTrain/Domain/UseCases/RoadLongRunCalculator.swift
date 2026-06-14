import Foundation

/// Calculates road-specific long run duration, distance caps, and structured variants.
///
/// Research basis:
/// - **Pfitzinger**: Marathon long runs peak at 32-35km (20-22mi). HM at 22-24km.
///   Progressive long runs build from easy to race pace.
/// - **Daniels**: Long runs should not exceed 25% of weekly mileage (or 2.5 hours).
///   Quality within long runs (MP blocks) in peak phase only.
/// - **Canova**: Alternating long run = marathon-specific endurance builder.
///   Start with E pace, insert MP blocks, return to E. Extend blocks weekly.
/// - **Hanson**: Marathon long runs capped at 26km (16mi) because cumulative fatigue
///   from weekly mileage simulates end-of-race conditions.
enum RoadLongRunCalculator {

    /// Structured long run variants for road training.
    enum LongRunVariant: String, Sendable {
        /// Pure easy pace, base building, time on feet.
        case easy
        /// Start easy, build to ~90% race pace in final third.
        case progressive
        /// Easy until last 20-25%, then surge to race pace.
        case fastFinish
        /// Late-build marathon variant: single 15-20 min MP block embedded
        /// near the end of an otherwise easy long run. Bridges progressive
        /// long runs and the full peak-phase MP-block sessions, so the
        /// athlete's first marathon-pace exposure isn't `5×3 km @ 103% MP`.
        case marathonPaceIntro
        /// Embed 2-3 blocks of marathon pace mid-run (Canova).
        case marathonPaceBlocks
        /// First half easy, second half at race pace.
        case twoPart
        /// Full race simulation: 15-20km at race pace within a longer run.
        case raceSimulation

        /// Short user-facing label used as a pill on the long-run row.
        /// Returns nil for `.easy` because a plain easy long run doesn't
        /// need a tag, only structured variants benefit from the badge.
        var displayLabel: String? {
            switch self {
            case .easy:               return nil
            case .progressive:        return "Progressive"
            case .fastFinish:         return "Fast Finish"
            case .marathonPaceIntro:  return "MP Intro"
            case .marathonPaceBlocks: return "MP Blocks"
            case .twoPart:            return "Two-Part"
            case .raceSimulation:     return "Race Sim"
            }
        }
    }

    // MARK: - Long Run Duration

    /// Calculates long run duration for a given week in a road plan.
    ///
    /// Uses a quadratic ramp up to peak, then holds or tapers.
    /// Duration is capped by distance (road-specific), experience,
    /// philosophy, and goal, a performance-mode targetRanking marathoner
    /// gets a longer LR cap than an enjoyment-mode finisher even at the
    /// same experience tier.
    static func longRunDuration(
        weekIndex: Int,
        totalWeeks: Int,
        phase: TrainingPhase,
        experience: ExperienceLevel,
        raceDistanceKm: Double,
        currentLongestRunKm: Double,
        isRecoveryWeek: Bool,
        philosophy: TrainingPhilosophy = .balanced,
        raceGoal: RaceGoal = .targetTime(0),
        weeklyVolumeKm: Double = 0,
        taperWeeks: Int = 3,
        thresholdPacePerKm: Double? = nil
    ) -> TimeInterval {
        let discipline = RoadRaceDiscipline.from(distanceKm: raceDistanceKm)
        let maxDistanceKm = discipline.longRunCapKm(
            experience: experience,
            philosophy: philosophy,
            raceGoal: raceGoal
        )

        // Long-run / easy pace. When the athlete has a measured threshold
        // pace we derive long-run pace from it (Daniels: L ≈ T + 30-45 s/km;
        // Pfitzinger: LR pace ≈ MP + 30-45 s/km; Magness / Hudson: long
        // run = 30-60 s/km slower than threshold). Using a fixed
        // ~35 s/km offset puts the LR right in the middle of consensus.
        // Without threshold data we fall back to a tier-based default
        // imperfect, but it's a cold-start signal and gets replaced as
        // soon as the athlete provides a PR or VMA.
        //
        // Effect on the duration cap: a 2:45-marathon advanced athlete
        // with a ~4:00 /km threshold gets a 35 km long-run cap at
        // (240 + 35) × 35 = 2h40; a 3:30-marathon advanced athlete with
        // a ~4:35 /km threshold gets the same 35 km at
        // (275 + 35) × 35 = 3h01. Same prescribed distance, time scales
        // with the athlete's actual pace instead of being forced to a
        // tier average.
        let avgPaceSecPerKm: Double = {
            if let t = thresholdPacePerKm, t > 0 {
                return t + 35
            }
            switch experience {
            case .beginner:     return 370  // ~6:10/km
            case .intermediate: return 330  // ~5:30/km
            case .advanced:     return 295  // ~4:55/km
            case .elite:        return 265  // ~4:25/km
            }
        }()
        let maxDurationSeconds = maxDistanceKm * avgPaceSecPerKm

        // Daniels' "≤ 2.5 h" rule is a beginner-era guideline. Pfitzinger's
        // intermediate and advanced plans routinely prescribe 18-22 mile long
        // runs that take 3:00-3:20 at the athlete's declared easy pace. If we
        // cap at 2:30 for everyone, the stated 32 km intermediate marathon
        // long run is mathematically unreachable (would need 4:40/km easy pace).
        // Raise the cap by tier so distance caps are actually achievable.
        let absoluteMax: TimeInterval = switch experience {
        case .beginner:     9000   // 2h30, keep conservative (injury prevention)
        case .intermediate: 10800  // 3h00, allows 32 km at 5:36/km intermediate easy pace
        case .advanced:     12000  // 3h20, allows 35 km at 5:40/km or 22-mi Pfitz 18/70
        case .elite:        12600  // 3h30, ultra-capable though usually used road
        }
        let capDuration = min(maxDurationSeconds, absoluteMax)

        // Starting long run: 40-55% of cap (tier default, used only when the
        // athlete hasn't declared a longestRunKm in onboarding).
        // Pfitzinger 18/55 starts at ~47% of peak, 18/70 at ~50%.
        let startFraction: Double = switch experience {
        case .beginner:     0.42
        case .intermediate: 0.48
        case .advanced:     0.52
        case .elite:        0.55
        }
        // Minimum long run by experience (60min too much for 10K beginner)
        let minimumLongRun: TimeInterval = switch experience {
        case .beginner:     2400  // 40 min
        case .intermediate: 3000  // 50 min
        case .advanced:     3600  // 60 min
        case .elite:        3600  // 60 min
        }

        // RR-1 / RR-9 / RR-11: Anchor the starting long run to the athlete's
        // current longest run when declared. Safer than a generic tier-based
        // start because it respects the BJSM 2018 rule: never exceed the
        // athlete's longest run by more than ~10% in a single week.
        //
        // - `currentLongestRunKm <= 0` (no data) → fall back to tier default
        //   (capDuration × startFraction, floored at the tier minimum so we
        //   don't prescribe a trivial long run for a beginner with no signal).
        // - Declared > 0 → anchor at 90% of declared (10% safety buffer), then
        //   cap at 60% of capDuration so there's room to grow toward peak
        //   (Pfitzinger 18/55 starts at ~12 mi vs 20 mi peak = 60%).
        //
        // RR-11: when a value is declared we no longer clamp up to the tier
        // `minimumLongRun` floor. A beginner declaring 5 km longest was
        // being bumped to 40 min (~6.5 km), a 30% jump on Week 1, exactly
        // what the BJSM 10% rule is supposed to prevent. Instead we use a
        // sanity floor of 15 min so the session is still distinct from an
        // easy run, but we respect declared base down to that floor.
        let startDuration: TimeInterval
        if currentLongestRunKm > 0 {
            let proposedAnchor = currentLongestRunKm * 0.9 * avgPaceSecPerKm
            let maxAnchor = capDuration * 0.60
            // Weekly-volume sanity cap: an athlete who declared
            // longestRunKm = 105 with weeklyVolumeKm = 40 has a
            // longest run that's 2.6× their weekly volume, almost
            // certainly trail/ultra history bleeding into a road
            // plan. Anchoring an LR at 21+ km in week 1 of a 40-
            // km/wk plan crushes every other session because the
            // remaining weekly budget can't be split across 4 easy
            // runs + 1 quality. Cap the anchor at 35% of weekly
            // volume so the LR stays a sensible fraction of the
            // week (Daniels' "≤25% of weekly mileage" guideline
            // applied as a slightly looser ceiling). When
            // weeklyVolumeKm isn't supplied (older callers, tests),
            // skip the cap and use the 60%-of-cap rule alone.
            let weeklyVolumeBasedCap: TimeInterval
            if weeklyVolumeKm > 0 {
                weeklyVolumeBasedCap = weeklyVolumeKm * 0.35 * avgPaceSecPerKm
            } else {
                weeklyVolumeBasedCap = .infinity
            }
            let sanityFloor: TimeInterval = 900 // 15 min, below this it's not a long run
            startDuration = max(sanityFloor, min(proposedAnchor, maxAnchor, weeklyVolumeBasedCap))
        } else {
            startDuration = max(capDuration * startFraction, minimumLongRun)
        }

        // RR-26: Place the LR peak 3-4 weeks BEFORE taper, then plateau.
        //
        // Pfitzinger Adv. Marathoning Ch. 9: "the last very long run must
        // precede taper by at least 3 weeks." Daniels 2Q peak LRs sit
        // 2-4 weeks pre-race. Canova: last specific block at the 40-day
        // window. Hudson: the 4th-week cutback is mandatory; longest LR
        // never sits adjacent to taper.
        //
        // Old behavior anchored the peak at 88% of total weeks, which
        // for a 23-week marathon plan placed the peak LR at the LAST
        // non-taper week, exactly the antipattern these systems warn
        // against. The athlete entered taper carrying acute fatigue
        // from the hardest run of the cycle, leaving the taper to clear
        // fatigue instead of sharpening.
        //
        // New behavior: ramp quadratically up to peakWeek = taperStart -
        // plateauOffset, then HOLD at peak through the remaining peak
        // weeks before taper. Recovery weeks within the plateau still
        // apply ×0.85 (natural cutback); taper still applies ×0.60.
        // Athlete sees the peak LR multiple times before the taper, then
        // the taper drop. plateauOffset scales with plan length so short
        // plans don't get a degenerate plateau.
        let taperStart = max(totalWeeks - taperWeeks, 1)
        // B7: plateauOffset is experience-aware so the LR peak lands
        // closer to taper for stronger athletes (Pfitzinger 18/85: peak
        // LR W15 of W18 = 3 weeks before race) while beginners keep the
        // conservative 4-week buffer. Mirrors RoadVolumeCalculator so
        // volume + LR peaks stay locked together.
        let baseOffset = min(4, max(1, totalWeeks / 5))
        let experienceOffsetAdjustment: Int = switch experience {
        case .beginner:      0
        case .intermediate: -1
        case .advanced:     -2
        case .elite:        -2
        }
        let plateauOffset = max(2, baseOffset + experienceOffsetAdjustment)
        let peakWeek = max(taperStart - plateauOffset, 1)
        let progress: Double
        if weekIndex <= peakWeek {
            let t = Double(weekIndex) / max(Double(peakWeek), 1.0)
            progress = t * (2.0 - t) // Quadratic ease-out
        } else {
            progress = 1.0 // Hold at peak, consolidation, not escalation
        }

        var duration = startDuration + (capDuration - startDuration) * progress

        // Recovery (deload) week: cut the long run ~28% so the whole week
        // troughs together with the non-LR sessions (RoadVolumeCalculator
        // cuts easy/quality to ~0.68/0.74 on the same week). A matching LR
        // cut is what makes the 3:1 sawtooth legible on the volume chart;
        // a token 15% LR cut left the deload nearly flat. The LR still owns
        // its independent taper shape (×0.60) below.
        if isRecoveryWeek {
            duration *= 0.72
        }

        // Taper: keep 60% of current duration (40% reduction per Mujika 2003).
        // M2 note: the long run owns its own taper shape, flat 60% across
        // every taper week. The non-LR sessions follow the TaperProfile's
        // per-week fractions in RoadVolumeCalculator. This is by design;
        // the two paths are deliberately decoupled so the LR doesn't get
        // double-cut by both ×0.60 here AND the per-week fraction there.
        if phase == .taper {
            duration *= 0.60
        }

        // Round to nearest 2 minutes (120s). 5-minute rounding erased small
        // week-to-week growth during peak phase.
        return round(duration / 120) * 120
    }

    // MARK: - Long Run Variant Selection

    /// Selects the appropriate long run variant based on phase, week, and distance.
    ///
    /// Progression across phases:
    /// - Base: all easy long runs (build aerobic foundation).
    /// - Build: introduce progressive and fast-finish variants.
    /// - Peak: race-specific variants (MP blocks, race simulation).
    /// - Taper: easy long runs only (recovery, confidence).
    static func variant(
        phase: TrainingPhase,
        weekInPhase: Int,
        raceDistanceKm: Double,
        experience: ExperienceLevel,
        isRecoveryWeek: Bool
    ) -> LongRunVariant {
        if isRecoveryWeek || phase == .taper { return .easy }

        let discipline = RoadRaceDiscipline.from(distanceKm: raceDistanceKm)

        switch phase {
        case .base:
            // Marathon non-beginners get an early single MP-block intro
            // in late base (weekInPhase ≥ 5 ≈ weeks 6-8 of a 24-week
            // plan), bridges into build's MP work without a hard
            // jump and gives the athlete a calibrated marathon-pace
            // exposure mid-base instead of waiting for late build.
            // Pfitzinger-style "tempo-finish long run" placement.
            // Beginners stay on .easy / .progressive; introducing MP
            // blocks before they've built threshold tolerance is
            // premature.
            if discipline == .roadMarathon && weekInPhase >= 5 && experience != .beginner {
                return .marathonPaceIntro
            }
            // Base: easy long runs. Introduce progressive in late base for experienced.
            if weekInPhase >= 2 && experience != .beginner {
                return .progressive
            }
            return .easy

        case .build:
            // Marathon: MP block introduction lowered from weekInPhase ≥ 3
            // to ≥ 1, the athlete already saw an MP intro in late base
            // (above) for marathon non-beginners, so the gap between MP
            // exposures stays consistent and there's no week-1 build
            // regression back to pure progressive runs.
            if discipline == .roadMarathon && weekInPhase >= 1 && experience != .beginner {
                return .marathonPaceIntro
            }
            // Build: alternate progressive and fast-finish
            return weekInPhase.isMultiple(of: 2) ? .progressive : .fastFinish

        case .peak:
            // Peak: race-specific variants based on discipline
            switch discipline {
            case .road5K, .road10K:
                // 5K/10K: fast-finish long runs (final 4-5km at race pace)
                return .fastFinish

            case .roadHalf:
                // HM: alternate progressive and fast-finish. NOT two-part —
                // half-marathon race pace is near threshold, so a "50% of the
                // long run at race pace" block is an hour-plus of racing, not
                // training. Fast-finish keeps the race-pace dose to the final
                // portion (and the builder caps it to ~half race distance).
                return weekInPhase.isMultiple(of: 2) ? .fastFinish : .progressive

            case .roadMarathon:
                // Marathon peak: variants by experience.
                //
                // Beginners (finish-mode novices) get a Pfitzinger-style
                // ramp: week 0 = .marathonPaceIntro (single 15-20min MP
                // block, gentle introduction to MP), then alternate
                // .fastFinish (last 20-25% at MP, textbook Pfitzinger
                // MP-finish long run) and .marathonPaceBlocks. Avoids
                // the audit's flagged issue of beginners hitting full
                // Canova 5×3km MP blocks in week 0 of peak.
                //
                // Intermediate gets the historical alternation between
                // .twoPart (50% easy + 50% race-pace) and
                // .marathonPaceBlocks. .twoPart is more appropriate
                // than .raceSimulation for the intermediate tier.
                //
                // Advanced/elite get .raceSimulation (15-20km at race
                // pace within a longer run) alternating with full
                // Canova blocks.
                if experience == .beginner {
                    if weekInPhase == 0 { return .marathonPaceIntro }
                    return weekInPhase.isMultiple(of: 2) ? .fastFinish : .marathonPaceBlocks
                }
                if weekInPhase == 0 {
                    return .marathonPaceBlocks
                } else if experience == .advanced || experience == .elite {
                    return weekInPhase.isMultiple(of: 2) ? .raceSimulation : .marathonPaceBlocks
                } else {
                    return weekInPhase.isMultiple(of: 2) ? .twoPart : .marathonPaceBlocks
                }
            }

        default:
            return .easy
        }
    }
}
