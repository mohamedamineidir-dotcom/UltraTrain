import Foundation
import Testing
@testable import UltraTrain

@Suite("IntervalGuidanceHandler Tests")
@MainActor
struct IntervalGuidanceHandlerTests {

    // MARK: - Helpers

    private func makeWorkout(
        workTrigger: IntervalTrigger = .duration(seconds: 60),
        recoveryTrigger: IntervalTrigger = .duration(seconds: 30),
        workRepeats: Int = 2,
        recoveryRepeats: Int = 2
    ) -> IntervalWorkout {
        IntervalWorkout(
            id: UUID(),
            name: "Test Interval",
            descriptionText: "A test interval workout",
            phases: [
                IntervalPhase(
                    id: UUID(),
                    phaseType: .warmUp,
                    trigger: .duration(seconds: 60),
                    targetIntensity: .easy,
                    repeatCount: 1
                ),
                IntervalPhase(
                    id: UUID(),
                    phaseType: .work,
                    trigger: workTrigger,
                    targetIntensity: .hard,
                    repeatCount: workRepeats
                ),
                IntervalPhase(
                    id: UUID(),
                    phaseType: .recovery,
                    trigger: recoveryTrigger,
                    targetIntensity: .easy,
                    repeatCount: recoveryRepeats
                ),
                IntervalPhase(
                    id: UUID(),
                    phaseType: .coolDown,
                    trigger: .duration(seconds: 60),
                    targetIntensity: .easy,
                    repeatCount: 1
                )
            ],
            category: .speedWork,
            estimatedDurationSeconds: 600,
            estimatedDistanceKm: 3.0,
            isUserCreated: false
        )
    }

    private func makeContext(
        elapsed: TimeInterval = 0,
        distance: Double = 0,
        heartRate: Int? = nil,
        pace: Double = 300
    ) -> IntervalGuidanceHandler.RunContext {
        IntervalGuidanceHandler.RunContext(
            elapsedTime: elapsed,
            distanceKm: distance,
            currentHeartRate: heartRate,
            currentPace: pace
        )
    }

    private func makeHandler(workout: IntervalWorkout?) -> (IntervalGuidanceHandler, MockHapticService) {
        let haptic = MockHapticService()
        let handler = IntervalGuidanceHandler(hapticService: haptic, intervalWorkout: workout)
        return (handler, haptic)
    }

    // MARK: - isActive

    @Test("isActive returns false when no workout provided")
    func isActiveFalseWhenNoWorkout() {
        let (handler, _) = makeHandler(workout: nil)

        #expect(handler.isActive == false)
    }

    @Test("isActive returns true when workout provided")
    func isActiveTrueWhenWorkoutProvided() {
        let workout = makeWorkout()
        let (handler, _) = makeHandler(workout: workout)

        #expect(handler.isActive == true)
    }

    // MARK: - Phase Transition by Duration

    @Test("Tick triggers phase transition when duration elapsed")
    func tickTriggersPhaseTransitionByDuration() {
        let workout = makeWorkout(
            workTrigger: .duration(seconds: 60),
            recoveryTrigger: .duration(seconds: 30)
        )
        let (handler, _) = makeHandler(workout: workout)

        // First tick starts the workout (warmUp phase begins)
        handler.tick(context: makeContext(elapsed: 0, distance: 0))
        #expect(handler.currentState != nil)
        #expect(handler.currentState?.currentPhaseType == .warmUp)

        // Tick at 60s completes warmUp, transitions to work
        handler.tick(context: makeContext(elapsed: 60, distance: 0.3))

        // After transition, we should be in the work phase
        // The split for warmUp should have been recorded
        #expect(handler.intervalSplits.count >= 1)
    }

    // MARK: - Phase Transition by Distance

    @Test("Tick triggers phase transition when distance reached")
    func tickTriggersPhaseTransitionByDistance() {
        let workout = IntervalWorkout(
            id: UUID(),
            name: "Distance Test",
            descriptionText: "",
            phases: [
                IntervalPhase(
                    id: UUID(),
                    phaseType: .work,
                    trigger: .distance(km: 0.5),
                    targetIntensity: .hard,
                    repeatCount: 1
                ),
                IntervalPhase(
                    id: UUID(),
                    phaseType: .coolDown,
                    trigger: .duration(seconds: 60),
                    targetIntensity: .easy,
                    repeatCount: 1
                )
            ],
            category: .speedWork,
            estimatedDurationSeconds: 300,
            estimatedDistanceKm: 1.0,
            isUserCreated: false
        )
        let (handler, _) = makeHandler(workout: workout)

        // Start workout
        handler.tick(context: makeContext(elapsed: 0, distance: 0))
        #expect(handler.currentState?.currentPhaseType == .work)

        // Distance not yet reached
        handler.tick(context: makeContext(elapsed: 60, distance: 0.3))
        #expect(handler.currentState?.currentPhaseType == .work)

        // Distance reached - should transition
        handler.tick(context: makeContext(elapsed: 120, distance: 0.5))
        #expect(handler.intervalSplits.count >= 1)
        #expect(handler.intervalSplits.first?.phaseType == .work)
    }

