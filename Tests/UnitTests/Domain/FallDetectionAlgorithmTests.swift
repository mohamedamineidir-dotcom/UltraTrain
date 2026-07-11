import Foundation
import Testing
@testable import UltraTrain

@Suite("FallDetectionAlgorithm Tests")
struct FallDetectionAlgorithmTests {

    // MARK: - Helpers

    private func makeReading(
        timestamp: Date = Date.now,
        x: Double = 0,
        y: Double = 0,
        z: Double = 1.0
    ) -> MotionReading {
        MotionReading(
            timestamp: timestamp,
            accelerationX: x,
            accelerationY: y,
            accelerationZ: z
        )
    }

    /// Creates a set of readings simulating an impact followed by stillness.
    /// Default `count` spans 5.5s after the impact (11 readings * 0.5s) —
    /// comfortably over `stillnessDurationSeconds` (5.0s), since the
    /// algorithm now requires the buffer to actually span the full window
    /// before concluding stillness.
    private func makeImpactThenStillReadings(
        impactG: Double,
        stillnessAcceleration: Double = 1.0,
        count: Int = 17,
        impactIndex: Int = 5
    ) -> [MotionReading] {
        let baseTime = Date.now
        var readings: [MotionReading] = []
        for i in 0..<count {
            let timestamp = baseTime.addingTimeInterval(Double(i) * 0.5)
            if i == impactIndex {
                // Impact reading: all acceleration on Z axis for simplicity
                readings.append(makeReading(timestamp: timestamp, x: 0, y: 0, z: impactG))
            } else {
                // Normal or still reading (~1g total)
                readings.append(makeReading(timestamp: timestamp, x: 0, y: 0, z: stillnessAcceleration))
            }
        }
        return readings
    }

    /// Creates readings simulating impact followed by continued movement.
    private func makeImpactThenMovementReadings(
        impactG: Double,
        movementAcceleration: Double = 2.5,
        count: Int = 15,
        impactIndex: Int = 5
    ) -> [MotionReading] {
        let baseTime = Date.now
        var readings: [MotionReading] = []
        for i in 0..<count {
            let timestamp = baseTime.addingTimeInterval(Double(i) * 0.5)
            if i == impactIndex {
                readings.append(makeReading(timestamp: timestamp, x: 0, y: 0, z: impactG))
            } else {
                readings.append(makeReading(timestamp: timestamp, x: 0, y: 0, z: movementAcceleration))
            }
        }
        return readings
    }

    // MARK: - Tests

    @Test("High impact followed by stillness detects a fall")
    func highImpactPlusStillness_fallDetected() {
        let readings = makeImpactThenStillReadings(impactG: 5.0)

        let result = FallDetectionAlgorithm.analyze(readings: readings)

        #expect(result.isFallDetected == true)
        #expect(result.impactG >= FallDetectionAlgorithm.impactThresholdG)
        #expect(result.stillnessAfterImpact == true)
    }

    @Test("High impact followed by continued movement does not detect a fall")
    func highImpactPlusMovement_noFall() {
        let readings = makeImpactThenMovementReadings(impactG: 5.0)

        let result = FallDetectionAlgorithm.analyze(readings: readings)

        #expect(result.isFallDetected == false)
        #expect(result.impactG >= FallDetectionAlgorithm.impactThresholdG)
        #expect(result.stillnessAfterImpact == false)
    }

    @Test("Low impact followed by stillness does not detect a fall")
    func lowImpactPlusStillness_noFall() {
        let readings = makeImpactThenStillReadings(impactG: 1.5)

        let result = FallDetectionAlgorithm.analyze(readings: readings)

        #expect(result.isFallDetected == false)
        #expect(result.impactG < FallDetectionAlgorithm.impactThresholdG)
    }

    @Test("Insufficient readings returns no fall")
    func insufficientReadings_noFall() {
        let readings = (0..<5).map { i in
            makeReading(timestamp: Date.now.addingTimeInterval(Double(i) * 0.5), x: 0, y: 0, z: 5.0)
        }

        let result = FallDetectionAlgorithm.analyze(readings: readings)

        #expect(result.isFallDetected == false)
        #expect(result.impactG == 0)
        #expect(result.stillnessAfterImpact == false)
    }

    @Test("Exactly at impact threshold with stillness detects a fall")
    func borderlineThreshold_exactImpact_fallDetected() {
        let readings = makeImpactThenStillReadings(
            impactG: FallDetectionAlgorithm.impactThresholdG
        )

        let result = FallDetectionAlgorithm.analyze(readings: readings)

        #expect(result.isFallDetected == true)
        #expect(result.impactG == FallDetectionAlgorithm.impactThresholdG)
    }

    @Test("Just below impact threshold does not detect a fall")
    func borderlineThreshold_belowImpact_noFall() {
        let readings = makeImpactThenStillReadings(
            impactG: FallDetectionAlgorithm.impactThresholdG - 0.01
        )

        let result = FallDetectionAlgorithm.analyze(readings: readings)

        #expect(result.isFallDetected == false)
    }

    @Test("Empty readings returns no fall")
    func emptyReadings_noFall() {
        let result = FallDetectionAlgorithm.analyze(readings: [])

        #expect(result.isFallDetected == false)
        #expect(result.impactG == 0)
        #expect(result.stillnessAfterImpact == false)
    }

    @Test("Footstrike-sized impact with only a brief calm window (buffer hasn't filled) does not detect a fall")
    func footstrikeImpactWithBriefWindow_noFall() {
        // Real-world false positive this test guards against: early in a
        // run the accelerometer buffer hasn't accumulated much history
        // yet, so a single hard footstrike (a transient impact above
        // threshold) is immediately followed by only ~1s of relatively
        // calm samples before the buffer ends — NOT a genuine 5s
        // stillness period, just "however much data exists so far."
        let baseTime = Date.now
        var readings: [MotionReading] = []
        for i in 0..<10 {
            readings.append(makeReading(timestamp: baseTime.addingTimeInterval(Double(i) * 0.1), x: 0, y: 0, z: 1.0))
        }
        readings.append(makeReading(timestamp: baseTime.addingTimeInterval(1.0), x: 0, y: 0, z: 3.5)) // footstrike
        // Only two calm samples follow, spanning 0.2s — nowhere near the
        // required 5.0s stillness window.
        readings.append(makeReading(timestamp: baseTime.addingTimeInterval(1.1), x: 0, y: 0, z: 1.0))
        readings.append(makeReading(timestamp: baseTime.addingTimeInterval(1.2), x: 0, y: 0, z: 1.0))

        let result = FallDetectionAlgorithm.analyze(readings: readings)

        #expect(result.isFallDetected == false)
        #expect(result.impactG >= FallDetectionAlgorithm.impactThresholdG)
    }
}
