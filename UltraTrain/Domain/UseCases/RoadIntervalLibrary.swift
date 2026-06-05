import Foundation

/// Complete library of road-specific interval workout templates.
///
/// 6 categories based on physiological target:
/// A: Speed / Running Economy (R-pace), neuromuscular recruitment
/// B: VO2max Intervals (I-pace), aerobic power ceiling
/// C: Lactate Threshold (T-pace), sustainable speed
/// D: Race-Specific (RP/MP), race simulation
/// E: Progression Runs, aerobic power at high end
/// F: Long Run Variants, structured endurance builders
///
/// Research sources: Daniels (VDOT), Canova (extension of quality),
/// Pfitzinger (lactate threshold), Norwegian model (double-threshold),
/// Billat (30/30 VO2max), Ingebrigtsen system.
enum RoadIntervalLibrary {

    /// A workout template that can be instantiated with an athlete's pace profile.
    struct Template: Sendable {
        let name: String
        let category: Category
        let description: String
        let targetPaceZone: PaceZone
        let repDistanceM: Int        // 0 = continuous/duration-based
        let repCount: Int
        let recoverySeconds: Int
        let recoveryType: RecoveryType
        let totalWorkMinutes: Double // Estimated total work time
        let applicablePhases: Set<TrainingPhase>
        let applicableDistances: Set<RoadRaceDiscipline>
        let minExperience: ExperienceLevel
    }

    enum Category: String, Sendable {
        case speed, vo2max, threshold, raceSpecific, progression, longRunVariant

        /// Short human-readable label shown on the session card so the
        /// athlete can distinguish "Speed intervals" from "VO2max" or
        /// "Race-pace" intervals at a glance without opening the detail.
        /// Populated onto `TrainingSession.intervalFocus` at generation
        /// time by the road plan pipeline (RR-24).
        var displayName: String {
            switch self {
            case .speed:           return String(localized: "interval.category.speed", defaultValue: "Speed")
            case .vo2max:          return String(localized: "interval.category.vo2max", defaultValue: "VO2max")
            case .threshold:       return String(localized: "interval.category.threshold", defaultValue: "Threshold")
            case .raceSpecific:    return String(localized: "interval.category.racePace", defaultValue: "Race pace")
            case .progression:     return String(localized: "interval.category.progression", defaultValue: "Progression")
            case .longRunVariant:  return String(localized: "interval.category.longRun", defaultValue: "Long run")
            }
        }
    }

    enum PaceZone: String, Sendable {
        case easy, marathonPace, threshold, interval, repetition, racePace
    }

    enum RecoveryType: String, Sendable {
        case jog, walk, float, standing
    }

    // MARK: - Template Selection

    /// Returns appropriate templates for the given context.
    ///
    /// Templates only declare `.base`, `.build`, `.peak` in their
    /// `applicablePhases` set. Athletes still run light openers
    /// (intervals / tempo) in taper, post-race recovery and race-week
    /// shakeouts, and SessionTemplateGenerator emits those sessions with
    /// real descriptions, so the session-detail view expects a
    /// matching structured workout. Without a fallback the workout
    /// breakdown silently disappears and the athlete just sees prose.
    ///
    /// In those phases we fall back to base-phase templates: they are
    /// the lightest in the library (200m / 400m strides, short cruise
    /// intervals) and match what those weeks actually prescribe.
    static func templates(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel,
        weekInPhase: Int
    ) -> [Template] {
        let effectivePhase: TrainingPhase = {
            switch phase {
            case .taper, .recovery, .race: return .base
            default:                       return phase
            }
        }()
        return allTemplates.filter { template in
            template.applicablePhases.contains(effectivePhase)
            && template.applicableDistances.contains(discipline)
            && experience.rawSortOrder >= template.minExperience.rawSortOrder
        }
    }

