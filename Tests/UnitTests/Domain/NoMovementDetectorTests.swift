import Foundation
import Testing
@testable import UltraTrain

@Suite("NoMovementDetector Tests")
struct NoMovementDetectorTests {

    // MARK: - Tests

    @Test("shouldAlert returns true when threshold exceeded")
    func thresholdExceeded_returnsTrue() {
        let lastMovement = Date.now.addingTimeInterval(-6 * 60) // 6 minutes ago
        let threshold = 5 // 5 minutes

        let result = NoMovementDetector.shouldAlert(
            lastMovementTime: lastMovement,
            currentTime: Date.now,
            thresholdMinutes: threshold,
            isRunPaused: false
        )

        #expect(result == true)
    }

    @Test("shouldAlert returns false when below threshold")
    func belowThreshold_returnsFalse() {
        let lastMovement = Date.now.addingTimeInterval(-3 * 60) // 3 minutes ago
        let threshold = 5 // 5 minutes

        let result = NoMovementDetector.shouldAlert(
            lastMovementTime: lastMovement,
            currentTime: Date.now,
            thresholdMinutes: threshold,
            isRunPaused: false
        )

        #expect(result == false)
    }

    @Test("shouldAlert returns false when run is paused even if threshold exceeded")
    func runPaused_returnsFalse() {
        let lastMovement = Date.now.addingTimeInterval(-10 * 60) // 10 minutes ago
        let threshold = 5 // 5 minutes

        let result = NoMovementDetector.shouldAlert(
            lastMovementTime: lastMovement,
            currentTime: Date.now,
            thresholdMinutes: threshold,
            isRunPaused: true
        )

        #expect(result == false)
    }

    @Test("shouldAlert returns true at exact threshold boundary")
    func exactThreshold_returnsTrue() {
        let now = Date.now
        let lastMovement = now.addingTimeInterval(-5 * 60) // exactly 5 minutes ago

        let result = NoMovementDetector.shouldAlert(
            lastMovementTime: lastMovement,
            currentTime: now,
            thresholdMinutes: 5,
            isRunPaused: false
        )

        #expect(result == true)
    }

    @Test("shouldAlert returns false one second before threshold")
    func justBelowThreshold_returnsFalse() {
        let now = Date.now
        let lastMovement = now.addingTimeInterval(-5 * 60 + 1) // 4 min 59 sec ago

        let result = NoMovementDetector.shouldAlert(
            lastMovementTime: lastMovement,
            currentTime: now,
            thresholdMinutes: 5,
            isRunPaused: false
        )

        #expect(result == false)
    }
}
