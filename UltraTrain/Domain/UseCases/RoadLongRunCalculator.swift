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
        /// Pure easy pace — base building, time on feet.
        case easy
        /// Start easy, build to ~90% race pace in final third.
        case progressive
        /// Easy until last 20-25%, then surge to race pace.
        case fastFinish
        /// Embed 2-3 blocks of marathon pace mid-run (Canova).
        case marathonPaceBlocks
        /// First half easy, second half at race pace.
        case twoPart
        /// Full race simulation: 15-20km at race pace within a longer run.
        case raceSimulation
    }

    // MARK: - Long Run Duration

    /// Calculates long run duration for a given week in a road plan.
    ///
    /// Uses a quadratic ramp up to peak, then holds or tapers.
    /// Duration is capped by distance (road-specific) and experience.
    static func longRunDuration(
        weekIndex: Int,
        totalWeeks: Int,
        phase: TrainingPhase,
        experience: ExperienceLevel,
        raceDistanceKm: Double,
        currentWeeklyVolumeKm: Double,
        currentLongestRunKm: Double,
        isRecoveryWeek: Bool
    ) -> TimeInterval {
        let discipline = RoadRaceDiscipline.from(distanceKm: raceDistanceKm)
        let maxDistanceKm = discipline.longRunCapKm(experience: experience)

        // Convert max distance to duration using experience-based pace
        let avgPaceSecPerKm: Double = switch experience {
        case .beginner:     370  // ~6:10/km
        case .intermediate: 330  // ~5:30/km
        case .advanced:     295  // ~4:55/km
        case .elite:        265  // ~4:25/km
        }
        let maxDurationSeconds = maxDistanceKm * avgPaceSecPerKm

        // Daniels' "≤ 2.5 h" rule is a beginner-era guideline. Pfitzinger's
        // intermediate and advanced plans routinely prescribe 18-22 mile long
        // runs that take 3:00-3:20 at the athlete's declared easy pace. If we
        // cap at 2:30 for everyone, the stated 32 km intermediate marathon
        // long run is mathematically unreachable (would need 4:40/km easy pace).
        // Raise the cap by tier so distance caps are actually achievable.
        let absoluteMax: TimeInterval = switch experience {
        case .beginner:     9000   // 2h30 — keep conservative (injury prevention)
        case .intermediate: 10800  // 3h00 — allows 32 km at 5:36/km intermediate easy pace
        case .advanced:     12000  // 3h20 — allows 35 km at 5:40/km or 22-mi Pfitz 18/70
        case .elite:        12600  // 3h30 — ultra-capable though usually used road
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

        // RR-1: Anchor the starting long run to the athlete's current
        // longest run when declared. Safer than a generic tier-based start
        // because it respects the BJSM 2018 rule: never exceed the athlete's
        // longest run by more than ~10% in a single week.
        //
        // - `currentLongestRunKm <= 0` → fall back to tier default.
        // - Anchor at 90% of declared longest (10% safety buffer).
        // - Clamp to [minimumLongRun, capDuration * 0.85] so there's still
        //   headroom to grow across the block.
        let startDuration: TimeInterval
        if currentLongestRunKm > 0 {
            let proposedAnchor = currentLongestRunKm * 0.9 * avgPaceSecPerKm
            let maxAnchor = capDuration * 0.85
            startDuration = max(minimumLongRun, min(proposedAnchor, maxAnchor))
        } else {
            startDuration = max(capDuration * startFraction, minimumLongRun)
        }

        // Quadratic ramp reaches peak just before taper starts (~88% of plan).
        // Old value 0.80 caused a 3-4 week long-run plateau during the peak
        // phase (W19 onward at same duration). Pushing the peak to 0.88 keeps
        // the long run growing through almost all peak-phase weeks before the
        // taper reduction kicks in.
        let peakWeek = Int(Double(totalWeeks) * 0.88)
        let progress: Double
        if weekIndex <= peakWeek {
            let t = Double(weekIndex) / max(Double(peakWeek), 1.0)
            progress = t * (2.0 - t) // Quadratic ease-out
        } else {
            progress = 1.0 // Hold at peak (taper handles reduction)
        }

        var duration = startDuration + (capDuration - startDuration) * progress

        // Recovery week: reduce by 15% (Pfitzinger: 80-85% of load week long run)
        if isRecoveryWeek {
            duration *= 0.85
        }

        // Taper: keep 60% of current duration (40% reduction per Mujika 2003)
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
            // Base: easy long runs. Introduce progressive in late base for experienced.
            if weekInPhase >= 2 && experience != .beginner {
                return .progressive
            }
            return .easy

        case .build:
            // Build: alternate progressive and fast-finish
            return weekInPhase.isMultiple(of: 2) ? .progressive : .fastFinish

        case .peak:
            // Peak: race-specific variants based on discipline
            switch discipline {
            case .road10K:
                // 10K: fast-finish long runs (final 4-5km at 10K pace)
                return .fastFinish

            case .roadHalf:
                // HM: alternate progressive and two-part
                return weekInPhase.isMultiple(of: 2) ? .twoPart : .progressive

            case .roadMarathon:
                // Marathon: Canova-style MP block long runs
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
