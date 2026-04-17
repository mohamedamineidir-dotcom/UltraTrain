import Foundation

/// Complete library of road-specific interval workout templates.
///
/// 6 categories based on physiological target:
/// A: Speed / Running Economy (R-pace) — neuromuscular recruitment
/// B: VO2max Intervals (I-pace) — aerobic power ceiling
/// C: Lactate Threshold (T-pace) — sustainable speed
/// D: Race-Specific (RP/MP) — race simulation
/// E: Progression Runs — aerobic power at high end
/// F: Long Run Variants — structured endurance builders
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
    }

    enum PaceZone: String, Sendable {
        case easy, marathonPace, threshold, interval, repetition, racePace
    }

    enum RecoveryType: String, Sendable {
        case jog, walk, float, standing
    }

    // MARK: - Template Selection

    /// Returns appropriate templates for the given context.
    static func templates(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel,
        weekInPhase: Int
    ) -> [Template] {
        allTemplates.filter { template in
            template.applicablePhases.contains(phase)
            && template.applicableDistances.contains(discipline)
            && experience.rawSortOrder >= template.minExperience.rawSortOrder
        }
    }

    /// Selects a quality session template for the given slot.
    /// Slot 1 and slot 2 must be DIFFERENT categories (Daniels: variety principle).
    static func selectForSlot(
        slotIndex: Int,
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        experience: ExperienceLevel,
        weekInPhase: Int,
        excludeCategory: Category? = nil
    ) -> Template? {
        let available = templates(
            phase: phase, discipline: discipline,
            experience: experience, weekInPhase: weekInPhase
        ).filter { excludeCategory == nil || $0.category != excludeCategory }

        guard !available.isEmpty else { return nil }

        // Phase-specific category preference (research-based ordering):
        let preferred: [Category]
        switch phase {
        case .base:
            preferred = [.speed, .threshold, .progression]
        case .build:
            preferred = slotIndex == 0
                ? [.vo2max, .speed]
                : [.threshold, .progression]
        case .peak:
            preferred = slotIndex == 0
                ? [.raceSpecific, .vo2max]
                : [.threshold, .raceSpecific]
        case .taper:
            preferred = [.speed, .raceSpecific]
        default:
            preferred = [.threshold]
        }

        // Pick from preferred category, cycling by weekInPhase for variety
        for cat in preferred {
            let inCat = available.filter { $0.category == cat }
            if !inCat.isEmpty {
                return inCat[weekInPhase % inCat.count]
            }
        }

        // Fallback: any available template
        return available[weekInPhase % available.count]
    }

    // MARK: - All Templates

    static let allTemplates: [Template] = {
        var t: [Template] = []
        t.append(contentsOf: speedTemplates)
        t.append(contentsOf: vo2maxTemplates)
        t.append(contentsOf: thresholdTemplates)
        t.append(contentsOf: raceSpecificTemplates)
        t.append(contentsOf: progressionTemplates)
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
            category: .speed, description: "Classic Daniels R-pace 400s. Neuromuscular speed work.",
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
            applicablePhases: [.base, .build], applicableDistances: [.road10K, .roadHalf],
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
            category: .vo2max, description: "5×1000m at I-pace. Daniels staple interval session.",
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
            applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf],
            minExperience: .intermediate
        ),
        Template(
            name: "1600m VO2max",
            category: .vo2max, description: "4×1600m at I-pace. Long VO2max intervals for sustained power.",
            targetPaceZone: .interval, repDistanceM: 1600, repCount: 4,
            recoverySeconds: 210, recoveryType: .jog, totalWorkMinutes: 24,
            applicablePhases: [.build, .peak], applicableDistances: [.road10K, .roadHalf],
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
            category: .threshold, description: "5×1000m at T-pace, 90s rest. Daniels cruise intervals.",
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
            category: .threshold, description: "2×20min at T-pace, 3min jog. Pfitzinger lactate threshold staple.",
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
            category: .raceSpecific, description: "5×3000m at 103% MP with 1000m float. Canova marathon-specific.",
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
            category: .raceSpecific, description: "3×7000m at MP, 1000m jog. Canova special block for advanced.",
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
            category: .progression, description: "25min building from easy to 108% race pace. Canova-style.",
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