    /// Selects a quality session template for the given slot.
    /// Slot 1 and slot 2 must be DIFFERENT categories (Daniels: variety principle).
    ///
    /// - Parameter isFirstTimerAtDistance: true when the athlete has no
    ///   prior PB at the race distance. First-timers stop one template
    ///   short of the hardest in each category, a first-time marathoner
    ///   should not be plateauing on `Double Tempo` (40 min total at
    ///   T-pace) just because the walk-forward index reached the end of
    ///   the threshold ladder.
    static func selectForSlot(
        slotIndex: Int,
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel,
        weekInPhase: Int,
        excludeCategory: Category? = nil,
        isFirstTimerAtDistance: Bool = false
    ) -> Template? {
        let available = templates(
            phase: phase, discipline: discipline,
            experience: experience, weekInPhase: weekInPhase
        ).filter { excludeCategory == nil || $0.category != excludeCategory }

        guard !available.isEmpty else { return nil }

        // Distance × phase × slot × week category preferences (Daniels, Pfitzinger, Canova)
        let preferred = categoryPreferences(
            phase: phase, discipline: discipline, slotIndex: slotIndex,
            weekInPhase: weekInPhase
        )

        // RR-16: Walk forward through the progression within a category,
        // plateau at the most-advanced template for weeks beyond the end.
        //
        // Templates within each category are sorted ascending by
        // `totalWorkMinutes` (a coarse but reliable difficulty proxy:
        // 800m → 1000m → 1200m → 1600m → 2000m for VO2max; short cruise
        // intervals → extended continuous tempo for threshold). Pfitzinger
        // and Daniels both use this pattern: progress weekly through
        // increasingly demanding workouts, then consolidate the top session
        // across remaining peak weeks.
        //
        // RR-25: Sorting is explicit. Earlier code relied on declaration
        // order, but `allTemplates` appends `auditTemplates` last, which
        // dropped lighter audit templates (e.g. Marathon Tempo 30min, 30
        // min) AFTER heavier originals (Marathon Pace 3K Blocks, 40 min)
        // in the same category. The walk-forward then handed week 0 the
        // heaviest session and weeks 1+ a lighter plateau, backwards
        // progression. Sorting by totalWorkMinutes guarantees ascending
        // difficulty regardless of where templates are declared.
        //
        // First-timers cap one short of the hardest template, they get
        // the progression up to the second-to-last template and plateau
        // there, instead of seeing repeated weeks of the toughest session
        // their experience tier unlocks.
        //
        // RR-27: Each category preference carries an introduction week.
        // Most categories are live from weekInPhase 0, but some are
        // introduced mid-phase (e.g. marathon raceSpecific in late build,
        // weekInPhase >= 3). Without an offset, those late-introduced
        // categories pin every week to the cap (3 weeks of late build all
        // get the hardest MP cruise template instead of progressing
        // through 3×1.5K → 4×1.5K → 3×2K). The effective index is
        // `weekInPhase - introductionWeek` so the walk-forward starts at 0
        // when a category is freshly engaged.
        for (cat, introWeek) in preferred {
            let inCat = available
                .filter { $0.category == cat }
                .sorted { $0.totalWorkMinutes < $1.totalWorkMinutes }
            if !inCat.isEmpty {
                // B6: base-phase strides — always pick the LIGHTEST speed
                // template (the 6×20s strides workout), not the walk-forward
                // 200m/300m/400m/600m progression. Base strides are a
                // neuromuscular maintenance touch, not a repetition ladder.
                if phase == .base && cat == .speed {
                    return inCat[0]
                }
                let lastIndex = inCat.count - 1
                let cap = isFirstTimerAtDistance ? max(0, lastIndex - 1) : lastIndex
                let effectiveWeek = max(0, weekInPhase - introWeek)
                let index = plateauOscillatingIndex(
                    effectiveWeek: effectiveWeek, cap: cap
                )
                return inCat[index]
            }
        }

        // Fallback: NONE of the preferred categories had a matching
        // template (rare, usually means an exotic phase × discipline
        // × experience combo we didn't anticipate). Pick a *safe*
        // category before falling back to "anything goes".
        //
        // M3: race-specific templates are tightly tied to phase timing
        // (peak only, late build for marathon). If a phase didn't ask
        // for raceSpecific, it shouldn't accidentally show up just
        // because the threshold pool was empty. Threshold / progression
        // / vo2max work safely in most contexts; raceSpecific and speed
        // do not. Only fall back to those when literally nothing else
        // is available.
        let safeCategories: Set<Category> = [.threshold, .progression, .vo2max, .longRunVariant]
        let safePool = available
            .filter { safeCategories.contains($0.category) }
            .sorted { $0.totalWorkMinutes < $1.totalWorkMinutes }
        let pool = safePool.isEmpty
            ? available.sorted { $0.totalWorkMinutes < $1.totalWorkMinutes }
            : safePool
        let lastIndex = pool.count - 1
        let cap = isFirstTimerAtDistance ? max(0, lastIndex - 1) : lastIndex
        let fallbackIndex = plateauOscillatingIndex(effectiveWeek: weekInPhase, cap: cap)
        return pool[fallbackIndex]
    }

    // MARK: - Purpose Line (B9)

    /// One-line "why" for a session, looked up from the `intervalFocus`
    /// string that the road plan pipeline writes onto `TrainingSession`
    /// at generation time. Surfaced in the session detail under the
    /// workout name so the athlete reads *what* (e.g. "5×1K Threshold")
    /// and *why* (e.g. "Lactate clearance — bread and butter for
    /// marathon pace") at a glance, rather than parsing the description
    /// each time.
    ///
    /// Returns `nil` when the focus is missing or unrecognised, the
    /// caller renders nothing in that case (no fabricated tagline for
    /// an unknown session type).
    static func purposeLine(for focus: String?) -> String? {
        guard let focus else { return nil }
        switch focus {
        case Category.speed.displayName:
            return String(localized: "session.purpose.speed",
                          defaultValue: "Neuromuscular freshness. Keeps the legs sharp.")
        case Category.vo2max.displayName:
            return String(localized: "session.purpose.vo2max",
                          defaultValue: "Aerobic ceiling. Top-end engine work.")
        case Category.threshold.displayName:
            return String(localized: "session.purpose.threshold",
                          defaultValue: "Lactate clearance. The bread and butter of marathon pace.")
        case Category.raceSpecific.displayName:
            return String(localized: "session.purpose.raceSpecific",
                          defaultValue: "Race-specific endurance. Rehearses your goal pace.")
        case Category.progression.displayName:
            return String(localized: "session.purpose.progression",
                          defaultValue: "Sustained aerobic power. Kenyan-style controlled build.")
        case Category.longRunVariant.displayName:
            return String(localized: "session.purpose.longRun",
                          defaultValue: "Time on feet. Race-specific endurance under fatigue.")
        default:
            return nil
        }
    }

    // MARK: - Plateau oscillation