    // MARK: - Interval Splits Recorded on Phase Completion

    @Test("intervalSplits are recorded when a phase completes")
    func intervalSplitsRecordedOnCompletion() {
        let workout = IntervalWorkout(
            id: UUID(),
            name: "Split Test",
            descriptionText: "",
            phases: [
                IntervalPhase(
                    id: UUID(),
                    phaseType: .work,
                    trigger: .duration(seconds: 30),
                    targetIntensity: .hard,
                    repeatCount: 1
                ),
                IntervalPhase(
                    id: UUID(),
                    phaseType: .coolDown,
                    trigger: .duration(seconds: 30),
                    targetIntensity: .easy,
                    repeatCount: 1
                )
            ],
            category: .speedWork,
            estimatedDurationSeconds: 60,
            estimatedDistanceKm: 0.5,
            isUserCreated: false
        )
        let (handler, _) = makeHandler(workout: workout)

        // Start workout
        handler.tick(context: makeContext(elapsed: 0, distance: 0))
        #expect(handler.intervalSplits.isEmpty)

        // Complete the work phase
        handler.tick(context: makeContext(elapsed: 30, distance: 0.2))
        #expect(handler.intervalSplits.count == 1)

        let split = handler.intervalSplits[0]
        #expect(split.phaseType == .work)
        #expect(split.distanceKm == 0.2)
        #expect(split.duration == 30)
    }

    // MARK: - currentState Updates

    @Test("currentState updates during workout with correct phase info")
    func currentStateUpdatesDuringWorkout() {
        let workout = IntervalWorkout(
            id: UUID(),
            name: "State Test",
            descriptionText: "",
            phases: [
                IntervalPhase(
                    id: UUID(),
                    phaseType: .warmUp,
                    trigger: .duration(seconds: 60),
                    targetIntensity: .easy,
                    repeatCount: 1
                ),
                IntervalPhase(
                    id: UUID(),
                    phaseType: .work,
                    trigger: .duration(seconds: 30),
                    targetIntensity: .hard,
                    repeatCount: 1
                )
            ],
            category: .speedWork,
            estimatedDurationSeconds: 90,
            estimatedDistanceKm: 0.5,
            isUserCreated: false
        )
        let (handler, _) = makeHandler(workout: workout)

        // Before any tick, state should be nil
        #expect(handler.currentState == nil)

        // Start workout
        handler.tick(context: makeContext(elapsed: 0, distance: 0))
        #expect(handler.currentState != nil)
        #expect(handler.currentState?.currentPhaseType == .warmUp)
        #expect(handler.currentState?.targetIntensity == .easy)

        // Midway through warmUp
        handler.tick(context: makeContext(elapsed: 30, distance: 0.1))
        #expect(handler.currentState?.currentPhaseType == .warmUp)
        #expect(handler.currentState?.phaseElapsedTime == 30)
        #expect(handler.currentState?.phaseRemainingTime == 30)
    }

    // MARK: - Haptic Feedback

    @Test("Starting workout triggers interval start haptic")
    func startWorkoutPlaysHaptic() {
        let workout = makeWorkout()
        let (handler, haptic) = makeHandler(workout: workout)

        handler.tick(context: makeContext(elapsed: 0, distance: 0))

        #expect(haptic.playIntervalStartCalled == true)
    }

    // MARK: - No Workout

    @Test("Tick does nothing when no workout provided")
    func tickDoesNothingWithoutWorkout() {
        let (handler, haptic) = makeHandler(workout: nil)

        handler.tick(context: makeContext(elapsed: 10, distance: 0.5))

        #expect(handler.currentState == nil)
        #expect(handler.intervalSplits.isEmpty)
        #expect(haptic.playIntervalStartCalled == false)
    }

    // MARK: - Heart Rate Recorded in Split

    @Test("Heart rate is recorded in interval split when provided")
    func heartRateRecordedInSplit() {
        let workout = IntervalWorkout(
            id: UUID(),
            name: "HR Test",
            descriptionText: "",
            phases: [
                IntervalPhase(
                    id: UUID(),
                    phaseType: .work,
                    trigger: .duration(seconds: 30),
                    targetIntensity: .hard,
                    repeatCount: 1
                ),
                IntervalPhase(
                    id: UUID(),
                    phaseType: .coolDown,
                    trigger: .duration(seconds: 30),
                    targetIntensity: .easy,
                    repeatCount: 1
                )
            ],
            category: .speedWork,
            estimatedDurationSeconds: 60,
            estimatedDistanceKm: 0.5,
            isUserCreated: false
        )
        let (handler, _) = makeHandler(workout: workout)

        handler.tick(context: makeContext(elapsed: 0, distance: 0, heartRate: 150))
        handler.tick(context: makeContext(elapsed: 15, distance: 0.1, heartRate: 160))
        handler.tick(context: makeContext(elapsed: 30, distance: 0.2, heartRate: 170))

        #expect(handler.intervalSplits.count == 1)
        #expect(handler.intervalSplits[0].averageHeartRate != nil)
    }
}
