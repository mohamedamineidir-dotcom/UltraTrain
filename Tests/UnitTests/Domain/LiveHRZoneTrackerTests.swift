import Foundation
import Testing
@testable import UltraTrain

@Suite("LiveHRZoneTracker Tests")
struct LiveHRZoneTrackerTests {

    @Test("Zone classification matches RunStatisticsCalculator")
    func zoneClassification() {
        let state = LiveHRZoneTracker.update(
            heartRate: 150, maxHeartRate: 185,
            customThresholds: nil, targetZone: nil,
            previousState: nil, elapsed: 0
        )
        let expected = RunStatisticsCalculator.heartRateZone(heartRate: 150, maxHeartRate: 185)
        #expect(state.currentZone == expected)
    }

    @Test("Zone name is correct for each zone")
    func zoneNames() {
        // Zone 1: 50-60% of 200 = 100-120
        let z1 = LiveHRZoneTracker.update(heartRate: 110, maxHeartRate: 200, customThresholds: nil, targetZone: nil, previousState: nil, elapsed: 0)
        #expect(z1.currentZoneName == "Recovery")

        // Zone 5: 90-100% of 200 = 180-200
        let z5 = LiveHRZoneTracker.update(heartRate: 190, maxHeartRate: 200, customThresholds: nil, targetZone: nil, previousState: nil, elapsed: 0)
        #expect(z5.currentZoneName == "VO2max")
    }

    @Test("Target zone tracking - in target")
    func inTargetZone() {
        // Zone 2: 60-70% of 200 = 120-140
        let state = LiveHRZoneTracker.update(
            heartRate: 130, maxHeartRate: 200,
            customThresholds: nil, targetZone: 2,
            previousState: nil, elapsed: 0
        )
        #expect(state.isInTargetZone)
        #expect(state.targetZone == 2)
    }

    @Test("Target zone tracking - not in target")
    func notInTargetZone() {
        // HR 170 at maxHR 200 = 85% = Zone 4
        let state = LiveHRZoneTracker.update(
            heartRate: 170, maxHeartRate: 200,
            customThresholds: nil, targetZone: 2,
            previousState: nil, elapsed: 0
        )
        #expect(!state.isInTargetZone)
    }

    @Test("Time in current zone accumulates when staying")
    func timeAccumulation() {
        let s1 = LiveHRZoneTracker.update(
            heartRate: 130, maxHeartRate: 200,
            customThresholds: nil, targetZone: 2,
            previousState: nil, elapsed: 1
        )
        let s2 = LiveHRZoneTracker.update(
            heartRate: 132, maxHeartRate: 200,
            customThresholds: nil, targetZone: 2,
            previousState: s1, elapsed: 2
        )
        let s3 = LiveHRZoneTracker.update(
            heartRate: 128, maxHeartRate: 200,
            customThresholds: nil, targetZone: 2,
            previousState: s2, elapsed: 3
        )
        #expect(s3.timeInCurrentZone >= 2)
    }

    @Test("Time in current zone resets on zone change")
    func timeResetsOnZoneChange() {
        // Zone 2
        let s1 = LiveHRZoneTracker.update(
            heartRate: 130, maxHeartRate: 200,
            customThresholds: nil, targetZone: 2,
            previousState: nil, elapsed: 1
        )
        let s2 = LiveHRZoneTracker.update(
            heartRate: 130, maxHeartRate: 200,
            customThresholds: nil, targetZone: 2,
            previousState: s1, elapsed: 2
        )
        // Jump to Zone 4
        let s3 = LiveHRZoneTracker.update(
            heartRate: 170, maxHeartRate: 200,
            customThresholds: nil, targetZone: 2,
            previousState: s2, elapsed: 3
        )
        #expect(s3.timeInCurrentZone == 0)
    }

    @Test("Zone distribution tracks time per zone")
    func zoneDistribution() {
        let s1 = LiveHRZoneTracker.update(
            heartRate: 130, maxHeartRate: 200,
            customThresholds: nil, targetZone: nil,
            previousState: nil, elapsed: 1
        )
        let s2 = LiveHRZoneTracker.update(
            heartRate: 130, maxHeartRate: 200,
            customThresholds: nil, targetZone: nil,
            previousState: s1, elapsed: 2
        )
        // s2's distribution should have time in zone 2
        let zone2Time = s2.zoneDistribution[s1.currentZone] ?? 0
        #expect(zone2Time > 0)
    }

    @Test("Nil previous state initializes cleanly")
    func nilPreviousState() {
        let state = LiveHRZoneTracker.update(
            heartRate: 150, maxHeartRate: 185,
            customThresholds: nil, targetZone: 3,
            previousState: nil, elapsed: 0
        )
        #expect(state.timeInCurrentZone == 0)
        #expect(state.zoneDistribution.isEmpty)
    }

    @Test("Custom thresholds are passed through")
    func customThresholds() {
        let thresholds = [100, 120, 140, 160, 180]
        let state = LiveHRZoneTracker.update(
            heartRate: 130, maxHeartRate: 200,
            customThresholds: thresholds, targetZone: nil,
            previousState: nil, elapsed: 0
        )
        let expected = RunStatisticsCalculator.heartRateZone(
            heartRate: 130, maxHeartRate: 200, customThresholds: thresholds
        )
        #expect(state.currentZone == expected)
    }

    @Test("No target zone means isInTargetZone is false")
    func noTargetZone() {
        let state = LiveHRZoneTracker.update(
            heartRate: 130, maxHeartRate: 200,
            customThresholds: nil, targetZone: nil,
            previousState: nil, elapsed: 0
        )
        #expect(!state.isInTargetZone)
        #expect(state.targetZone == nil)
    }
}
