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

        // Daniels: long run ≤ 2.5 hours regardless of distance
        let absoluteMax: TimeInterval = switch experience {
        case .beginner:     9000  // 2h30
        case .intermediate: 9000  // 2h30
        case .advanced:     9900  // 2h45
        case .elite:        10800 // 3h00
        }
        let capDuration = min(maxDurationSeconds, absoluteMax)

        // Starting long run: 40-55% of cap.
        // Pfitzinger 18/55 starts at ~47% of peak, 18/70 at ~50%.
        // Beginners start lower to allow more gradual ramp (Lydiard principle).
        let startFraction: Double = switch experience {
        case .beginner:     0.42
        case .intermediate: 0.48
        case .advanced:     0.52
        case .elite:        0.55
        }
        // Issue #5: Minimum long run by experience (60min too much for 10K beginner)
        let minimumLongRun: TimeInterval = switch experience {
        case .beginner:     2400  // 40 min
        case .intermediate: 3000  // 50 min
        case .advanced:     3600  // 60 min
        case .elite:        3600  // 60 min
        }
        let startDuration = max(capDuration * startFraction, minimumLongRun)

        // Quadratic ramp: reaches peak ~80% through the plan
        let peakWeek = Int(Double(totalWeeks) * 0.80)
        let progress: Double
        if weekIndex <= peakWeek {
            let t = Double(weekIndex) / max(Double(peakWeek), 1.0)
            progress = t * (2.0 - t) // Quadratic ease-out
        } else {
            progress = 1.0 // Hold at peak (taper handles reduction)
        }

        var duration = startDuration + (capDuration - startDuration) * progress

        // Recovery week: reduce by 22% (Pfitzinger: 75-80% of load week long run)
        if isRecoveryWeek {
            duration *= 0.78
        }

        // Taper: keep 60% of current duration (40% reduction per Mujika 2003)
        if phase == .taper {
            duration *= 0.60
        }

        return round(duration / 300) * 300 // Round to nearest 5 min
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
