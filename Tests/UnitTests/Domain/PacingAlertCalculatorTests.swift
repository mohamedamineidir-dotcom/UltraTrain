import Foundation
import Testing
@testable import UltraTrain

@Suite("Pacing Alert Calculator Tests")
struct PacingAlertCalculatorTests {

    // MARK: - Helpers

    private func makeInput(
        currentPace: Double = 360,
        plannedPace: Double = 300,
        distanceKm: Double = 1.0,
        timeSinceLastAlert: TimeInterval = 120,
        previousAlertType: PacingAlertType? = nil
    ) -> PacingAlertCalculator.Input {
        PacingAlertCalculator.Input(
            currentPaceSecondsPerKm: currentPace,
            plannedPaceSecondsPerKm: plannedPace,
            distanceKm: distanceKm,
            elapsedTimeSinceLastAlert: timeSinceLastAlert,
            previousAlertType: previousAlertType
        )
    }

    // MARK: - Guard Conditions

    @Test("No alert before minimum distance")
    func noAlertBeforeMinDistance() {
        let input = makeInput(distanceKm: 0.3)
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }

    @Test("No alert during cooldown period")
    func noAlertDuringCooldown() {
        let input = makeInput(timeSinceLastAlert: 30)
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }

    @Test("No alert with zero current pace")
    func noAlertZeroCurrentPace() {
        let input = makeInput(currentPace: 0)
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }

    @Test("No alert with zero planned pace")
    func noAlertZeroPlannedPace() {
        let input = makeInput(plannedPace: 0)
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }

    // MARK: - On Pace

    @Test("No alert when pace is within 5% band")
    func noAlertWhenOnPace() {
        let input = makeInput(currentPace: 310, plannedPace: 300) // ~3.3% deviation
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }

    // MARK: - Too Slow

    @Test("Minor too slow alert at 10-20% deviation")
    func minorTooSlow() {
        // 15% slower: 300 * 1.15 = 345
        let input = makeInput(currentPace: 345, plannedPace: 300)
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.type == .tooSlow)
        #expect(result?.severity == .minor)
        #expect(result?.deviationPercent ?? 0 > 0) // positive = slower
    }

    @Test("Major too slow alert above 20% deviation")
    func majorTooSlow() {
        // 25% slower: 300 * 1.25 = 375
        let input = makeInput(currentPace: 375, plannedPace: 300)
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.type == .tooSlow)
        #expect(result?.severity == .major)
    }

    // MARK: - Too Fast

    @Test("Minor too fast alert at 10-20% deviation")
    func minorTooFast() {
        // 15% faster: 300 * 0.85 = 255
        let input = makeInput(currentPace: 255, plannedPace: 300)
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.type == .tooFast)
        #expect(result?.severity == .minor)
        #expect(result?.deviationPercent ?? 0 < 0) // negative = faster
    }

    @Test("Major too fast alert above 20% deviation")
    func majorTooFast() {
        // 25% faster: 300 * 0.75 = 225
        let input = makeInput(currentPace: 225, plannedPace: 300)
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.type == .tooFast)
        #expect(result?.severity == .major)
    }

    // MARK: - Back on Pace

    @Test("Back on pace after too slow deviation")
    func backOnPaceAfterTooSlow() {
        let input = makeInput(
            currentPace: 305, plannedPace: 300,
            previousAlertType: .tooSlow
        )
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.type == .backOnPace)
        #expect(result?.severity == .positive)
    }

    @Test("Back on pace after too fast deviation")
    func backOnPaceAfterTooFast() {
        let input = makeInput(
            currentPace: 298, plannedPace: 300,
            previousAlertType: .tooFast
        )
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result != nil)
        #expect(result?.type == .backOnPace)
        #expect(result?.severity == .positive)
    }

    @Test("No back-on-pace without prior deviation")
    func noBackOnPaceWithoutPrior() {
        let input = makeInput(currentPace: 305, plannedPace: 300)
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }

    // MARK: - Deviation Percentage

    @Test("Deviation percent is correctly signed")
    func deviationPercentCorrectlySigned() {
        // Too slow: positive deviation
        let slowInput = makeInput(currentPace: 345, plannedPace: 300)
        let slowResult = PacingAlertCalculator.evaluate(slowInput)
        #expect(slowResult?.deviationPercent ?? -1 > 0)

        // Too fast: negative deviation
        let fastInput = makeInput(currentPace: 255, plannedPace: 300)
        let fastResult = PacingAlertCalculator.evaluate(fastInput)
        #expect(fastResult?.deviationPercent ?? 1 < 0)
    }

    @Test("Message contains deviation percentage")
    func messageContainsPercentage() {
        let input = makeInput(currentPace: 345, plannedPace: 300) // 15%
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result?.message.contains("15") == true)
    }

    // MARK: - Threshold Boundaries

    @Test("No alert between 5% and 10% deviation")
    func noAlertBetweenBands() {
        // 8% deviation: 300 * 1.08 = 324
        let input = makeInput(currentPace: 324, plannedPace: 300)
        let result = PacingAlertCalculator.evaluate(input)
        #expect(result == nil)
    }
}
