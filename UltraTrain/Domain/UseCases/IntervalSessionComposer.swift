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
        /// The sibling quality session's shape this week (Q1's shape when
        /// composing Q2). The chosen shape avoids it so a week never runs two
        /// pyramids / two cutdowns / etc. nil for Q1 (nothing to avoid yet).
        var avoidShape: Shape? = nil
        /// Per-(athlete, race) phase offset for the rep-length menus and shape
        /// rotation. Two similar athletes — or the same athlete's next prep
        /// (a new race) — start the rotations at a different point, so the
        /// hardest-week dose is 8×1K for one and 4×2K for another even though
        /// the total work is identical. Stable for a given prep (deterministic
        /// regeneration); derived from the race + athlete id by the generator.
        var varietySeed: Int = 0
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
        /// The shape used, so the generator can pass it as the sibling's
        /// `avoidShape` when composing the week's other quality session.
        let shape: Shape
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

    /// Avalanche hash of (seed, salt) → a decorrelated phase offset per
    /// call site. Adding the raw seed to several small menus (size 3-5) would
    /// let two preps collide whenever the seeds merely agree mod ~60; mixing
    /// with a per-menu salt makes a full-plan collision astronomically rare,
    /// so the same athlete's next prep is reliably different. Deterministic
    /// (pure arithmetic) so a given prep always reproduces.
    static func mix(_ seed: Int, _ salt: Int) -> Int {
        var z = UInt64(bitPattern: Int64(seed)) &+ (UInt64(bitPattern: Int64(salt)) &* 0x9E37_79B9_7F4A_7C15)
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z = z ^ (z >> 31)
        return Int(z & 0x7FFF_FFFF)
    }

    // MARK: - Shape selection

    private static func chooseShape(_ ctx: Context) -> Shape {
        let candidate = candidateShape(ctx)
        // Q1 and Q2 must not share a shape the same week (no week of two
        // pyramids / two cutdowns). When the natural pick collides with the
        // sibling's shape, fall to the next valid shape for this category.
        guard let avoid = ctx.avoidShape, candidate == avoid else { return candidate }
        let pool = shapePool(ctx)
        return pool.first { $0 != avoid } ?? candidate
    }

    /// The natural shape for this session before sibling de-confliction.
    private static func candidateShape(_ ctx: Context) -> Shape {
        // Threshold is the road runner's bread-and-butter, most often a
        // sustained TEMPO rather than reps. Q1 (the hard slot) keeps it as
        // cruise intervals so it complements the Q2 tempo (otherwise HM weeks,
        // threshold on both slots, end up with two tempos). Q2 (the tempo
        // slot) alternates a sustained tempo with a cruise variant so the week
        // reliably carries one true tempo and never repeats two thresholds.
        // The variety seed phase-shifts every rotation (via a decorrelated
        // mix) so two similar athletes — or the same athlete's next prep —
        // get different shapes, while a given prep stays deterministic.
        if ctx.category == .threshold {
            let reps: [Shape] = [.uniform, .cutdown, .mixedContrast]
            let n = ctx.ordinal + mix(ctx.varietySeed, 8000 + ctx.slotIndex)
            if ctx.slotIndex == 0 {
                return reps[n % reps.count]
            }
            if n % 2 == 0 { return .progression }
            return reps[(n / 2) % reps.count]
        }
        let valid = validShapes(for: ctx.category, phase: ctx.phase)
        // Rotate by ordinal so successive sessions of a category differ;
        // salt by slot so Q1 and Q2 tend to diverge the same week.
        let salt = ctx.slotIndex * 2 + categorySalt(ctx.category)
        let off = mix(ctx.varietySeed, 7000 + categorySalt(ctx.category) * 10 + ctx.slotIndex)
        return valid[(ctx.ordinal + salt + off) % valid.count]
    }

    /// Shapes available for a category, used to pick an alternative when the
    /// natural shape collides with the sibling's.
    private static func shapePool(_ ctx: Context) -> [Shape] {
        ctx.category == .threshold
            ? [.progression, .uniform, .cutdown, .mixedContrast]
            : validShapes(for: ctx.category, phase: ctx.phase)
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