    /// Walks forward through the difficulty ladder, then oscillates
    /// between the top two templates once the cap is reached, instead
    /// of pinning the hardest workout for every remaining week.
    ///
    /// Before this fix (B4): marathon peak (6 weeks) with only 3
    /// raceSpecific templates produced T0 / T1 / T2 / T2 / T2 / T2 —
    /// the athlete saw the same "MP 5K Blocks" four weeks in a row.
    /// After: T0 / T1 / T2 / T1 / T2 / T1 — final weeks alternate
    /// between the top two, giving the athlete variety in structure
    /// (e.g. 5K Blocks ⇄ 4K Pyramid) at comparable difficulty.
    ///
    /// When the category has only one template the oscillation
    /// degenerates to repeating that template (cap = 0 = top = bottom).
    /// In that case the variety gap is a template-pool issue, not a
    /// selection issue, the fix is to add another template.
    private static func plateauOscillatingIndex(effectiveWeek: Int, cap: Int) -> Int {
        guard cap > 0 else { return 0 }
        if effectiveWeek <= cap { return effectiveWeek }
        let overshoot = effectiveWeek - cap
        return overshoot.isMultiple(of: 2) ? cap : cap - 1
    }

    /// The physiological target category for a quality slot in a given
    /// context, used by `IntervalSessionComposer` to know WHAT to compose.
    /// Mirrors `selectForSlot`'s category choice: slot 0 takes the primary
    /// preference; slot 1 takes the first preference different from `exclude`.
    static func slotCategory(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        slotIndex: Int,
        weekInPhase: Int,
        exclude: Category? = nil
    ) -> Category {
        let prefs = categoryPreferences(
            phase: phase, discipline: discipline,
            slotIndex: slotIndex, weekInPhase: weekInPhase
        )
        if let exclude {
            return prefs.first(where: { $0.0 != exclude })?.0 ?? prefs.first?.0 ?? .threshold
        }
        return prefs.first?.0 ?? .threshold
    }

    // MARK: - Distance-Specific Category Preferences

    /// Returns ordered category preferences based on distance, phase, slot,
    /// and the athlete's progress within the phase.
    ///
    /// Research basis:
    /// - **10K** (Daniels): Speed → VO2max → race-specific. VO2max is the limiter.
    /// - **HM** (Pfitzinger): Threshold is the limiter. Extended threshold through peak.
    /// - **Marathon** (Canova/Pfitzinger): Aerobic base → threshold → MP-specific.
    ///   Threshold continues through peak phase. Race-specific (MP cruise
    ///   intervals) introduce in late build so peak isn't the first time the
    ///   athlete sees marathon pace.
    /// - **Base** (Daniels/Pfitzinger purer model): Base is mileage-first. Drop
    ///   `.speed` from primary slot, repetition work belongs in build/peak,
    ///   not aerobic base. Base has at most one quality session/week, the
    ///   second slot is suppressed at the selector level for base phase.
    /// Returns `[(category, introductionWeekInPhase)]` so a category that
    /// only kicks in mid-phase (e.g. marathon raceSpecific in late build)
    /// can be walked forward starting from its own zero, not from the
    /// phase's zero. Most categories use `0` (live since week 0).
    private static func categoryPreferences(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        slotIndex: Int,
        weekInPhase: Int = 0
    ) -> [(Category, Int)] {
        // Marathon late-build threshold: raceSpecific MP cruise intervals
        // first appear at weekInPhase >= 3. Encoded as an explicit constant
        // so both Q1 and Q2 share the same introduction point and stay
        // synchronized when one slot picks raceSpecific over the other.
        let marathonRaceSpecificIntroWeek = 3

        switch (phase, discipline, slotIndex) {
        // === BASE: One quality session/week. Light progression or threshold
        // most weeks, strides every 3rd base week for neuromuscular
        // maintenance (Daniels/Pfitzinger). Slot 1 is unused in base.
        // The strides rotation kicks in on weekInPhase 2, 5, 8, … so
        // short base mesocycles still get at least one strides session
        // (a 6-week base hits weeks 2 and 5).
        case (.base, _, 0):
            if weekInPhase % 3 == 2 {
                return [(.speed, 0), (.progression, 0)]
            }
            return [(.progression, 0), (.threshold, 0)]
        case (.base, _, _):
            return [(.threshold, 0), (.progression, 0)]

        // === BUILD: Distance-specific ===
        // 10K: VO2max is the limiter (Daniels)
        case (.build, .road10K, 0):     return [(.vo2max, 0), (.speed, 0)]
        case (.build, .road10K, _):     return [(.threshold, 0), (.vo2max, 0)]
        // HM: Threshold is the limiter (Pfitzinger: "LT is the HM cornerstone")
        case (.build, .roadHalf, 0):    return [(.threshold, 0), (.vo2max, 0)]
        case (.build, .roadHalf, _):    return [(.threshold, 0), (.progression, 0)]
        // Marathon Q1 (Tuesday, the hardest session of the week):
        // VO2max early build builds aerobic ceiling, then late build
        // (weekInPhase >= 3) transitions to MP cruise intervals so the
        // athlete sees marathon-pace work BEFORE peak. Without this
        // transition the first MP intervals show up at peak Q1 cold
        // contrary to Canova's progression and Pfitzinger 18/85 which
        // both gradually introduce MP cruise (1.5K → 2K → 3K) through
        // late build before the peak's full MP blocks. (RR-27 audit C2.)
        case (.build, .roadMarathon, 0):
            return weekInPhase >= marathonRaceSpecificIntroWeek
                ? [(.raceSpecific, marathonRaceSpecificIntroWeek), (.vo2max, 0)]
                : [(.vo2max, 0), (.threshold, 0)]
        // Marathon Q2 (Thursday): threshold-primary, race-specific takes
        // over in late build alongside Q1 so the athlete sees TWO MP
        // sessions/week in late build instead of one.
        case (.build, .roadMarathon, _):
            return weekInPhase >= marathonRaceSpecificIntroWeek
                ? [(.raceSpecific, marathonRaceSpecificIntroWeek), (.threshold, 0), (.progression, 0)]
                : [(.threshold, 0), (.progression, 0)]

        // === PEAK: Distance-specific ===
        // 10K: Race-specific + VO2max sharpeners
        case (.peak, .road10K, 0):      return [(.raceSpecific, 0), (.vo2max, 0)]
        case (.peak, .road10K, _):      return [(.vo2max, 0), (.raceSpecific, 0)]
        // HM: Threshold CONTINUES + race-specific (Pfitzinger: LT is cornerstone)
        case (.peak, .roadHalf, 0):     return [(.raceSpecific, 0), (.threshold, 0)]
        case (.peak, .roadHalf, _):     return [(.threshold, 0), (.raceSpecific, 0)]
        // Marathon: Race-specific + threshold maintenance (Canova: threshold never stops)
        case (.peak, .roadMarathon, 0): return [(.raceSpecific, 0), (.threshold, 0)]
        case (.peak, .roadMarathon, _): return [(.threshold, 0), (.raceSpecific, 0)]

        // === TAPER: Light sharpeners ===
        case (.taper, _, _):
            return [(.speed, 0), (.raceSpecific, 0)]

        default:
            return [(.threshold, 0)]
        }
    }

