import Foundation
import Testing
@testable import UltraTrain

@Suite("Race Pacing Alert Calculator Tests")
struct RacePacingAlertCalculatorTests {

    // MARK: - Helpers

    private func makeInput(
        currentPace: Double = 360,
        targetPace: Double = 300,
        segmentName: String = "CP2",
        distanceKm: Double = 1.0,
        timeSinceLastAlert: TimeInterval = 120,
        previousAlertType: PacingAlertType? = nil
    ) -> RacePacingAlertCalculator.Input {
        RacePacingAlertCalculator.Input(
            currentPaceSecondsPerKm: currentPace,
            segmentTargetPaceSecondsPerKm: targetPace,
            segmentName: segmentName,
            distanceKm: distanceKm,
            elapsedTimeSinceLastAlert: timeSinceLastAlert,
            previousAlertType: previousAlertType
        )
    }

    // MARK: - Guard Conditions

    @Test("No alert before minimum distance")
    func noAlertBeforeMinDistance() {
        let input = makeInput(distanceKm: 0.3)
        let result = RacePacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }

    @Test("No alert during cooldown period")
    func noAlertDuringCooldown() {
        let input = makeInput(timeSinceLastAlert: 30)
        let result = RacePacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }

    @Test("No alert within on-pace band")
    func noAlertWithinOnPaceBand() {
        let input = makeInput(currentPace: 310, targetPace: 300)
        let result = RacePacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }

    // MARK: - Alert Types

    @Test("Minor alert at 12% deviation — too slow")
    func minorAlertTooSlow() {
        let input = makeInput(currentPace: 336, targetPace: 300)
        let result = RacePacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.type == .tooSlow)
        #expect(result?.severity == .minor)
    }

    @Test("Major alert at 25% deviation — too slow")
    func majorAlertTooSlow() {
        let input = makeInput(currentPace: 375, targetPace: 300)
        let result = RacePacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.type == .tooSlow)
        #expect(result?.severity == .major)
    }

    @Test("Too fast — negative pace deviation")
    func tooFastAlert() {
        let input = makeInput(currentPace: 258, targetPace: 300)
        let result = RacePacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.type == .tooFast)
        #expect(result?.severity == .minor)
    }

    @Test("Back on pace after prior deviation")
    func backOnPaceAlert() {
        let input = makeInput(
            currentPace: 302,
            targetPace: 300,
            previousAlertType: .tooSlow
        )
        let result = RacePacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.type == .backOnPace)
        #expect(result?.severity == .positive)
    }

    @Test("Message includes segment name")
    func messageIncludesSegmentName() {
        let input = makeInput(
            currentPace: 375,
            targetPace: 300,
            segmentName: "Aid Station 3"
        )
        let result = RacePacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.message.contains("Aid Station 3") == true)
    }

    @Test("No alert with zero target pace")
    func noAlertZeroTargetPace() {
        let input = makeInput(targetPace: 0)
        let result = RacePacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }
}
