import Foundation
import Testing
@testable import UltraTrain

@Suite("IntervalWorkout Tests")
struct IntervalWorkoutTests {

    // MARK: - Helpers

    private func makePhase(
        phaseType: IntervalPhaseType,
        trigger: IntervalTrigger,
        repeatCount: Int = 1
    ) -> IntervalPhase {
        IntervalPhase(
            id: UUID(),
            phaseType: phaseType,
            trigger: trigger,
            targetIntensity: .moderate,
            repeatCount: repeatCount
        )
    }

    private func makeWorkout(phases: [IntervalPhase]) -> IntervalWorkout {
        IntervalWorkout(
            id: UUID(),
            name: "Test Workout",
            descriptionText: "A test workout",
            phases: phases,
            category: .speedWork,
            estimatedDurationSeconds: 3600,
            estimatedDistanceKm: 10.0,
            isUserCreated: false
        )
    }

    // MARK: - totalWorkDuration

    @Test("totalWorkDuration sums work phases with duration triggers")
    func totalWorkDurationSumsDurationPhases() {
        let phases = [
            makePhase(phaseType: .warmUp, trigger: .duration(seconds: 600)),
            makePhase(phaseType: .work, trigger: .duration(seconds: 180), repeatCount: 4),
            makePhase(phaseType: .recovery, trigger: .duration(seconds: 120), repeatCount: 4),
            makePhase(phaseType: .coolDown, trigger: .duration(seconds: 600))
        ]
        let workout = makeWorkout(phases: phases)

        // work: 180 * 4 = 720
        #expect(workout.totalWorkDuration == 720)
    }

    @Test("totalWorkDuration returns 0 for distance-based work phases")
    func totalWorkDurationZeroForDistancePhases() {
        let phases = [
            makePhase(phaseType: .work, trigger: .distance(km: 1.0), repeatCount: 4)
        ]
        let workout = makeWorkout(phases: phases)

        #expect(workout.totalWorkDuration == 0)
    }

    // MARK: - totalRecoveryDuration

    @Test("totalRecoveryDuration sums recovery phases with duration triggers")
    func totalRecoveryDurationSumsDurationPhases() {
        let phases = [
            makePhase(phaseType: .work, trigger: .duration(seconds: 180), repeatCount: 4),
            makePhase(phaseType: .recovery, trigger: .duration(seconds: 120), repeatCount: 4)
        ]
        let workout = makeWorkout(phases: phases)

        // recovery: 120 * 4 = 480
        #expect(workout.totalRecoveryDuration == 480)
    }

    @Test("totalRecoveryDuration returns 0 when no recovery phases")
    func totalRecoveryDurationZeroWhenNoRecovery() {
        let phases = [
            makePhase(phaseType: .work, trigger: .duration(seconds: 180), repeatCount: 4)
        ]
        let workout = makeWorkout(phases: phases)

        #expect(workout.totalRecoveryDuration == 0)
    }

    // MARK: - intervalCount

    @Test("intervalCount sums repeat counts across work phases")
    func intervalCountSumsWorkRepeats() {
        let phases = [
            makePhase(phaseType: .warmUp, trigger: .duration(seconds: 600)),
            makePhase(phaseType: .work, trigger: .duration(seconds: 180), repeatCount: 4),
            makePhase(phaseType: .recovery, trigger: .duration(seconds: 120), repeatCount: 4),
            makePhase(phaseType: .work, trigger: .duration(seconds: 60), repeatCount: 2),
            makePhase(phaseType: .coolDown, trigger: .duration(seconds: 600))
        ]
        let workout = makeWorkout(phases: phases)

        #expect(workout.intervalCount == 6)
    }

    @Test("intervalCount returns 0 when no work phases")
    func intervalCountZeroWhenNoWork() {
        let phases = [
            makePhase(phaseType: .warmUp, trigger: .duration(seconds: 600)),
            makePhase(phaseType: .coolDown, trigger: .duration(seconds: 600))
        ]
        let workout = makeWorkout(phases: phases)

        #expect(workout.intervalCount == 0)
    }

    // MARK: - estimatedDurationSeconds and estimatedDistanceKm

    @Test("estimatedDurationSeconds stores provided value")
    func estimatedDurationSecondsStoresValue() {
        let workout = IntervalWorkout(
            id: UUID(),
            name: "Quick Test",
            descriptionText: "",
            phases: [],
            category: .speedWork,
            estimatedDurationSeconds: 2400,
            estimatedDistanceKm: 7.0,
            isUserCreated: false
        )

        #expect(workout.estimatedDurationSeconds == 2400)
    }

    @Test("estimatedDistanceKm stores provided value")
    func estimatedDistanceKmStoresValue() {
        let workout = IntervalWorkout(
            id: UUID(),
            name: "Quick Test",
            descriptionText: "",
            phases: [],
            category: .speedWork,
            estimatedDurationSeconds: 2400,
            estimatedDistanceKm: 7.5,
            isUserCreated: false
        )

        #expect(workout.estimatedDistanceKm == 7.5)
    }

    // MARK: - Empty Phases

    @Test("All computed properties return 0 with empty phases")
    func emptyPhasesReturnZero() {
        let workout = makeWorkout(phases: [])

        #expect(workout.totalWorkDuration == 0)
        #expect(workout.totalRecoveryDuration == 0)
        #expect(workout.intervalCount == 0)
        #expect(workout.workToRestRatio == 0)
    }

    // MARK: - workToRestRatio

    @Test("workToRestRatio returns work divided by recovery")
    func workToRestRatioCalculation() {
        let phases = [
            makePhase(phaseType: .work, trigger: .duration(seconds: 180), repeatCount: 4),
            makePhase(phaseType: .recovery, trigger: .duration(seconds: 90), repeatCount: 4)
        ]
        let workout = makeWorkout(phases: phases)

        // work: 180 * 4 = 720, recovery: 90 * 4 = 360
        #expect(workout.workToRestRatio == 2.0)
    }

    @Test("workToRestRatio returns 0 when no recovery")
    func workToRestRatioZeroWhenNoRecovery() {
        let phases = [
            makePhase(phaseType: .work, trigger: .duration(seconds: 180), repeatCount: 4)
        ]
        let workout = makeWorkout(phases: phases)

        #expect(workout.workToRestRatio == 0)
    }
}
