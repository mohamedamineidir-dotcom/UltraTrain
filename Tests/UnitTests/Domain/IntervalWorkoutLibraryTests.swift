import Foundation
import Testing
@testable import UltraTrain

@Suite("IntervalWorkoutLibrary Tests")
struct IntervalWorkoutLibraryTests {

    // MARK: - All Workouts

    @Test("allWorkouts returns a non-empty list")
    func allWorkoutsNonEmpty() {
        #expect(!IntervalWorkoutLibrary.allWorkouts.isEmpty)
    }

    @Test("allWorkouts contains expected number of templates")
    func allWorkoutsCount() {
        #expect(IntervalWorkoutLibrary.allWorkouts.count == 8)
    }

    // MARK: - Valid Phases

    @Test("All templates have at least one phase")
    func allTemplatesHavePhases() {
        for workout in IntervalWorkoutLibrary.allWorkouts {
            #expect(!workout.phases.isEmpty, "Workout '\(workout.name)' has no phases")
        }
    }

    @Test("All templates have at least one work phase")
    func allTemplatesHaveWorkPhase() {
        for workout in IntervalWorkoutLibrary.allWorkouts {
            let hasWork = workout.phases.contains { $0.phaseType == .work }
            #expect(hasWork, "Workout '\(workout.name)' has no work phase")
        }
    }

    @Test("All phases have positive repeat counts")
    func allPhasesHavePositiveRepeatCount() {
        for workout in IntervalWorkoutLibrary.allWorkouts {
            for phase in workout.phases {
                #expect(phase.repeatCount > 0, "Workout '\(workout.name)' has a phase with repeatCount \(phase.repeatCount)")
            }
        }
    }

    // MARK: - No Duplicate IDs

    @Test("No duplicate workout IDs")
    func noDuplicateWorkoutIDs() {
        let ids = IntervalWorkoutLibrary.allWorkouts.map(\.id)
        let uniqueIds = Set(ids)

        #expect(ids.count == uniqueIds.count)
    }

    @Test("No duplicate phase IDs across all workouts")
    func noDuplicatePhaseIDs() {
        let allPhaseIds = IntervalWorkoutLibrary.allWorkouts.flatMap { $0.phases.map(\.id) }
        let uniquePhaseIds = Set(allPhaseIds)

        #expect(allPhaseIds.count == uniquePhaseIds.count)
    }

    // MARK: - Name and Duration

    @Test("Each workout has a non-empty name")
    func allWorkoutsHaveNames() {
        for workout in IntervalWorkoutLibrary.allWorkouts {
            #expect(!workout.name.isEmpty, "Workout has empty name")
        }
    }

    @Test("Each workout has a valid estimatedDurationSeconds greater than zero")
    func allWorkoutsHavePositiveDuration() {
        for workout in IntervalWorkoutLibrary.allWorkouts {
            #expect(workout.estimatedDurationSeconds > 0, "Workout '\(workout.name)' has non-positive duration")
        }
    }

    @Test("Each workout has a non-empty description")
    func allWorkoutsHaveDescription() {
        for workout in IntervalWorkoutLibrary.allWorkouts {
            #expect(!workout.descriptionText.isEmpty, "Workout '\(workout.name)' has empty description")
        }
    }

    @Test("No library workout is marked as user-created")
    func noWorkoutIsUserCreated() {
        for workout in IntervalWorkoutLibrary.allWorkouts {
            #expect(!workout.isUserCreated, "Workout '\(workout.name)' is marked as user-created")
        }
    }
}
