import Foundation
import Testing
@testable import UltraTrain

@Suite("ZoneComplianceCalculator Tests")
struct ZoneComplianceCalculatorTests {

    private func makePoints(heartRates: [Int], interval: TimeInterval = 10) -> [TrackPoint] {
        let start = Date.now
        return heartRates.enumerated().map { i, hr in
            TrackPoint(
                latitude: 45.0 + Double(i) * 0.0001,
                longitude: 6.0,
                altitudeM: 500,
                timestamp: start.addingTimeInterval(Double(i) * interval),
                heartRate: hr
            )
        }
    }

    @Test("100% compliance when always in target zone")
    func fullCompliance() {
        // Zone 2: 60-70% of 200 = 120-140
        let points = makePoints(heartRates: [130, 132, 128, 135, 130])
        let result = ZoneComplianceCalculator.calculate(
            trackPoints: points, targetZone: 2, maxHeartRate: 200
        )
        #expect(result.compliancePercent > 95)
        #expect(result.rating == .excellent)
    }

    @Test("0% compliance when never in target zone")
    func zeroCompliance() {
        // Zone 4: 80-90% of 200 = 160-180, but target is zone 2
        let points = makePoints(heartRates: [170, 172, 168, 175, 170])
        let result = ZoneComplianceCalculator.calculate(
            trackPoints: points, targetZone: 2, maxHeartRate: 200
        )
        #expect(result.compliancePercent < 5)
        #expect(result.rating == .poor)
    }

    @Test("Rating thresholds - good")
    func goodRating() {
        // 8 points in Z2, 2 in Z3 -> ~80% compliance
        let hrs = [130, 130, 130, 130, 130, 130, 130, 130, 145, 145]
        let points = makePoints(heartRates: hrs)
        let result = ZoneComplianceCalculator.calculate(
            trackPoints: points, targetZone: 2, maxHeartRate: 200
        )
        #expect(result.rating == .good || result.rating == .excellent)
    }

    @Test("Empty track points returns poor rating")
    func emptyPoints() {
        let result = ZoneComplianceCalculator.calculate(
            trackPoints: [], targetZone: 2, maxHeartRate: 200
        )
        #expect(result.compliancePercent == 0)
        #expect(result.rating == .poor)
    }

    @Test("Single point returns poor rating")
    func singlePoint() {
        let points = makePoints(heartRates: [130])
        let result = ZoneComplianceCalculator.calculate(
            trackPoints: points, targetZone: 2, maxHeartRate: 200
        )
        #expect(result.rating == .poor)
    }

    @Test("Zone distribution sums to approximately 100%")
    func distributionSums() {
        let hrs = [130, 130, 145, 170, 130, 130]
        let points = makePoints(heartRates: hrs)
        let result = ZoneComplianceCalculator.calculate(
            trackPoints: points, targetZone: 2, maxHeartRate: 200
        )
        let total = result.zoneDistribution.values.reduce(0, +)
        #expect(abs(total - 100) < 1)
    }

    @Test("Custom thresholds are passed through")
    func customThresholds() {
        let thresholds = [100, 120, 140, 160, 180]
        let points = makePoints(heartRates: [130, 130, 130])
        let result = ZoneComplianceCalculator.calculate(
            trackPoints: points, targetZone: 2, maxHeartRate: 200,
            customThresholds: thresholds
        )
        #expect(result.totalTimeWithHR > 0)
    }
}
