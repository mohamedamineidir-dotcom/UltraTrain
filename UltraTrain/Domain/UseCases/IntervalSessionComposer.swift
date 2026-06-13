import Foundation

/// Parametric composer for road quality (interval / tempo / race-pace)
/// sessions. Replaces the fixed-template pick (`RoadIntervalLibrary
/// .selectForSlot`) so every quality session is COMPOSED from the athlete's
/// profile + block progression instead of chosen from a finite menu — the
/// way Campus Coach / Pfitzinger / Daniels actually periodise quality work.
///
/// Principles (from the Campus Coach analysis):
///  1. Hold the block's target pace constant (from the athlete's
///     `RoadPaceProfile`); pace drifts only with fitness, never per session.
///  2. Progress the WORK ORGANISATION each session — rep count → rep length →
///     recovery ratio — walking up a difficulty coordinate (the per-category
///     session `ordinal`).
///  3. Vary the SHAPE (uniform / pyramid / cutdown / mixed-contrast /
///     progression) so consecutive sessions never share a work part.
///  4. Scale total work to the athlete's weekly volume + experience
///     (Daniels: VO2max ≈ 6-8% of weekly km, threshold ≈ 8-10%).
///  5. Recovery weeks → strides / short mixed primer.
enum IntervalSessionComposer {

    // MARK: - Public types

    struct Context: Sendable {
        let category: RoadIntervalLibrary.Category
        let phase: TrainingPhase
        let discipline: RoadRaceDiscipline
        let experience: ExperienceLevel
        let weeklyVolumeKm: Double
        let paceProfile: RoadPaceProfile?
        /// Monotonic per-category session counter (0-based). The progression
        /// coordinate; recovery weeks do NOT increment it, so the build
        /// resumes where it left off after a deload (like Campus Coach).
        let ordinal: Int
        /// Slot 0 (Q1, the week's hardest) vs slot 1 (Q2). Salts the shape
        /// rotation so the two weekly quality sessions never align.
        let slotIndex: Int
        let isRecoveryWeek: Bool
        let isFirstTimer: Bool
        let athleteAge: Int
    }

    struct Composed: Sendable {
        let workout: IntervalWorkout
        /// Stable structural fingerprint, used by the generator to guarantee
        /// no two quality sessions in a plan share an identical work part.
        let signature: String
        /// Category display name for the session purpose line.
        let focus: String
        /// A synthesized library template matching the composed primary
        /// segment, so existing downstream code (intervalFocus label, coach
        /// advice pace selection) keeps working without change.
        let template: RoadIntervalLibrary.Template
        /// True when the work is a sustained continuous effort (one or two
        /// long blocks at threshold / marathon pace) — a genuine *tempo*.
        /// Rep-based shapes (uniform reps, pyramid, cutdown, mixed-contrast)
        /// are *intervals*. The generator types the session from this so a
        /// "5×1K" never shows under a "Tempo" title and vice-versa.
        let isTempo: Bool
    }

    enum Shape: Int, CaseIterable, Sendable {
        case uniform, pyramid, cutdown, mixedContrast, progression
    }

    // MARK: - Internal work model

    /// One homogeneous block of reps. A workout is one or more segments
    /// (a uniform session is a single segment; a pyramid / mixed-contrast is
    /// several). `repDistanceM == 0` means the rep is time-based.
    struct Segment: Sendable, Equatable {
        var repCount: Int
        var repDistanceM: Int
        var repDurationSec: Int
        var zone: RoadIntervalLibrary.PaceZone
        var recoverySec: Int
        var recoveryType: RoadIntervalLibrary.RecoveryType
    }

    // MARK: - Entry point

    static func compose(_ ctx: Context) -> Composed {
        let segments: [Segment]
        let shape: Shape
        if ctx.isRecoveryWeek {
            segments = recoverySegments(ctx)
            shape = .uniform
        } else {
            shape = chooseShape(ctx)
            segments = plan(ctx, shape: shape)
        }
        return render(ctx, segments: segments, shape: shape)
    }

    // MARK: - Shape selection

    private static func chooseShape(_ ctx: Context) -> Shape {
        // Threshold is the road runner's bread-and-butter, and it's most
        // often prescribed as a sustained TEMPO, not reps. So alternate the
        // threshold slot between a continuous tempo (progression) and a
        // rep variant every other session: each block reads tempo ⇄ cruise
        // intervals, the week reliably carries one true tempo, and structure
        // never repeats two threshold sessions running.
        if ctx.category == .threshold {
            let reps: [Shape] = [.uniform, .cutdown, .mixedContrast]
            // Q1 is the week's hard interval slot: keep threshold as cruise
            // intervals so it complements (not duplicates) the Q2 tempo —
            // otherwise half-marathon weeks, where both slots lean threshold,
            // end up with two tempos and no interval variety.
            if ctx.slotIndex == 0 {
                return reps[ctx.ordinal % reps.count]
            }
            // Q2 is the tempo slot: alternate a sustained tempo with a cruise
            // variant so the week reliably carries one true tempo and the
            // structure never repeats two threshold sessions running.
            if ctx.ordinal % 2 == 0 { return .progression }
            return reps[(ctx.ordinal / 2) % reps.count]
        }
        let valid = validShapes(for: ctx.category, phase: ctx.phase)
        // Rotate by ordinal so successive sessions of a category differ;
        // salt by slot so Q1 and Q2 never use the same shape the same week.
        let salt = ctx.slotIndex * 2 + categorySalt(ctx.category)
        let idx = (ctx.ordinal + salt) % valid.count
        return valid[idx]
    }

    private static func validShapes(for category: RoadIntervalLibrary.Category,
                                    phase: TrainingPhase) -> [Shape] {
        switch category {
        case .speed:          return [.uniform, .cutdown]
        case .vo2max:         return [.uniform, .pyramid, .cutdown]
        case .threshold:      return [.uniform, .cutdown, .mixedContrast, .progression]
        case .raceSpecific:   return [.uniform, .pyramid, .progression]
        case .progression:    return [.progression]
        case .longRunVariant: return [.uniform]
        }
    }

    private static func categorySalt(_ c: RoadIntervalLibrary.Category) -> Int {
        switch c {
        case .speed: return 0
        case .vo2max: return 1
        case .threshold: return 2
        case .raceSpecific: return 3
        case .progression: return 4
        case .longRunVariant: return 0
        }
    }

    // MARK: - Recovery-week sessions

    private static func recoverySegments(_ ctx: Context) -> [Segment] {
        if ctx.slotIndex == 0 {
            // Strides primer (Campus Coach week-5 pattern: 6×15-20s fast).
            return [Segment(repCount: 6, repDistanceM: 0, repDurationSec: 20,
                            zone: .repetition, recoverySec: 60, recoveryType: .walk)]
        }
        // Short mixed primer touching tempo + threshold (light, 1:2 work:rest).
        return [
            Segment(repCount: 4, repDistanceM: 0, repDurationSec: 60,
                    zone: .marathonPace, recoverySec: 60, recoveryType: .jog),
            Segment(repCount: 3, repDistanceM: 0, repDurationSec: 60,
                    zone: .threshold, recoverySec: 60, recoveryType: .jog)
        ]
    }
}