    // MARK: - All Templates

    static let allTemplates: [Template] = {
        var t: [Template] = []
        t.append(contentsOf: speedTemplates)
        t.append(contentsOf: vo2maxTemplates)
        t.append(contentsOf: thresholdTemplates)
        t.append(contentsOf: raceSpecificTemplates)
        t.append(contentsOf: progressionTemplates)
        t.append(contentsOf: auditTemplates)
        return t
    }()

    // MARK: - Category A: Speed / Running Economy

    private static let speedTemplates: [Template] = [
        Template(
            name: "200m Repeats",
            category: .speed, description: "Fast 200m reps to build leg speed and running economy.",
            targetPaceZone: .repetition, repDistanceM: 200, repCount: 10,
            recoverySeconds: 60, recoveryType: .jog, totalWorkMinutes: 8,
            applicablePhases: [.base, .build], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .beginner
        ),
        Template(
            name: "400m Repeats",
            category: .speed, description: "Classic 400m repeats at R-pace. Neuromuscular speed work.",
            targetPaceZone: .repetition, repDistanceM: 400, repCount: 8,
            recoverySeconds: 90, recoveryType: .jog, totalWorkMinutes: 12,
            applicablePhases: [.base, .build], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .beginner
        ),
        Template(
            name: "600m Repeats",
            category: .speed, description: "Longer speed reps bridging to VO2max work.",
            targetPaceZone: .repetition, repDistanceM: 600, repCount: 6,
            recoverySeconds: 90, recoveryType: .jog, totalWorkMinutes: 12,
            applicablePhases: [.base, .build], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .intermediate
        ),
    ]

    // MARK: - Category B: VO2max Intervals

