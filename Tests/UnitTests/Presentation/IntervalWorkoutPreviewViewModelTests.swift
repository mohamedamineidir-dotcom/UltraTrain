import Foundation
import Testing
@testable import UltraTrain

@Suite("IntervalWorkoutPreview ViewModel Tests")
struct IntervalWorkoutPreviewViewModelTests {

    private func makeWorkout(
        durationSeconds: TimeInterval = 3600,
        phases: [IntervalPhase] = []
    ) -> IntervalWorkout {
        IntervalWorkout(
            id: UUID(),
            name: "Test Intervals",
            descriptionText: "Test workout",
            phases: phases,
            category: .speedWork,
            estimatedDurationSeconds: durationSeconds,
            estimatedDistanceKm: 8,
            isUserCreated: true
        )
    }

    @Test("Formatted duration shows minutes for sub-hour workouts")
    @MainActor
    func formattedDurationMinutes() {
        let workout = makeWorkout(durationSeconds: 2700) // 45 min
        let vm = IntervalWorkoutPreviewViewModel(workout: workout)
        #expect(vm.formattedDuration == "45 min")
    }

    @Test("Formatted duration shows hours and minutes for long workouts")
    @MainActor
    func formattedDurationHours() {
        let workout = makeWorkout(durationSeconds: 5400) // 1h 30min
        let vm = IntervalWorkoutPreviewViewModel(workout: workout)
        #expect(vm.formattedDuration == "1h 30m")
    }

    @Test("Work to rest ratio formats correctly")
    @MainActor
    func workToRestRatio() {
        let workout = makeWorkout()
        let vm = IntervalWorkoutPreviewViewModel(workout: workout)
        if workout.workToRestRatio > 0 {
            #expect(vm.formattedWorkToRest.contains(":1"))
        } else {
            #expect(vm.formattedWorkToRest == "--")
        }
    }

    @Test("Total phase count matches flattened phases")
    @MainActor
    func totalPhaseCountMatchesFlattenedPhases() {
        let workout = makeWorkout()
        let vm = IntervalWorkoutPreviewViewModel(workout: workout)
        #expect(vm.totalPhaseCount == vm.flattenedPhases.count)
    }

    @Test("ViewModel exposes workout directly")
    @MainActor
    func exposesWorkout() {
        let workout = makeWorkout()
        let vm = IntervalWorkoutPreviewViewModel(workout: workout)
        #expect(vm.workout.id == workout.id)
        #expect(vm.workout.name == "Test Intervals")
    }
}
