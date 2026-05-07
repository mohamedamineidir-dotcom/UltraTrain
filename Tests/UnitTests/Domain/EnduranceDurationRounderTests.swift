import Foundation
import Testing
@testable import UltraTrain

@Suite("EnduranceDurationRounder Tests")
struct EnduranceDurationRounderTests {

    private func makeSession(type: SessionType, duration: TimeInterval) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: Date(),
            type: type,
            plannedDistanceKm: duration / 330.0,
            plannedElevationGainM: 0,
            plannedDuration: duration,
            intensity: .easy,
            description: "",
            isCompleted: false,
            isSkipped: false,
            isKeySession: false
        )
    }

    @Test("Long Run, Recovery, BackToBack round to nearest 5 min")
    func enduranceTypesRound() {
        var sessions: [TrainingSession] = [
            makeSession(type: .longRun, duration: 156 * 60),       // 2h36 → 2h35
            makeSession(type: .longRun, duration: 162 * 60),       // 2h42 → 2h40
            makeSession(type: .longRun, duration: 168 * 60),       // 2h48 → 2h50
            makeSession(type: .recovery, duration: 57 * 60),       // 57 → 55
            makeSession(type: .recovery, duration: 66 * 60),       // 1h06 → 1h05
            makeSession(type: .recovery, duration: 69 * 60),       // 1h09 → 1h10
            makeSession(type: .backToBack, duration: 73 * 60),     // 1h13 → 1h15
        ]

        EnduranceDurationRounder.roundInPlace(&sessions)

        let durations = sessions.map { Int($0.plannedDuration / 60) }
        #expect(durations == [155, 160, 170, 55, 65, 70, 75])
    }

    @Test("Quality sessions keep minute precision")
    func qualityUnchanged() {
        var sessions: [TrainingSession] = [
            makeSession(type: .intervals, duration: 113 * 60),     // 1h53 stays
            makeSession(type: .tempo, duration: 47 * 60),          // 47 stays
            makeSession(type: .verticalGain, duration: 88 * 60),   // 1h28 stays
            makeSession(type: .strengthConditioning, duration: 35 * 60), // 35 stays
        ]
        let before = sessions.map(\.plannedDuration)
        EnduranceDurationRounder.roundInPlace(&sessions)
        let after = sessions.map(\.plannedDuration)
        #expect(before == after)
    }

    @Test("Distance is rescaled with the rounded duration")
    func distanceRescales() {
        var sessions: [TrainingSession] = [
            makeSession(type: .longRun, duration: 168 * 60), // 2h48
        ]
        let originalKm = sessions[0].plannedDistanceKm
        EnduranceDurationRounder.roundInPlace(&sessions)
        // Duration was scaled up by 170/168 → distance should follow.
        let expectedScale = 170.0 / 168.0
        let expectedKm = (originalKm * expectedScale * 10).rounded() / 10
        #expect(sessions[0].plannedDistanceKm == expectedKm)
    }

    @Test("Zero / unset durations are not rounded")
    func zeroLeftAlone() {
        var sessions: [TrainingSession] = [
            makeSession(type: .longRun, duration: 0),
            makeSession(type: .recovery, duration: 0),
        ]
        EnduranceDurationRounder.roundInPlace(&sessions)
        #expect(sessions.allSatisfy { $0.plannedDuration == 0 })
    }
}
