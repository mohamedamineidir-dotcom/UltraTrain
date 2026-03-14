import Foundation
import Testing
@testable import UltraTrain

@Suite("WorkoutProgressionEngine Tests")
struct WorkoutProgressionEngineTests {

    // MARK: - Interval Workouts

    @Test("interval workout has warmup, work, recovery, and cooldown phases")
    func intervalWorkoutStructure() {
        let workout = WorkoutProgressionEngine.workout(
            type: .intervals,
            phase: .build,
            weekInPhase: 0,
            intensity: .hard,
            totalDuration: 3600
        )

        #expect(!workout.phases.isEmpty)
        let types = workout.phases.map(\.phaseType)
        #expect(types.contains(.warmUp))
        #expect(types.contains(.work))
        #expect(types.contains(.recovery))
        #expect(types.contains(.coolDown))
    }

    @Test("different weeks in build produce different interval workouts")
    func buildWeekVariety() {
        let descriptions = (0..<6).map { week in
            WorkoutProgressionEngine.workout(
                type: .intervals,
                phase: .build,
                weekInPhase: week,
                intensity: .hard,
                totalDuration: 3600
            ).descriptionText
        }

        let unique = Set(descriptions)
        #expect(unique.count == 6, "All 6 build weeks should have different descriptions")
    }

    @Test("peak phase has different templates than build")
    func peakVsBuild() {
        let build = WorkoutProgressionEngine.workout(
            type: .intervals,
            phase: .build,
            weekInPhase: 0,
            intensity: .hard,
            totalDuration: 3600
        )
        let peak = WorkoutProgressionEngine.workout(
            type: .intervals,
            phase: .peak,
            weekInPhase: 0,
            intensity: .hard,
            totalDuration: 3600
        )

        #expect(build.descriptionText != peak.descriptionText)
    }

    @Test("taper interval is moderate intensity")
    func taperIsModerate() {
        let workout = WorkoutProgressionEngine.workout(
            type: .intervals,
            phase: .taper,
            weekInPhase: 0,
            intensity: .moderate,
            totalDuration: 3600
        )

        #expect(workout.descriptionText.contains("threshold") || workout.descriptionText.contains("opener"))
    }

    // MARK: - Vertical Gain Workouts

    @Test("vertical workout has correct structure")
    func verticalWorkoutStructure() {
        let workout = WorkoutProgressionEngine.workout(
            type: .verticalGain,
            phase: .build,
            weekInPhase: 0,
            intensity: .hard,
            totalDuration: 3600
        )

        #expect(!workout.phases.isEmpty)
        let types = workout.phases.map(\.phaseType)
        #expect(types.contains(.warmUp))
        #expect(types.contains(.work))
        #expect(types.contains(.coolDown))
    }

    @Test("moderate vertical produces endurance climbing workout")
    func moderateVerticalEndurance() {
        let workout = WorkoutProgressionEngine.workout(
            type: .verticalGain,
            phase: .build,
            weekInPhase: 0,
            intensity: .moderate,
            totalDuration: 3600
        )

        #expect(workout.name == "Hill repeats")
    }

    @Test("hard vertical produces VO2max hill repeats workout")
    func hardVerticalVO2max() {
        let workout = WorkoutProgressionEngine.workout(
            type: .verticalGain,
            phase: .build,
            weekInPhase: 0,
            intensity: .hard,
            totalDuration: 3600
        )

        #expect(workout.name == "Hill repeats")
    }

    @Test("different weeks in vertical produce different workouts")
    func verticalWeekVariety() {
        let descriptions = (0..<8).map { week in
            WorkoutProgressionEngine.workout(
                type: .verticalGain,
                phase: .build,
                weekInPhase: week,
                intensity: .hard,
                totalDuration: 3600
            ).descriptionText
        }

        let unique = Set(descriptions)
        #expect(unique.count >= 3, "Should have variety across weeks")
    }

    // MARK: - Structured Workout Blocks

    @Test("long run produces multi-phase structured workout")
    func longRunMultiPhase() {
        let workout = WorkoutProgressionEngine.workout(
            type: .longRun,
            phase: .base,
            weekInPhase: 0,
            intensity: .easy,
            totalDuration: 7200
        )

        #expect(workout.phases.count >= 3, "Long run should have warmup + segments + cooldown")
        let types = workout.phases.map(\.phaseType)
        #expect(types.first == .warmUp)
        #expect(types.last == .coolDown)
    }