    private static let vo2maxTemplates: [Template] = [
        Template(
            name: "800m VO2max",
            category: .vo2max, description: "6×800m at I-pace. Core VO2max development.",
            targetPaceZone: .interval, repDistanceM: 800, repCount: 6,
            recoverySeconds: 120, recoveryType: .jog, totalWorkMinutes: 18,
            applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .beginner
        ),
        Template(
            name: "1000m VO2max",
            category: .vo2max, description: "5×1000m at I-pace. Staple VO2max interval session.",
            targetPaceZone: .interval, repDistanceM: 1000, repCount: 5,
            recoverySeconds: 150, recoveryType: .jog, totalWorkMinutes: 20,
            applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .beginner
        ),
        Template(
            name: "1200m VO2max",
            category: .vo2max, description: "4×1200m at I-pace. Extended aerobic power intervals.",
            targetPaceZone: .interval, repDistanceM: 1200, repCount: 4,
            recoverySeconds: 180, recoveryType: .jog, totalWorkMinutes: 20,
            applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .intermediate
        ),
        Template(
            name: "1600m VO2max",
            category: .vo2max, description: "4×1600m at I-pace. Long VO2max intervals for sustained power.",
            targetPaceZone: .interval, repDistanceM: 1600, repCount: 4,
            recoverySeconds: 210, recoveryType: .jog, totalWorkMinutes: 24,
            applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .intermediate
        ),
        Template(
            name: "2000m VO2max",
            category: .vo2max, description: "3×2000m at I-pace. Bridges VO2max to race-specific for HM.",
            targetPaceZone: .interval, repDistanceM: 2000, repCount: 3,
            recoverySeconds: 240, recoveryType: .jog, totalWorkMinutes: 24,
            applicablePhases: [.build, .peak], applicableDistances: [.roadHalf, .roadMarathon],
            minExperience: .advanced
        ),
        Template(
            name: "Norwegian 1K Floats",
            category: .vo2max, description: "8×1000m at 97% 10K pace with 400m float recovery. Norwegian model.",
            targetPaceZone: .interval, repDistanceM: 1000, repCount: 8,
            recoverySeconds: 100, recoveryType: .float, totalWorkMinutes: 28,
            applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf],
            minExperience: .advanced
        ),
    ]

    // MARK: - Category C: Lactate Threshold

    private static let thresholdTemplates: [Template] = [
        Template(
            name: "Cruise Intervals 1K",
            category: .threshold, description: "5×1000m at T-pace, 90s rest. Cruise intervals at threshold.",
            targetPaceZone: .threshold, repDistanceM: 1000, repCount: 5,
            recoverySeconds: 90, recoveryType: .standing, totalWorkMinutes: 20,
            applicablePhases: [.base, .build, .peak], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .beginner
        ),
        Template(
            name: "Cruise Intervals 1600m",
            category: .threshold, description: "4×1600m at T-pace, 3min rest. Extended cruise intervals.",
            targetPaceZone: .threshold, repDistanceM: 1600, repCount: 4,
            recoverySeconds: 180, recoveryType: .standing, totalWorkMinutes: 24,
            applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .intermediate
        ),
        Template(
            name: "Tempo 20min",
            category: .threshold, description: "20min continuous at T-pace. Lactate threshold builder.",
            targetPaceZone: .threshold, repDistanceM: 0, repCount: 1,
            recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 20,
            applicablePhases: [.base, .build], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .beginner
        ),
        Template(
            name: "Double Tempo",
            category: .threshold, description: "2×20min at T-pace, 3min jog. Lactate threshold staple.",
            targetPaceZone: .threshold, repDistanceM: 0, repCount: 2,
            recoverySeconds: 180, recoveryType: .jog, totalWorkMinutes: 40,
            applicablePhases: [.build, .peak], applicableDistances: [.roadHalf, .roadMarathon],
            minExperience: .intermediate
        ),
        Template(
            name: "Extended Tempo 30min",
            category: .threshold, description: "30min continuous at T-pace. Advanced threshold endurance.",
            targetPaceZone: .threshold, repDistanceM: 0, repCount: 1,
            recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 30,
            applicablePhases: [.peak], applicableDistances: [.roadHalf, .roadMarathon],
            minExperience: .advanced
        ),
        Template(
            name: "Norwegian Double Threshold",
            category: .threshold, description: "2×4000m at T-pace, 4min jog. Ingebrigtsen system.",
            targetPaceZone: .threshold, repDistanceM: 4000, repCount: 2,
            recoverySeconds: 240, recoveryType: .jog, totalWorkMinutes: 28,
            applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf],
            minExperience: .advanced
        ),
        Template(
            name: "Threshold Ladder 2K",
            category: .threshold, description: "3×2000m at T-pace, 2min jog. Marathon lactate endurance.",
            targetPaceZone: .threshold, repDistanceM: 2000, repCount: 3,
            recoverySeconds: 120, recoveryType: .jog, totalWorkMinutes: 24,
            applicablePhases: [.build], applicableDistances: [.roadMarathon],
            minExperience: .intermediate
        ),
    ]

    // MARK: - Category D: Race-Specific

    private static let raceSpecificTemplates: [Template] = [
        // === Marathon late-build MP introductions ===
        // Pfitzinger / Canova-style: 1.5–2.5 km cruise intervals at MP with
        // very short recovery, before peak ramps to 3 km / 5 km / 7 km blocks.
        // Sits in build phase so the athlete meets marathon pace gradually.
        Template(
            name: "MP Cruise 3×1.5K",
            category: .raceSpecific, description: "3×1500m at marathon pace, 60s jog. Intro MP work, late build.",
            targetPaceZone: .marathonPace, repDistanceM: 1500, repCount: 3,
            recoverySeconds: 60, recoveryType: .jog, totalWorkMinutes: 18,
            applicablePhases: [.build], applicableDistances: [.roadMarathon],
            minExperience: .intermediate
        ),
        Template(
            name: "MP Cruise 4×1.5K",
            category: .raceSpecific, description: "4×1500m at marathon pace, 60s jog. Extended MP intro for advanced.",
            targetPaceZone: .marathonPace, repDistanceM: 1500, repCount: 4,
            recoverySeconds: 60, recoveryType: .jog, totalWorkMinutes: 24,
            applicablePhases: [.build], applicableDistances: [.roadMarathon],
            minExperience: .advanced
        ),
        Template(
            name: "MP Cruise 3×2K",
            category: .raceSpecific, description: "3×2000m at marathon pace, 90s jog. Bridging MP block to peak.",
            targetPaceZone: .marathonPace, repDistanceM: 2000, repCount: 3,
            recoverySeconds: 90, recoveryType: .jog, totalWorkMinutes: 24,
            applicablePhases: [.build], applicableDistances: [.roadMarathon],
            minExperience: .intermediate
        ),
        // 10K specific
        Template(
            name: "10K Pace 1000m",
            category: .raceSpecific, description: "8×1000m at 10K pace, 90s jog. Lock in race rhythm.",
            targetPaceZone: .racePace, repDistanceM: 1000, repCount: 8,
            recoverySeconds: 90, recoveryType: .jog, totalWorkMinutes: 28,
            applicablePhases: [.peak], applicableDistances: [.road10K],
            minExperience: .beginner
        ),
        Template(
            name: "10K Pace 2000m",
            category: .raceSpecific, description: "4×2000m at 10K pace, 90s jog. Extended race-specific intervals.",
            targetPaceZone: .racePace, repDistanceM: 2000, repCount: 4,
            recoverySeconds: 90, recoveryType: .jog, totalWorkMinutes: 28,
            applicablePhases: [.peak], applicableDistances: [.road10K],
            minExperience: .intermediate
        ),
        Template(
            name: "10K Pace 3000m",
            category: .raceSpecific, description: "3×3000m at 10K pace, 3min jog. Advanced 10K simulation.",
            targetPaceZone: .racePace, repDistanceM: 3000, repCount: 3,
            recoverySeconds: 180, recoveryType: .jog, totalWorkMinutes: 30,
            applicablePhases: [.peak], applicableDistances: [.road10K],
            minExperience: .advanced
        ),
        Template(
            name: "10K Tempo Simulation",
            category: .raceSpecific, description: "Continuous 8-10min at 10K race pace. Full-system rehearsal.",
            targetPaceZone: .racePace, repDistanceM: 0, repCount: 1,
            recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 9,
            applicablePhases: [.peak], applicableDistances: [.road10K],
            minExperience: .advanced
        ),
        // Half Marathon specific
        Template(
            name: "HM Pace 1600m",
            category: .raceSpecific, description: "6×1600m at HM pace, 90s jog. Half-marathon race rhythm.",
            targetPaceZone: .racePace, repDistanceM: 1600, repCount: 6,
            recoverySeconds: 90, recoveryType: .jog, totalWorkMinutes: 30,
            applicablePhases: [.peak], applicableDistances: [.roadHalf],
            minExperience: .beginner
        ),
        Template(
            name: "HM Pace 3000m",
            category: .raceSpecific, description: "4×3000m at HM pace, 2min jog. Sustained race-pace endurance.",
            targetPaceZone: .racePace, repDistanceM: 3000, repCount: 4,
            recoverySeconds: 120, recoveryType: .jog, totalWorkMinutes: 40,
            applicablePhases: [.peak], applicableDistances: [.roadHalf],
            minExperience: .intermediate
        ),
        Template(
            name: "HM Pace 5000m",
            category: .raceSpecific, description: "3×5000m at HM pace, 3min jog. Long HM-specific blocks.",
            targetPaceZone: .racePace, repDistanceM: 5000, repCount: 3,
            recoverySeconds: 180, recoveryType: .jog, totalWorkMinutes: 48,
            applicablePhases: [.peak], applicableDistances: [.roadHalf],
            minExperience: .advanced
        ),
        // Marathon specific (Canova-style)
        Template(
            name: "Marathon Pace 3K Blocks",
            category: .raceSpecific, description: "5×3000m at 103% MP with 1000m float. Marathon-specific block.",
            targetPaceZone: .marathonPace, repDistanceM: 3000, repCount: 5,
            recoverySeconds: 240, recoveryType: .float, totalWorkMinutes: 40,
            applicablePhases: [.peak], applicableDistances: [.roadMarathon],
            minExperience: .intermediate
        ),
        Template(
            name: "Marathon Pace 5K Blocks",
            category: .raceSpecific, description: "4×5000m at MP, 1000m jog. Extended marathon-specific endurance.",
            targetPaceZone: .marathonPace, repDistanceM: 5000, repCount: 4,
            recoverySeconds: 300, recoveryType: .jog, totalWorkMinutes: 60,
            applicablePhases: [.peak], applicableDistances: [.roadMarathon],
            minExperience: .advanced
        ),
        Template(
            name: "Marathon Pace 7K Blocks",
            category: .raceSpecific, description: "3×7000m at MP, 1000m jog. Special block for advanced runners.",
            targetPaceZone: .marathonPace, repDistanceM: 7000, repCount: 3,
            recoverySeconds: 300, recoveryType: .jog, totalWorkMinutes: 63,
            applicablePhases: [.peak], applicableDistances: [.roadMarathon],
            minExperience: .elite
        ),
    ]

    // MARK: - Category E: Progression Runs

    private static let progressionTemplates: [Template] = [
        Template(
            name: "Short Progression",
            category: .progression, description: "25min building from easy to 108% race pace. Progressive stimulus.",
            targetPaceZone: .racePace, repDistanceM: 0, repCount: 1,
            recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 25,
            applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
            minExperience: .beginner
        ),
        Template(
            name: "Medium Progression",
            category: .progression, description: "45min building from 88% to 105% race pace. Kenyan-style.",
            targetPaceZone: .racePace, repDistanceM: 0, repCount: 1,
            recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 45,
            applicablePhases: [.build, .peak], applicableDistances: [.roadHalf, .roadMarathon],
            minExperience: .intermediate
        ),
        Template(
            name: "Long Progression",
            category: .progression, description: "60min building from 80% to race pace. Advanced aerobic power.",
            targetPaceZone: .racePace, repDistanceM: 0, repCount: 1,
            recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 60,
            applicablePhases: [.peak], applicableDistances: [.roadMarathon],
            minExperience: .advanced
        ),
    ]

    // MARK: - Additional Templates (Audit Fixes)

    /// Templates added from coaching methodology audit:
    /// Marathon-specific threshold, HM-pace tempo, Billat 30/30,
    /// progressive tempo, 2Q combos, long run variants.
    private static var auditTemplates: [Template] {
        [
            // Marathon-specific threshold in peak (Pfitzinger: threshold continues through peak)
            Template(
                name: "Marathon Threshold 25min",
                category: .threshold, description: "25min continuous at T-pace. Marathon lactate clearance.",
                targetPaceZone: .threshold, repDistanceM: 0, repCount: 1,
                recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 25,
                applicablePhases: [.peak], applicableDistances: [.roadMarathon],
                minExperience: .intermediate
            ),
            // HM-pace tempo work for peak (Pfitzinger: lock in race rhythm)
            Template(
                name: "HM Tempo Run 20min",
                category: .raceSpecific, description: "20min continuous at HM pace. Race rhythm builder.",
                targetPaceZone: .racePace, repDistanceM: 0, repCount: 1,
                recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 20,
                applicablePhases: [.peak], applicableDistances: [.roadHalf],
                minExperience: .beginner
            ),
            // Progressive tempo (Canova: vary stimulus without intervals)
            Template(
                name: "Progressive Tempo 30min",
                category: .threshold, description: "30min building from easy to T-pace. Progressive threshold stimulus.",
                targetPaceZone: .threshold, repDistanceM: 0, repCount: 1,
                recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 30,
                applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
                minExperience: .intermediate
            ),
            // Billat 30/30 VO2max (Billat, INSEP research)
            Template(
                name: "Billat 30/30",
                category: .vo2max, description: "14×(30s hard / 30s easy). VO2max stimulus with minimal recovery.",
                targetPaceZone: .interval, repDistanceM: 0, repCount: 14,
                recoverySeconds: 30, recoveryType: .jog, totalWorkMinutes: 14,
                applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf],
                minExperience: .advanced
            ),
            // Daniels 2Q combo: tempo + VO2max in one session (advanced/elite)
            Template(
                name: "2Q Tempo + VO2max",
                category: .vo2max, description: "15min tempo (T-pace) then 4×3min VO2max (I-pace). Threshold-to-VO2max combo.",
                targetPaceZone: .interval, repDistanceM: 0, repCount: 4,
                recoverySeconds: 180, recoveryType: .jog, totalWorkMinutes: 27,
                applicablePhases: [.peak], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
                minExperience: .advanced
            ),
            // Marathon continuous tempo at MP (not threshold, race-specific tempo)
            Template(
                name: "Marathon Tempo 30min",
                category: .raceSpecific, description: "30min continuous at marathon pace. Lock in race rhythm.",
                targetPaceZone: .marathonPace, repDistanceM: 0, repCount: 1,
                recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 30,
                applicablePhases: [.peak], applicableDistances: [.roadMarathon],
                minExperience: .intermediate
            ),
            // Billat threshold 5×5min (lactate clearance)
            Template(
                name: "Threshold 5×5min",
                category: .threshold, description: "5×5min at T-pace, 90s rest. Lactate clearance training.",
                targetPaceZone: .threshold, repDistanceM: 0, repCount: 5,
                recoverySeconds: 90, recoveryType: .jog, totalWorkMinutes: 25,
                applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
                minExperience: .intermediate
            ),
            // Long run + VO2 surges (marathon build)
            Template(
                name: "LR + VO2 Surges",
                category: .longRunVariant, description: "Easy long run with 6×2min surges at I-pace.",
                targetPaceZone: .interval, repDistanceM: 0, repCount: 6,
                recoverySeconds: 180, recoveryType: .jog, totalWorkMinutes: 12,
                applicablePhases: [.build], applicableDistances: [.roadHalf, .roadMarathon],
                minExperience: .advanced
            ),
            // Long run + tempo blocks (marathon peak)
            Template(
                name: "LR + Tempo Blocks",
                category: .longRunVariant, description: "Easy long run with 2×12min blocks at T-pace.",
                targetPaceZone: .threshold, repDistanceM: 0, repCount: 2,
                recoverySeconds: 300, recoveryType: .jog, totalWorkMinutes: 24,
                applicablePhases: [.build, .peak], applicableDistances: [.roadMarathon],
                minExperience: .intermediate
            ),
            // Canova alternating long run (marathon peak, MP blocks)
            Template(
                name: "Alternating Long Run",
                category: .longRunVariant, description: "Easy + 3×3km MP blocks + easy. Marathon-specific endurance.",
                targetPaceZone: .marathonPace, repDistanceM: 3000, repCount: 3,
                recoverySeconds: 300, recoveryType: .jog, totalWorkMinutes: 30,
                applicablePhases: [.peak], applicableDistances: [.roadMarathon],
                minExperience: .intermediate
            ),
            // Tempo with surges (Pfitzinger near-peak: tempo + surges at 10K pace)
            Template(
                name: "Tempo + Surges",
                category: .threshold, description: "20min tempo with 4×1min surges at 10K pace mid-run.",
                targetPaceZone: .threshold, repDistanceM: 0, repCount: 1,
                recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 24,
                applicablePhases: [.peak], applicableDistances: [.road10K, .roadHalf],
                minExperience: .advanced
            ),
            // 300m repeats (bridge between 200m and 400m)
            Template(
                name: "300m Repeats",
                category: .speed, description: "8×300m at R-pace. Speed rhythm bridge.",
                targetPaceZone: .repetition, repDistanceM: 300, repCount: 8,
                recoverySeconds: 75, recoveryType: .jog, totalWorkMinutes: 10,
                applicablePhases: [.base, .build], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
                minExperience: .beginner
            ),
            // Base-phase strides (B6). Daniels' Running Formula and
            // Pfitzinger both prescribe strides 1-2×/week through base
            // for neuromuscular maintenance. 6×20-second accelerations
            // after a 30-min easy warm-up: short, gentle, never
            // anaerobic. Marked .base only so other phases keep their
            // usual speed/repetition workouts unchanged. Slot 0 base
            // preferences pull this in on every 3rd base week.
            Template(
                name: "Strides 6×20s",
                category: .speed, description: "30 min easy + 6×20-second strides at R-pace, 90s walk. Neuromuscular freshness.",
                targetPaceZone: .repetition, repDistanceM: 0, repCount: 6,
                recoverySeconds: 90, recoveryType: .walk, totalWorkMinutes: 2,
                applicablePhases: [.base], applicableDistances: [.road10K, .roadHalf, .roadMarathon],
                minExperience: .beginner
            ),

            // --- Marathon-peak raceSpecific variety (B4) ---
            // Previously advanced marathon peak had only 3 templates
            // (MP Tempo 30, MP 3K Blocks, MP 5K Blocks) → 6-week peak
            // plateaued on MP 5K Blocks for the last 3-4 weeks. These
            // five additions give a richer rotation across the peak
            // mesocycle, covering the standard Pfitzinger/Canova MP
            // structures (continuous, short-rep, pyramid, cutdown,
            // sharpener) instead of a single workout repeated.

            // Intro-level MP block — sits BELOW MP 3K Blocks on the
            // difficulty ladder so peak W1 isn't a Canova 5×3km cold.
            Template(
                name: "MP 4×2K",
                category: .raceSpecific, description: "4×2000m at marathon pace, 90s jog. Intro-level MP block.",
                targetPaceZone: .marathonPace, repDistanceM: 2000, repCount: 4,
                recoverySeconds: 90, recoveryType: .jog, totalWorkMinutes: 32,
                applicablePhases: [.peak], applicableDistances: [.roadMarathon],
                minExperience: .intermediate
            ),
            // Continuous-block alternative to interval-style MP work
            // (Pfitzinger 18/70 prescribes 8 km continuous @ MP within
            // a longer session as a sustained lactate-tolerance test).
            Template(
                name: "MP 8K Continuous",
                category: .raceSpecific, description: "8000m continuous at marathon pace. Sustained MP block.",
                targetPaceZone: .marathonPace, repDistanceM: 0, repCount: 1,
                recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 36,
                applicablePhases: [.peak], applicableDistances: [.roadMarathon],
                minExperience: .intermediate
            ),
            // Pyramid: varied reps (Canova-style structural variation).
            // Total 9 km @ MP across 5 reps with progressive then
            // descending length — same MP work, different rhythm
            // than uniform-rep blocks.
            Template(
                name: "MP Pyramid 1-2-3-2-1",
                category: .raceSpecific, description: "1K + 2K + 3K + 2K + 1K at MP, 60s jog between reps. Pyramid block.",
                targetPaceZone: .marathonPace, repDistanceM: 0, repCount: 5,
                recoverySeconds: 60, recoveryType: .jog, totalWorkMinutes: 40,
                applicablePhases: [.peak], applicableDistances: [.roadMarathon],
                minExperience: .advanced
            ),
            // MP cutdown: final 2K accelerates from MP-equivalent to
            // ~HM-pace. Teaches the athlete to finish strong from
            // marathon-pace fatigue (race-day skill).
            Template(
                name: "MP Cutdown 6K",
                category: .raceSpecific, description: "6000m progressing from MP+10s/km to HM pace over the final 2K. Race-finish skill.",
                targetPaceZone: .marathonPace, repDistanceM: 0, repCount: 1,
                recoverySeconds: 0, recoveryType: .standing, totalWorkMinutes: 28,
                applicablePhases: [.peak], applicableDistances: [.roadMarathon],
                minExperience: .advanced
            ),
            // Short-rep MP sharpener — peak/taper bridge. Pfitzinger
            // 18/85 final-peak prescribes "8×1km @ MP, 60s jog" as a
            // sharpener that holds MP touch without the cumulative
            // fatigue of long blocks.
            Template(
                name: "MP 6×1K Sharpener",
                category: .raceSpecific, description: "6×1000m at marathon pace, 60s jog. Late-peak MP sharpener.",
                targetPaceZone: .marathonPace, repDistanceM: 1000, repCount: 6,
                recoverySeconds: 60, recoveryType: .jog, totalWorkMinutes: 24,
                applicablePhases: [.peak], applicableDistances: [.roadMarathon],
                minExperience: .intermediate
            ),

            // Build-phase MP cruise intermediate — fills the gap
            // between MP Cruise 3×1.5K (18 min) and MP Cruise 3×2K
            // (24 min) so 4-week late build has 4 walk-forward
            // templates instead of 3.
            Template(
                name: "MP Cruise 5×1K",
                category: .raceSpecific, description: "5×1000m at marathon pace, 60s jog. Early MP intro for late build.",
                targetPaceZone: .marathonPace, repDistanceM: 1000, repCount: 5,
                recoverySeconds: 60, recoveryType: .jog, totalWorkMinutes: 20,
                applicablePhases: [.build], applicableDistances: [.roadMarathon],
                minExperience: .intermediate
            ),
        ]
    }
}

