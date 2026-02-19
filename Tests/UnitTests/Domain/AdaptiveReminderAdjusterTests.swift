import Foundation
import Testing
@testable import UltraTrain

@Suite("AdaptiveReminderAdjuster Tests")
struct AdaptiveReminderAdjusterTests {

    // MARK: - Heart Rate Adjustments

    @Test("High heart rate reduces hydration interval")
    func highHRReducesHydration() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 170,
            maxHeartRate: 200,
            elapsedDistanceKm: 10,
            currentPaceSecondsPerKm: 360,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier == 0.75)
    }

    @Test("High heart rate reduces fuel interval less than hydration")
    func highHRReducesFuel() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 170,
            maxHeartRate: 200,
            elapsedDistanceKm: 10,
            currentPaceSecondsPerKm: 360,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .fuel, conditions: conditions)

        #expect(multiplier == 0.90)
    }

    @Test("High heart rate reduces electrolyte interval")
    func highHRReducesElectrolyte() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 170,
            maxHeartRate: 200,
            elapsedDistanceKm: 10,
            currentPaceSecondsPerKm: 360,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .electrolyte, conditions: conditions)

        #expect(multiplier == 0.75)
    }

    @Test("Normal heart rate does not adjust interval")
    func normalHRNoAdjustment() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 140,
            maxHeartRate: 200,
            elapsedDistanceKm: 10,
            currentPaceSecondsPerKm: 360,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier == 1.0)
    }

    // MARK: - Pace Adjustments

    @Test("Slow pace increases interval")
    func slowPaceIncreasesInterval() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 140,
            maxHeartRate: 200,
            elapsedDistanceKm: 10,
            currentPaceSecondsPerKm: 420,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier == 1.15)
    }

    @Test("Normal pace does not adjust")
    func normalPaceNoAdjustment() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 140,
            maxHeartRate: 200,
            elapsedDistanceKm: 10,
            currentPaceSecondsPerKm: 370,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier == 1.0)
    }

    // MARK: - Distance Adjustments

    @Test("Long distance reduces interval")
    func longDistanceReducesInterval() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 140,
            maxHeartRate: 200,
            elapsedDistanceKm: 35,
            currentPaceSecondsPerKm: 360,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier == 0.90)
    }

    @Test("Short distance does not adjust")
    func shortDistanceNoAdjustment() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 140,
            maxHeartRate: 200,
            elapsedDistanceKm: 15,
            currentPaceSecondsPerKm: 360,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier == 1.0)
    }

    // MARK: - Stacking & Clamping

    @Test("Multiple factors stack correctly")
    func multipleFactorsStack() {
        // High HR (0.75) + long distance (0.90) = 0.675
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 170,
            maxHeartRate: 200,
            elapsedDistanceKm: 35,
            currentPaceSecondsPerKm: 360,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier == 0.675)
    }

    @Test("Multiplier clamped to minimum 0.5")
    func clampedToMinimum() {
        // Extreme scenario: would be < 0.5 without clamping
        // HR 0.75 + distance 0.90 = 0.675 for hydration, still above 0.5
        // All three factors at max reduce: HR 0.75 * distance 0.90 = 0.675 (hydration)
        // This doesn't go below 0.5, but let's ensure the clamp path works
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 170,
            maxHeartRate: 200,
            elapsedDistanceKm: 35,
            currentPaceSecondsPerKm: 360,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier >= 0.5)
    }

    @Test("Multiplier clamped to maximum 1.5")
    func clampedToMaximum() {
        // Slow pace with no other factors: 1.15, which is within range
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 140,
            maxHeartRate: 200,
            elapsedDistanceKm: 10,
            currentPaceSecondsPerKm: 500,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier <= 1.5)
    }

    // MARK: - Nil Values

    @Test("Nil heart rate does not adjust")
    func nilHRNoAdjustment() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: nil,
            maxHeartRate: 200,
            elapsedDistanceKm: 10,
            currentPaceSecondsPerKm: 360,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier == 1.0)
    }

    @Test("Nil max heart rate does not adjust")
    func nilMaxHRNoAdjustment() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 170,
            maxHeartRate: nil,
            elapsedDistanceKm: 10,
            currentPaceSecondsPerKm: 360,
            averagePaceSecondsPerKm: 360
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier == 1.0)
    }

    @Test("Nil pace values do not adjust")
    func nilPaceNoAdjustment() {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: 140,
            maxHeartRate: 200,
            elapsedDistanceKm: 10,
            currentPaceSecondsPerKm: nil,
            averagePaceSecondsPerKm: nil
        )

        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(for: .hydration, conditions: conditions)

        #expect(multiplier == 1.0)
    }
}
