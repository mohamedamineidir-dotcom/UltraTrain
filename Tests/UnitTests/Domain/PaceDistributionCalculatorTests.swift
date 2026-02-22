import Foundation
import Testing
@testable import UltraTrain

@Suite("Pace Distribution Calculator Tests")
struct PaceDistributionCalculatorTests {

    // MARK: - Helpers

    private func makeTrackPoint(
        lat: Double, lon: Double, altitude: Double = 100, seconds: TimeInterval
    ) -> TrackPoint {
        TrackPoint(
            latitude: lat,
            longitude: lon,
            altitudeM: altitude,
            timestamp: Date(timeIntervalSinceReferenceDate: seconds),
            heartRate: nil
        )
    }

    /// Build a straight-line track with evenly spaced points at ~5:00/km pace.
    /// Each step: 10s apart, ~33m apart (0.0003 deg lat ~ 33m).
    private func makeSteadyTrack(pointCount: Int, baseLat: Double = 48.0, baseLon: Double = 2.0) -> [TrackPoint] {
        (0..<pointCount).map { i in
            makeTrackPoint(
                lat: baseLat + Double(i) * 0.0003,
                lon: baseLon,
                seconds: Double(i) * 10
            )
        }
    }

    // MARK: - Tests

    @Test("Empty track returns empty buckets")
    func emptyTrack() {
        let result = PaceDistributionCalculator.compute(trackPoints: [])
        #expect(result.isEmpty)
    }

    @Test("Single point returns empty buckets")
    func singlePoint() {
        let point = makeTrackPoint(lat: 0, lon: 0, seconds: 0)
        let result = PaceDistributionCalculator.compute(trackPoints: [point])
        #expect(result.isEmpty)
    }

    @Test("Steady pace track produces non-empty buckets with positive duration")
    func steadyPace() {
        // 20 points at ~5:00/km pace, 10s apart
        let points = makeSteadyTrack(pointCount: 20)
        let result = PaceDistributionCalculator.compute(trackPoints: points)
        #expect(!result.isEmpty)
        #expect(result.allSatisfy { $0.durationSeconds > 0 })
    }

    @Test("Outlier paces faster than 2:00/km are filtered out")
    func outlierFiltering() {
        // Two points very far apart (1km) but only 10s apart -> ~10s/km, way under 120s threshold
        let points = [
            makeTrackPoint(lat: 48.0, lon: 2.0, seconds: 0),
            makeTrackPoint(lat: 48.009, lon: 2.0, seconds: 10),
        ]
        let result = PaceDistributionCalculator.compute(trackPoints: points)
        #expect(result.isEmpty)
    }

    @Test("Buckets are sorted by pace ascending")
    func sortedBuckets() {
        let points = makeSteadyTrack(pointCount: 30)
        let result = PaceDistributionCalculator.compute(trackPoints: points)
        if result.count >= 2 {
            for i in 1..<result.count {
                #expect(result[i - 1].rangeLowerSeconds <= result[i].rangeLowerSeconds)
            }
        }
    }

    @Test("Percentages sum to approximately 100")
    func percentagesSum() {
        let points = makeSteadyTrack(pointCount: 40)
        let result = PaceDistributionCalculator.compute(trackPoints: points)
        guard !result.isEmpty else { return }
        let totalPct = result.reduce(0) { $0 + $1.percentage }
        #expect(totalPct > 99 && totalPct < 101)
    }
}
