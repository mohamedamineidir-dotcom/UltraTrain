import Foundation

enum WorkoutProgressionEngine {

    // MARK: - Public

    static func workout(
        type: SessionType,
        phase: TrainingPhase,
        weekInPhase: Int,
        intensity: Intensity,
        totalDuration: TimeInterval,
        expectedRaceDuration: TimeInterval = 0,
        isB2BDay1: Bool = false,
        phaseFocus: PhaseFocus? = nil
    ) -> IntervalWorkout {
        let phases: [IntervalPhase]
        let name: String
        let description: String

        switch type {
        case .intervals:
            let template = intervalTemplate(phase: phase, weekInPhase: weekInPhase, intensity: intensity, phaseFocus: phaseFocus)
            phases = template.phases
            name = template.name
            description = template.description
        case .verticalGain:
            let template = verticalTemplate(phase: phase, weekInPhase: weekInPhase, intensity: intensity)
            phases = template.phases
            name = template.name
            description = template.description
        case .tempo:
            let template = tempoTemplate(phase: phase, weekInPhase: weekInPhase, intensity: intensity)
            phases = template.phases
            name = template.name
            description = template.description
        case .longRun where isB2BDay1:
            let template = b2bDay1Template(totalDuration: totalDuration)
            phases = template.phases
            name = template.name
            description = template.description
        case .longRun where phase == .peak && totalDuration >= 2 * 3600:
            let template = longRunPeakTemplate(totalDuration: totalDuration, expectedRaceDuration: expectedRaceDuration)
            phases = template.phases
            name = template.name
            description = template.description
        case .longRun:
            let template = longRunTemplate(totalDuration: totalDuration)
            phases = template.phases
            name = template.name
            description = template.description
        case .backToBack:
            let template = b2bDay2Template(totalDuration: totalDuration)
            phases = template.phases
            name = template.name
            description = template.description
        case .recovery:
            let template = recoveryRunTemplate(totalDuration: totalDuration)
            phases = template.phases
            name = template.name
            description = template.description
        case .crossTraining, .rest:
            return makeGenericWorkout(type: type, duration: totalDuration, intensity: intensity)
        }

        let totalDur = phases.reduce(0.0) { $0 + $1.totalDuration }
        let category: WorkoutCategory = type == .verticalGain ? .hillTraining
            : type == .longRun || type == .backToBack ? .trailSpecific
            : type == .recovery ? .recovery
            : .speedWork

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

    // MARK: - Recovery Run Template

    private static func recoveryRunTemplate(totalDuration: TimeInterval) -> WorkoutTemplate {
        let totalMin = Int(totalDuration) / 60
        let main = phase(.work, duration: totalDuration, intensity: .easy, reps: 1,
                         notes: "Easy conversational pace (Zone 2). Focus on recovery and blood flow.")
        return WorkoutTemplate(
            name: "Easy run",
            description: "Easy run: \(totalMin)min at conversational pace",
            phases: [main]
        )
    }

    // MARK: - Long Run Template (non-peak)

    private static func longRunTemplate(totalDuration: TimeInterval) -> WorkoutTemplate {
        let warmUpDuration: TimeInterval = min(900, totalDuration * 0.15)  // 15min or 15%
        let coolDownDuration: TimeInterval = min(600, totalDuration * 0.10) // 10min or 10%
        let mainDuration = max(totalDuration - warmUpDuration - coolDownDuration, 600)

        let warmUp = phase(.warmUp, duration: warmUpDuration, intensity: .easy, reps: 1,
                           notes: "Progressive warmup — start walking, build to easy jog")

        // Split main effort into nutrition segments (~45min each)
        let segmentLength: TimeInterval = 2700 // 45min
        let segmentCount = max(Int(mainDuration / segmentLength), 1)
        let actualSegment = mainDuration / Double(segmentCount)

        let main = phase(.work, duration: actualSegment, intensity: .easy, reps: segmentCount,
                         notes: segmentCount > 1
                             ? "Easy pace. Eat/drink at each segment break."
                             : "Easy pace throughout.")

        let coolDown = phase(.coolDown, duration: coolDownDuration, intensity: .easy, reps: 1,
                             notes: "Walk to cool down. Stretch. Refuel within 30min.")

        let totalMin = Int(totalDuration) / 60
        return WorkoutTemplate(
            name: "Long run",
            description: "Long run \(totalMin)min: warmup → \(segmentCount)×\(Int(actualSegment)/60)min → cooldown",
            phases: [warmUp, main, coolDown]
        )
    }

    // MARK: - B2B Day 1 Template

    private static func b2bDay1Template(totalDuration: TimeInterval) -> WorkoutTemplate {
        let warmUpDuration: TimeInterval = min(900, totalDuration * 0.12)
        let coolDownDuration: TimeInterval = min(600, totalDuration * 0.08)
        let remaining = max(totalDuration - warmUpDuration - coolDownDuration, 1200)
        let negativeSplitDuration = remaining / 3
        let steadyDuration = remaining - negativeSplitDuration

        let warmUp = phase(.warmUp, duration: warmUpDuration, intensity: .easy, reps: 1,
                           notes: "Progressive warmup")
        let steady = phase(.work, duration: steadyDuration, intensity: .easy, reps: 1,
                           notes: "Steady effort at easy pace. Fuel consistently.")
        let negativeSplit = phase(.work, duration: negativeSplitDuration, intensity: .moderate, reps: 1,
                                  notes: "Negative split — build effort in the last third")
        let coolDown = phase(.coolDown, duration: coolDownDuration, intensity: .easy, reps: 1,
                             notes: "Cool down. Refuel well — tomorrow runs on today's fatigue.")

        return WorkoutTemplate(
            name: "B2B Day 1",
            description: "B2B Day 1: warmup → steady → negative split last third → cooldown",
            phases: [warmUp, steady, negativeSplit, coolDown]
        )
    }

    // MARK: - B2B Day 2 Template

    private static func b2bDay2Template(totalDuration: TimeInterval) -> WorkoutTemplate {
        let warmUpDuration: TimeInterval = min(1200, totalDuration * 0.15) // 20min extra-long
        let coolDownDuration: TimeInterval = min(600, totalDuration * 0.08)
        let remaining = max(totalDuration - warmUpDuration - coolDownDuration, 1200)
        let pushDuration = remaining * 0.20
        let mainDuration = remaining - pushDuration

        let warmUp = phase(.warmUp, duration: warmUpDuration, intensity: .easy, reps: 1,
                           notes: "Extra-long warmup on tired legs. Walk → jog → easy run.")
        let main = phase(.work, duration: mainDuration, intensity: .easy, reps: 1,
                         notes: "Steady fatigued effort at easy pace. Embrace the discomfort.")
        let push = phase(.work, duration: pushDuration, intensity: .moderate, reps: 1,
                         notes: "Push section — build to race effort in the last 20%")
        let coolDown = phase(.coolDown, duration: coolDownDuration, intensity: .easy, reps: 1,
                             notes: "Walk to cool down. Refuel immediately.")

        return WorkoutTemplate(
            name: "B2B Day 2",
            description: "B2B Day 2: warmup → fatigued effort → push last 20% → cooldown",
            phases: [warmUp, main, push, coolDown]
        )
    }

    // MARK: - Interval Templates

    private struct WorkoutTemplate {
        let name: String
        let description: String
        let phases: [IntervalPhase]
    }

    private static func intervalTemplate(
        phase trainingPhase: TrainingPhase,
        weekInPhase: Int,
        intensity: Intensity,
        phaseFocus: PhaseFocus? = nil
    ) -> WorkoutTemplate {
        let warmUp = phase(.warmUp, duration: 900, intensity: .easy, reps: 1, notes: "Easy jog, progressive pace")
        let coolDown = phase(.coolDown, duration: 600, intensity: .easy, reps: 1, notes: "Easy jog, stretching")

        let workPhases: (reps: Int, workSec: Double, restSec: Double, desc: String)

        // Dispatch on PhaseFocus if available, otherwise fallback to TrainingPhase
        let effectiveFocus = phaseFocus ?? trainingPhase.defaultFocus

        switch effectiveFocus {
        case .threshold30:
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

        case .vo2max:
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

        case .threshold60:
            // Sustained threshold — long blocks at race effort
            let variants: [(Int, Double, Double, String)] = [
                (2, 900, 300,  "2×15min at threshold (Z3-4) / 5min jog"),
                (2, 1200, 300, "2×20min at threshold (Z3-4) / 5min jog"),
                (3, 900, 240,  "3×15min at threshold (Z3-4) / 4min jog"),
                (2, 1500, 300, "2×25min at threshold (Z3-4) / 5min jog"),
                (3, 1200, 300, "3×20min at threshold (Z3-4) / 5min jog"),
                (2, 1800, 300, "2×30min at threshold (Z3-4) / 5min jog"),
            ]
            workPhases = variants[weekInPhase % variants.count]

        case .sharpening:
            workPhases = (4, 120, 120, "4×2min at threshold (Z3) / 2min jog")

        case .postRaceRecovery:
            workPhases = (5, 180, 120, "5×3min at threshold (Z3) / 2min jog")
        }

        let work = self.phase(.work, duration: workPhases.workSec, intensity: intensity, reps: workPhases.reps, notes: nil)
        let recovery = self.phase(.recovery, duration: workPhases.restSec, intensity: .easy, reps: workPhases.reps, notes: nil)

        return WorkoutTemplate(
            name: "Interval session",
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

    // MARK: - Tempo Templates

    private static func tempoTemplate(phase trainingPhase: TrainingPhase, weekInPhase: Int, intensity: Intensity) -> WorkoutTemplate {
        let warmUp = phase(.warmUp, duration: 900, intensity: .easy, reps: 1, notes: "Easy jog, build gradually")
        let coolDown = phase(.coolDown, duration: 600, intensity: .easy, reps: 1, notes: "Easy jog, stretching")

        let workPhases: (reps: Int, workSec: Double, restSec: Double, desc: String, name: String)

        switch trainingPhase {
        case .base:
            let variants: [(Int, Double, Double, String, String)] = [
                (2, 600, 180, "2×10min at threshold (Z3) / 3min jog", "Threshold tempo"),
                (2, 720, 180, "2×12min at threshold (Z3) / 3min jog", "Threshold tempo"),
                (2, 900, 300, "2×15min at threshold (Z3) / 5min jog", "Sustained tempo"),
                (2, 900, 240, "2×15min at threshold (Z3) / 4min jog", "Sustained tempo"),
                (3, 600, 180, "3×10min at threshold (Z3) / 3min jog", "Sustained tempo"),
                (2, 1200, 300, "2×20min at threshold (Z3) / 5min jog", "Long tempo"),
            ]
            workPhases = variants[min(weekInPhase, variants.count - 1)]

        case .build:
            let variants: [(Int, Double, Double, String, String)] = [
                (2, 1200, 300, "2×20min at tempo (Z3-Z4) / 5min jog", "Tempo run"),
                (3, 900, 240, "3×15min at tempo (Z3-Z4) / 4min jog", "Tempo run"),
                (2, 1500, 300, "2×25min at tempo (Z3-Z4) / 5min jog", "Long tempo"),
                (3, 1200, 300, "3×20min at tempo (Z3-Z4) / 5min jog", "Long tempo"),
            ]
            workPhases = variants[weekInPhase % variants.count]

        case .peak:
            let variants: [(Int, Double, Double, String, String)] = [
                (3, 600, 180, "3×10min at race pace (Z4) / 3min jog", "Race-pace tempo"),
                (4, 480, 150, "4×8min at race pace (Z4) / 2min30 jog", "Race-pace tempo"),
                (3, 720, 180, "3×12min at race pace (Z4) / 3min jog", "Race-pace tempo"),
            ]
            workPhases = variants[weekInPhase % variants.count]

        case .taper:
            workPhases = (1, 900, 0, "1×15min at threshold (Z3)", "Maintenance tempo")

        default:
            workPhases = (2, 600, 180, "2×10min at threshold (Z3) / 3min jog", "Threshold tempo")
        }

        let work = self.phase(.work, duration: workPhases.workSec, intensity: intensity, reps: workPhases.reps, notes: nil)
        let recovery: IntervalPhase? = workPhases.restSec > 0
            ? self.phase(.recovery, duration: workPhases.restSec, intensity: .easy, reps: max(workPhases.reps - 1, 1), notes: nil)
            : nil

        var phases = [warmUp, work]
        if let recovery { phases.append(recovery) }
        phases.append(coolDown)

        return WorkoutTemplate(
            name: workPhases.name,
            description: workPhases.desc,
            phases: phases
        )
    }

    // MARK: - Long Run Peak Template

    private static func longRunPeakTemplate(totalDuration: TimeInterval, expectedRaceDuration: TimeInterval) -> WorkoutTemplate {
        let warmUp = phase(.warmUp, duration: 1800, intensity: .easy, reps: 1, notes: "Easy pace, settle in")
        let coolDown = phase(.coolDown, duration: 1200, intensity: .easy, reps: 1, notes: "Easy pace to finish")

        let availableTime = totalDuration - 1800 - 1200
        let recoveryBetween: TimeInterval = 1800
        let blockCount = 2
        let totalRecovery = recoveryBetween * Double(blockCount - 1)

        let rawWorkPerBlock = (availableTime - totalRecovery) / Double(blockCount)
        let maxRacePaceTotal = expectedRaceDuration > 0 ? expectedRaceDuration * 0.40 : .infinity
        let cappedWork = min(rawWorkPerBlock, maxRacePaceTotal / Double(blockCount))
        let workPerBlock = max(900, cappedWork)

        let work = phase(.work, duration: workPerBlock, intensity: .moderate, reps: blockCount, notes: "Race effort — maintain steady rhythm")
        let recovery = phase(.recovery, duration: recoveryBetween, intensity: .easy, reps: 1, notes: "Easy jog, recover fully")

        let workMin = Int(workPerBlock) / 60
        let desc = "\(blockCount)×\(workMin)min at race effort / 30min easy"

        return WorkoutTemplate(
            name: "Peak long run",
            description: desc,
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
        let work = phase(.work, duration: duration, intensity: intensity, reps: 1, notes: nil)
        return IntervalWorkout(
            id: UUID(),
            name: type.displayName,
            descriptionText: "Steady \(intensity.displayName) effort",
            phases: [work],
            category: type == .recovery ? .recovery : .trailSpecific,
            estimatedDurationSeconds: duration,
            estimatedDistanceKm: 0,
            isUserCreated: false
        )
    }
}
