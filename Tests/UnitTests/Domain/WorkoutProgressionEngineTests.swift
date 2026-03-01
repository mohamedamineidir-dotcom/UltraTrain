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

        #expect(workout.descriptionText.contains("moderate"))
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

        #expect(workout.name == "Endurance climbing")
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

        #expect(workout.name == "VO2max hill repeats")
    }

    @Test("different weeks in vertical produce different workouts")
    func verticalWeekVariety() {
        let descriptions = (0..<6).map { week in
            WorkoutProgressionEngine.workout(
                type: .verticalGain,
                phase: .build,
                weekInPhase: week,
                intensity: .hard,
                totalDuration: 3600
            ).descriptionText
        }

        let unique = Set(descriptions)
        #expect(unique.count >= 4, "Should have variety across weeks")
    }

    // MARK: - Generic Workouts

    @Test("non-interval type produces generic workout")
    func genericWorkout() {
        let workout = WorkoutProgressionEngine.workout(
            type: .longRun,
            phase: .base,
            weekInPhase: 0,
            intensity: .easy,
            totalDuration: 7200
        )

        #expect(workout.phases.isEmpty)
        #expect(workout.estimatedDurationSeconds == 7200)
    }

    // MARK: - Duration Consistency

    @Test("warmup is 15 minutes and cooldown is 10 minutes")
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