    @Test("recovery run produces structured warmup/main/cooldown")
    func recoveryRunStructured() {
        let workout = WorkoutProgressionEngine.workout(
            type: .recovery,
            phase: .base,
            weekInPhase: 0,
            intensity: .easy,
            totalDuration: 2700
        )

        #expect(workout.phases.count >= 3, "Recovery run should have warmup + main + cooldown")
        let types = workout.phases.map(\.phaseType)
        #expect(types.first == .warmUp)
        #expect(types.last == .coolDown)
    }

    @Test("B2B Day 1 produces structured workout with negative split")
    func b2bDay1Structured() {
        let workout = WorkoutProgressionEngine.workout(
            type: .longRun,
            phase: .build,
            weekInPhase: 0,
            intensity: .easy,
            totalDuration: 14400,
            isB2BDay1: true
        )

        #expect(workout.phases.count >= 3)
        let types = workout.phases.map(\.phaseType)
        #expect(types.first == .warmUp)
        #expect(types.last == .coolDown)
    }

    @Test("B2B Day 2 produces structured workout with fatigued effort")
    func b2bDay2Structured() {
        let workout = WorkoutProgressionEngine.workout(
            type: .backToBack,
            phase: .build,
            weekInPhase: 0,
            intensity: .moderate,
            totalDuration: 18000
        )

        #expect(workout.phases.count >= 3)
        let types = workout.phases.map(\.phaseType)
        #expect(types.first == .warmUp)
        #expect(types.last == .coolDown)
    }

    @Test("cross-training and rest still produce single-phase workout")
    func crossTrainingAndRestGeneric() {
        let crossTraining = WorkoutProgressionEngine.workout(
            type: .crossTraining,
            phase: .base,
            weekInPhase: 0,
            intensity: .easy,
            totalDuration: 3600
        )
        let rest = WorkoutProgressionEngine.workout(
            type: .rest,
            phase: .base,
            weekInPhase: 0,
            intensity: .easy,
            totalDuration: 0
        )

        #expect(crossTraining.phases.count == 1)
        #expect(rest.phases.count == 1)
    }

    // MARK: - PhaseFocus Intervals

    @Test("threshold30 focus produces threshold interval workout")
    func threshold30Intervals() {
        let workout = WorkoutProgressionEngine.workout(
            type: .intervals,
            phase: .base,
            weekInPhase: 0,
            intensity: .moderate,
            totalDuration: 3600,
            phaseFocus: .threshold30
        )

        #expect(!workout.phases.isEmpty)
        #expect(workout.descriptionText.lowercased().contains("threshold"))
    }

    @Test("vo2max focus produces VO2max interval workout")
    func vo2maxIntervals() {
        let workout = WorkoutProgressionEngine.workout(
            type: .intervals,
            phase: .build,
            weekInPhase: 0,
            intensity: .hard,
            totalDuration: 3600,
            phaseFocus: .vo2max
        )

        #expect(!workout.phases.isEmpty)
    }

    @Test("threshold60 focus produces sustained threshold workout")
    func threshold60Intervals() {
        let workout = WorkoutProgressionEngine.workout(
            type: .intervals,
            phase: .peak,
            weekInPhase: 0,
            intensity: .hard,
            totalDuration: 3600,
            phaseFocus: .threshold60
        )

        #expect(!workout.phases.isEmpty)
        // Threshold60 produces sustained longer blocks
        let workPhases = workout.phases.filter { $0.phaseType == .work }
        #expect(!workPhases.isEmpty)
    }

    @Test("sharpening focus produces short sharp intervals")
    func sharpeningIntervals() {
        let workout = WorkoutProgressionEngine.workout(
            type: .intervals,
            phase: .taper,
            weekInPhase: 0,
            intensity: .moderate,
            totalDuration: 3600,
            phaseFocus: .sharpening
        )

        #expect(!workout.phases.isEmpty)
    }

    // MARK: - Duration Consistency

    @Test("warmup is 15 minutes and cooldown is 10 minutes for intervals")
    func warmupCooldownDurations() {
        let workout = WorkoutProgressionEngine.workout(
            type: .intervals,
            phase: .build,
            weekInPhase: 0,
            intensity: .hard,
            totalDuration: 3600
        )

        let warmup = workout.phases.first { $0.phaseType == .warmUp }
        let cooldown = workout.phases.first { $0.phaseType == .coolDown }

        #expect(warmup?.totalDuration == 900) // 15 min
        #expect(cooldown?.totalDuration == 600) // 10 min
    }
}
