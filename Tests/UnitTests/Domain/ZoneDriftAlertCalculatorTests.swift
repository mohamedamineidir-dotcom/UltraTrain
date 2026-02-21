import Foundation
import Testing
@testable import UltraTrain

@Suite("ZoneDriftAlertCalculator Tests")
struct ZoneDriftAlertCalculatorTests {

    private let config = ZoneDriftAlertCalculator.DriftConfig(
        mildThresholdSeconds: 60,
        moderateThresholdSeconds: 180,
        significantThresholdSeconds: 300,
        cooldownSeconds: 30
    )

    @Test("No alert when in target zone")
    func noAlertInTarget() {
        let state = LiveHRZoneTracker.LiveZoneState(
            currentZone: 2, currentZoneName: "Aerobic",
            timeInCurrentZone: 120, zoneDistribution: [:],
            targetZone: 2, isInTargetZone: true
        )
        let alert = ZoneDriftAlertCalculator.evaluate(state: state, config: config)
        #expect(alert == nil)
    }

    @Test("No alert when no target zone")
    func noAlertNoTarget() {
        let state = LiveHRZoneTracker.LiveZoneState(
            currentZone: 4, currentZoneName: "Threshold",
            timeInCurrentZone: 300, zoneDistribution: [:],
            targetZone: nil, isInTargetZone: false
        )
        let alert = ZoneDriftAlertCalculator.evaluate(state: state, config: config)
        #expect(alert == nil)
    }

    @Test("No alert when drift below threshold")
    func noAlertBelowThreshold() {
        let state = LiveHRZoneTracker.LiveZoneState(
            currentZone: 4, currentZoneName: "Threshold",
            timeInCurrentZone: 30, zoneDistribution: [:],
            targetZone: 2, isInTargetZone: false
        )
        let alert = ZoneDriftAlertCalculator.evaluate(state: state, config: config)
        #expect(alert == nil)
    }

    @Test("Mild alert at 60 seconds")
    func mildAlert() {
        let state = LiveHRZoneTracker.LiveZoneState(
            currentZone: 4, currentZoneName: "Threshold",
            timeInCurrentZone: 60, zoneDistribution: [:],
            targetZone: 2, isInTargetZone: false
        )
        let alert = ZoneDriftAlertCalculator.evaluate(state: state, config: config)
        #expect(alert != nil)
        #expect(alert?.severity == .mild)
        #expect(alert?.currentZone == 4)
        #expect(alert?.targetZone == 2)
    }

    @Test("Moderate alert at 180 seconds")
    func moderateAlert() {
        let state = LiveHRZoneTracker.LiveZoneState(
            currentZone: 4, currentZoneName: "Threshold",
            timeInCurrentZone: 180, zoneDistribution: [:],
            targetZone: 2, isInTargetZone: false
        )
        let alert = ZoneDriftAlertCalculator.evaluate(state: state, config: config)
        #expect(alert?.severity == .moderate)
    }

    @Test("Significant alert at 300 seconds")
    func significantAlert() {
        let state = LiveHRZoneTracker.LiveZoneState(
            currentZone: 4, currentZoneName: "Threshold",
            timeInCurrentZone: 300, zoneDistribution: [:],
            targetZone: 2, isInTargetZone: false
        )
        let alert = ZoneDriftAlertCalculator.evaluate(state: state, config: config)
        #expect(alert?.severity == .significant)
    }

    @Test("Message says slow down when above target")
    func slowDownMessage() {
        let state = LiveHRZoneTracker.LiveZoneState(
            currentZone: 4, currentZoneName: "Threshold",
            timeInCurrentZone: 60, zoneDistribution: [:],
            targetZone: 2, isInTargetZone: false
        )
        let alert = ZoneDriftAlertCalculator.evaluate(state: state, config: config)
        #expect(alert?.message.contains("Slow down") == true)
    }
}
