import Foundation

enum WorkoutProgressionEngine {

    // MARK: - Public

    static func workout(
        type: SessionType,
        phase: TrainingPhase,
        weekInPhase: Int,
        intensity: Intensity,
        totalDuration: TimeInterval
    ) -> IntervalWorkout {
        let phases: [IntervalPhase]
        let name: String
        let description: String

        switch type {
        case .intervals:
            let template = intervalTemplate(phase: phase, weekInPhase: weekInPhase, intensity: intensity)
            phases = template.phases
            name = template.name
            description = template.description
        case .verticalGain:
            let template = verticalTemplate(phase: phase, weekInPhase: weekInPhase, intensity: intensity)
            phases = template.phases
            name = template.name
            description = template.description
        default:
            return makeGenericWorkout(type: type, duration: totalDuration, intensity: intensity)
        }

        let totalDur = phases.reduce(0.0) { $0 + $1.totalDuration }
        let category: WorkoutCategory = type == .verticalGain ? .hillTraining : .speedWork

        return IntervalWorkout(
            id: UUID(),
            name: name,
            descriptionText: description,
            phases: phases,
            category: category,
            estimatedDurationSeconds: totalDur,
            estimatedDistanceKm: 0,
            isUserCreated: false
        )
    }

    // MARK: - Interval Templates

    private struct WorkoutTemplate {
        let name: String
        let description: String
        let phases: [IntervalPhase]
    }

    private static func intervalTemplate(phase trainingPhase: TrainingPhase, weekInPhase: Int, intensity: Intensity) -> WorkoutTemplate {
        let warmUp = phase(.warmUp, duration: 900, intensity: .easy, reps: 1, notes: "Easy jog, progressive pace")
        let coolDown = phase(.coolDown, duration: 600, intensity: .easy, reps: 1, notes: "Easy jog, stretching")

        let workPhases: (reps: Int, workSec: Double, restSec: Double, desc: String)

        switch trainingPhase {
        case .base:
            // Progressive threshold intervals — moderate intensity, building volume
            let variants: [(Int, Double, Double, String)] = [
                (4, 180, 120, "4×3min at threshold (Z3) / 2min jog"),
                (5, 180, 120, "5×3min at threshold (Z3) / 2min jog"),
                (5, 240, 120, "5×4min at threshold (Z3) / 2min jog"),
                (6, 240, 120, "6×4min at threshold (Z3) / 2min jog"),
                (6, 300, 120, "6×5min at threshold (Z3) / 2min jog"),
                (5, 360, 150, "5×6min at threshold (Z3) / 2min30 jog"),
            ]
            workPhases = variants[min(weekInPhase, variants.count - 1)]

        case .build:
            // VO2max intervals — hard intensity, progressive
            let variants: [(Int, Double, Double, String)] = [
                (6, 180, 120, "6×3min at VO2max (Z4) / 2min jog"),
                (7, 180, 90,  "7×3min at VO2max (Z4) / 90s jog"),
                (5, 240, 120, "5×4min at VO2max (Z4) / 2min jog"),
                (8, 150, 90,  "8×2min30 at VO2max (Z4) / 90s jog"),
                (6, 240, 120, "6×4min at VO2max (Z4) / 2min jog"),
                (10, 120, 60, "10×2min at VO2max (Z4) / 1min jog"),
            ]
            workPhases = variants[weekInPhase % variants.count]

        case .peak:
            // Short sharp intervals — high intensity, race-specific
            let variants: [(Int, Double, Double, String)] = [
                (10, 60, 60,  "10×1min at VO2max (Z4-5) / 1min jog"),
                (8, 90, 60,   "8×90s at VO2max (Z4-5) / 1min jog"),
                (12, 45, 75,  "12×45s max effort (Z5) / 1min15 jog"),
                (6, 120, 60,  "6×2min at VO2max (Z4) / 1min jog"),
                (10, 60, 45,  "10×1min at VO2max (Z4-5) / 45s jog"),
            ]
            workPhases = variants[weekInPhase % variants.count]

        case .taper:
            workPhases = (4, 120, 120, "4×2min at threshold (Z3) / 2min jog")

        default:
            workPhases = (5, 180, 120, "5×3min at threshold (Z3) / 2min jog")
        }

        let work = self.phase(.work, duration: workPhases.workSec, intensity: intensity, reps: workPhases.reps, notes: nil)
        let recovery = self.phase(.recovery, duration: workPhases.restSec, intensity: .easy, reps: workPhases.reps, notes: nil)

        return WorkoutTemplate(
            name: "VO2max intervals",
            description: workPhases.desc,
            phases: [warmUp, work, recovery, coolDown]
        )
    }

