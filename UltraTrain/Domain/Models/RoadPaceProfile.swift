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
    let raceDistanceKm: Double

    /// Whether the athlete's goal is ambitious relative to current fitness.
    /// Used to gate race-pace usage in early phases (Daniels: don't train at goal
    /// pace if it's >10% faster than current fitness supports).
    let goalRealismLevel: GoalRealism
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

    /// Maximum long run distance in km, scaled by experience.
    /// Maximum long run distance in km. Daniels: LR ≤ 25% of weekly volume or distance cap.
    /// Pfitzinger 18/55: 16mi (26km), 18/70: 20mi (32km), 18/85: 22mi (35km).
    func longRunCapKm(experience: ExperienceLevel) -> Double {
        switch (self, experience) {
        case (.road10K, .beginner):       16
        case (.road10K, .intermediate):   20
        case (.road10K, .advanced):       24
        case (.road10K, .elite):          24
        case (.roadHalf, .beginner):      20
        case (.roadHalf, .intermediate):  23
        case (.roadHalf, .advanced):      26
        case (.roadHalf, .elite):         26
        case (.roadMarathon, .beginner):  30
        case (.roadMarathon, .intermediate): 32
        case (.roadMarathon, .advanced):  35
        case (.roadMarathon, .elite):     35
        }
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
