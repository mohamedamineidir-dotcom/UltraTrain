import Foundation

/// A complete set of Daniels-based training pace zones for road race preparation.
///
/// The 6-tier system (Daniels, 2014 — "Daniels' Running Formula"):
/// - **E (Easy)**: 65-75% VO2max → recovery, warm-up, cool-down, base building
/// - **MP (Marathon Pace)**: ~78-82% VO2max → marathon-specific endurance
/// - **T (Threshold)**: ~83-88% VO2max → lactate clearance, ~1hr max race effort
/// - **I (Interval/VO2max)**: ~95-100% VO2max → ~3K-5K race pace, aerobic power
/// - **R (Repetition)**: ~105-112% VO2max → ~mile race pace, neuromuscular speed
/// - **RP (Race Pace)**: exact target pace for the goal race distance
///
/// All paces stored in seconds per kilometer.
struct RoadPaceProfile: Equatable, Sendable {
    let easyPacePerKm: ClosedRange<Double>
    let marathonPacePerKm: Double
    let thresholdPacePerKm: Double
    let intervalPacePerKm: Double
    let repetitionPacePerKm: Double
    let racePacePerKm: Double

    /// Whether the athlete's goal is ambitious relative to current fitness.
    /// Used to gate race-pace usage in early phases (Daniels: don't train at goal
    /// pace if it's >10% faster than current fitness supports).
    let goalRealismLevel: GoalRealism

    /// True when the pace values came from actual athlete data (PRs, VMA,
    /// or a goal time). False when they fell through to a pure experience-
    /// tier heuristic because the athlete entered no PRs, no VMA, and no
    /// goal time. UI should prefer RPE/effort labels over specific /km
    /// paces when this is false — a coach prescribes by effort when there's
    /// no baseline data, not by fabricated pace numbers.
    let isDataDerived: Bool

    /// Coach-recommended realistic finish time given the athlete's current
    /// fitness — fitness-derived pace × race distance. Used by coach advice
    /// to suggest a retarget when the athlete's declared goal is
    /// .veryAmbitious. Nil when we have no usable fitness signal.
    let recommendedGoalTime: TimeInterval?
}

/// Classification of how realistic the athlete's target time is relative to current fitness.
enum GoalRealism: String, Sendable, Codable {
    /// Goal ≤10% faster than current fitness — use goal pace for all specific work.
    case realistic
    /// Goal 10-25% faster — use fitness paces for VO2max/threshold, goal pace only in late peak.
    case ambitious
    /// Goal >25% faster — flag in coach advice, use fitness paces throughout.
    case veryAmbitious
}

/// Discipline classification for road races.
/// Determines phase structure, interval selection, and long run caps.
enum RoadRaceDiscipline: String, Sendable {
    case road10K
    case roadHalf
    case roadMarathon

    static func from(distanceKm: Double) -> RoadRaceDiscipline {
        switch distanceKm {
        case ..<15:    return .road10K
        case ..<30:    return .roadHalf
        default:       return .roadMarathon
        }
    }

    var displayName: String {
        switch self {
        case .road10K:      "10K"
        case .roadHalf:     "Half Marathon"
        case .roadMarathon: "Marathon"
        }
    }

    /// Maximum long run distance in km. Daniels: LR ≤ 25% of weekly volume
    /// or distance cap. Pfitzinger 18/55: 16mi (26km), 18/70: 20mi (32km),
    /// 18/85: 22mi (35km). Hanson: 16mi (26km) regardless of athlete tier.
    ///
    /// The cap responds to three personalisation dimensions:
    ///   • **experience** — base level (beginner→elite)
    ///   • **philosophy** — performance lifts the cap modestly
    ///     (×1.08), enjoyment trims it (×0.92). Wider swings would
    ///     over-rotate: a marathon LR can only meaningfully grow so far
    ///     before recovery cost outweighs adaptation (Pfitzinger
    ///     stops at 22 mi even for elites).
    ///   • **goal** — targetRanking nudges +5%, finish trims -5%.
    ///     Goal effect is smaller than philosophy because the target
    ///     time is already encoded in pace targets, not LR distance.
    ///
    /// Floors prevent the lowest combinations from producing dangerously
    /// short LRs (Hanson principle: marathoners need a 26 km cumulative
    /// fatigue test). Ceilings prevent the highest combinations from
    /// pushing athletes above what mainstream road coaching considers
    /// safe-to-recover from.
    func longRunCapKm(
        experience: ExperienceLevel,
        philosophy: TrainingPhilosophy = .balanced,
        raceGoal: RaceGoal = .targetTime(0)
    ) -> Double {
        let baseline: Double
        switch (self, experience) {
        case (.road10K, .beginner):          baseline = 16
        case (.road10K, .intermediate):      baseline = 20
        case (.road10K, .advanced):          baseline = 24
        case (.road10K, .elite):             baseline = 24
        case (.roadHalf, .beginner):         baseline = 20
        case (.roadHalf, .intermediate):     baseline = 23
        case (.roadHalf, .advanced):         baseline = 26
        case (.roadHalf, .elite):            baseline = 26
        case (.roadMarathon, .beginner):     baseline = 30
        case (.roadMarathon, .intermediate): baseline = 32
        case (.roadMarathon, .advanced):     baseline = 35
        case (.roadMarathon, .elite):        baseline = 35
        }

        let philMult: Double = switch philosophy {
        case .enjoyment:    0.92
        case .balanced:     1.00
        case .performance:  1.08
        }

        let goalMult: Double
        switch raceGoal {
        case .finish:        goalMult = 0.95
        case .targetTime:    goalMult = 1.00
        case .targetRanking: goalMult = 1.05
        }

        let scaled = baseline * philMult * goalMult

        // Floors — minimum LRs to actually prepare for the race.
        // Hanson holds marathoners at 26 km even for the most conservative
        // profile; Pfitz keeps HM athletes at 16+ km; 10K runners need
        // ~120% of race distance to develop adequate aerobic depth.
        let floor: Double
        let ceiling: Double
        switch self {
        case .road10K:      (floor, ceiling) = (12, 24)
        case .roadHalf:     (floor, ceiling) = (16, 28)
        case .roadMarathon: (floor, ceiling) = (26, 35)
        }

        return min(max(scaled, floor), ceiling)
    }

    /// Peak weekly volume in km (Pfitzinger plans as reference).
    /// 10K: 16/30 → 16/60. HM: 12/50 → 16/80. Marathon: 18/55 → 18/85+.
    func peakWeeklyKm(experience: ExperienceLevel) -> Double {
        switch (self, experience) {
        case (.road10K, .beginner):       40
        case (.road10K, .intermediate):   55
        case (.road10K, .advanced):       70
        case (.road10K, .elite):          85
        case (.roadHalf, .beginner):      55
        case (.roadHalf, .intermediate):  70
        case (.roadHalf, .advanced):      90
        case (.roadHalf, .elite):         110
        case (.roadMarathon, .beginner):  55
        case (.roadMarathon, .intermediate): 85
        case (.roadMarathon, .advanced):  115
        case (.roadMarathon, .elite):     140
        }
    }
}
