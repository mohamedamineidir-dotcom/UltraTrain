import Foundation
import Testing
@testable import UltraTrain

@Suite("Custom Zone Classification Tests")
struct CustomZoneClassificationTests {

    // MARK: - Default Zones

    @Test("Default zones use percentage-based classification")
    func defaultZones() {
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 100, maxHeartRate: 200) == 1)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 130, maxHeartRate: 200) == 2)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 150, maxHeartRate: 200) == 3)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 170, maxHeartRate: 200) == 4)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 190, maxHeartRate: 200) == 5)
    }

    // MARK: - Custom Thresholds

    @Test("Custom thresholds override percentage-based zones")
    func customThresholds() {
        let thresholds = [120, 140, 155, 170]
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 110, maxHeartRate: 200, customThresholds: thresholds) == 1)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 130, maxHeartRate: 200, customThresholds: thresholds) == 2)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 150, maxHeartRate: 200, customThresholds: thresholds) == 3)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 165, maxHeartRate: 200, customThresholds: thresholds) == 4)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 180, maxHeartRate: 200, customThresholds: thresholds) == 5)
    }

    @Test("Boundary values go to lower zone")
    func boundaryValues() {
        let thresholds = [120, 140, 155, 170]
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 120, maxHeartRate: 200, customThresholds: thresholds) == 1)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 140, maxHeartRate: 200, customThresholds: thresholds) == 2)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 155, maxHeartRate: 200, customThresholds: thresholds) == 3)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 170, maxHeartRate: 200, customThresholds: thresholds) == 4)
    }

    @Test("Heart rate above zone4Max is zone 5")
    func aboveZone4Max() {
        let thresholds = [120, 140, 155, 170]
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 171, maxHeartRate: 200, customThresholds: thresholds) == 5)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 200, maxHeartRate: 200, customThresholds: thresholds) == 5)
    }

    @Test("Invalid custom thresholds fall back to default")
    func invalidThresholds() {
        let tooFew = [120, 140]
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 150, maxHeartRate: 200, customThresholds: tooFew) == 3)

        let tooMany = [100, 120, 140, 155, 170]
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 150, maxHeartRate: 200, customThresholds: tooMany) == 3)
    }

    @Test("Nil custom thresholds use default zones")
    func nilThresholds() {
        let zone = RunStatisticsCalculator.heartRateZone(heartRate: 150, maxHeartRate: 200, customThresholds: nil)
        #expect(zone == 3)
    }
}