    // MARK: - Vertical Gain Templates (Progressive Overload)

    private static func verticalTemplate(phase trainingPhase: TrainingPhase, weekInPhase: Int, intensity: Intensity) -> WorkoutTemplate {
        let warmUp = phase(.warmUp, duration: 900, intensity: .easy, reps: 1, notes: "Easy jog to the climb")
        let coolDown = phase(.coolDown, duration: 600, intensity: .easy, reps: 1, notes: "Easy jog back, stretching")

        let workPhases: (reps: Int, workSec: Double, restSec: Double, desc: String, name: String)

        switch trainingPhase {
        case .base:
            // Aerobic climbing at threshold — progressive reps and duration
            switch weekInPhase {
            case 0...1:
                workPhases = (3, 480, 300, "3×8min climb at threshold (Z3) / 5min jog down", "Aerobic climbing")
            case 2...3:
                workPhases = (4, 480, 300, "4×8min climb at threshold (Z3) / 5min jog down", "Aerobic climbing")
            case 4...5:
                workPhases = (4, 600, 360, "4×10min climb at threshold (Z3) / 6min jog down", "Endurance climbing")
            default:
                workPhases = (5, 600, 360, "5×10min climb at threshold (Z3) / 6min jog down", "Endurance climbing")
            }

        case .build:
            // VO2max climbing — increasing grade and intensity
            switch weekInPhase {
            case 0...1:
                workPhases = (4, 240, 180, "4×4min climb at VO2max (Z4) / 3min jog down", "Hill repeats")
            case 2...3:
                workPhases = (5, 240, 180, "5×4min climb at VO2max (Z4) / 3min jog down", "Hill repeats")
            case 4...5:
                workPhases = (6, 180, 120, "6×3min steep climb at VO2max (Z4) / 2min jog down", "Steep repeats")
            default:
                workPhases = (7, 180, 120, "7×3min steep climb at VO2max (Z4) / 2min jog down", "Steep repeats")
            }

        case .peak:
            // Short explosive efforts — steep grade, race-specific
            switch weekInPhase {
            case 0...1:
                workPhases = (6, 180, 120, "6×3min climb at VO2max (Z4) / 2min jog down", "Power climbing")
            case 2...3:
                workPhases = (8, 120, 120, "8×2min max effort climb (Z5) / 2min jog down", "Max effort climbing")
            default:
                workPhases = (10, 90, 90, "10×90s max effort climb (Z5) / 90s jog down", "Sprint climbing")
            }

        case .taper:
            workPhases = (3, 180, 180, "3×3min climb at threshold (Z3) / 3min jog down", "Maintenance climbing")

        case .recovery, .race:
            workPhases = (2, 240, 240, "2×4min easy climb (Z2) / 4min jog down", "Easy climbing")
        }

        let workIntensity: Intensity = (trainingPhase == .base || trainingPhase == .recovery) ? .moderate : intensity
        let work = self.phase(.work, duration: workPhases.workSec, intensity: workIntensity, reps: workPhases.reps, notes: "Climb at steady effort")
        let recovery = self.phase(.recovery, duration: workPhases.restSec, intensity: .easy, reps: workPhases.reps, notes: "Jog/walk descent")

        return WorkoutTemplate(
            name: workPhases.name,
            description: workPhases.desc,
            phases: [warmUp, work, recovery, coolDown]
        )
    }

    // MARK: - Helpers

    private static func phase(
        _ type: IntervalPhaseType,
        duration: TimeInterval,
        intensity: Intensity,
        reps: Int,
        notes: String?
    ) -> IntervalPhase {
        IntervalPhase(
            id: UUID(),
            phaseType: type,
            trigger: .duration(seconds: duration),
            targetIntensity: intensity,
            repeatCount: reps,
            notes: notes
        )
    }

    private static func makeGenericWorkout(type: SessionType, duration: TimeInterval, intensity: Intensity) -> IntervalWorkout {
        IntervalWorkout(
            id: UUID(),
            name: type.displayName,
            descriptionText: "Steady effort at \(intensity.displayName) intensity.",
            phases: [],
            category: .trailSpecific,
            estimatedDurationSeconds: duration,
            estimatedDistanceKm: 0,
            isUserCreated: false
        )
    }
}