// MARK: - ExperienceLevel Sort Helper

extension ExperienceLevel {
    var rawSortOrder: Int {
        switch self {
        case .beginner:     0
        case .intermediate: 1
        case .advanced:     2
        case .elite:        3
        }
    }
}

// MARK: - Template Pace Selection

extension RoadIntervalLibrary.Template {
    /// Picks the appropriate threshold pace for this template from the
    /// athlete's `thresholdPaceRangePerKm` (Daniels 1.06× – 1.09× of 5K
    /// pace).
    ///
    /// - Cruise intervals (short reps with recovery, per-rep ≤ 10 min)
    ///   → **faster end** (1.06×). The athlete can recover between
    ///   reps, so the pace itself is steeper. Daniels' classic 4×5 min
    ///   T or 5×1 km T sessions live here.
    /// - Sustained tempo (single continuous block, or multi-rep with
    ///   each rep ≥ 11 min) → **slower end** (1.09×). One-hour-holdable
    ///   pace because the rep itself is the lactate-clearance work.
    ///   "Tempo 20 min", "Marathon Threshold 25 min", "Double Tempo
    ///   2×20 min" live here.
    ///
    /// Only call on threshold-zone templates; non-threshold zones have
    /// their own single-value pace and ignore the range.
    func effectiveThresholdPacePerKm(profile: RoadPaceProfile) -> Double {
        guard repCount > 1 else {
            return profile.thresholdPaceRangePerKm.upperBound
        }
        let perRepMinutes = totalWorkMinutes / Double(repCount)
        if perRepMinutes <= 10 {
            return profile.thresholdPaceRangePerKm.lowerBound
        }
        return profile.thresholdPaceRangePerKm.upperBound
    }
}
