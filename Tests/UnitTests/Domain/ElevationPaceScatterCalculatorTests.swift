import Foundation
import Testing
@testable import UltraTrain

@Suite("Elevation Pace Scatter Calculator Tests")
struct ElevationPaceScatterCalculatorTests {

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

    /// Build a line of points spaced ~100m apart (0.0009 deg lat ~ 100m), 30s each.
    /// Pace ~5:33/km. Altitude changes per step via `altitudeStep`.
    private func makeTrack(
        pointCount: Int,
        baseAltitude: Double = 100,
        altitudeStep: Double = 0,
        baseLat: Double = 48.0,
        baseLon: Double = 2.0,
        timeStep: Double = 30
    ) -> [TrackPoint] {
        (0..<pointCount).map { i in
            makeTrackPoint(
                lat: baseLat + Double(i) * 0.0009,
                lon: baseLon,
                altitude: baseAltitude + Double(i) * altitudeStep,
                seconds: Double(i) * timeStep
            )
        }
    }

    // MARK: - Tests

    @Test("Empty track returns empty result")
    func emptyTrack() {
        let result = ElevationPaceScatterCalculator.compute(trackPoints: [])
        #expect(result.isEmpty)
    }

    @Test("Too few points for a 200m segment returns empty result")
    func tooFewPoints() {
        // Only one point - not enough for a single segment
        let point = makeTrackPoint(lat: 48.0, lon: 2.0, seconds: 0)
        let result = ElevationPaceScatterCalculator.compute(trackPoints: [point])
        #expect(result.isEmpty)
    }

    @Test("Flat terrain produces gradient near zero")
    func flatTerrain() {
        // 10 points ~100m apart with constant altitude -> should give ~1 segment (>200m)
        let points = makeTrack(pointCount: 10, altitudeStep: 0)
        let result = ElevationPaceScatterCalculator.compute(trackPoints: points)
        #expect(!result.isEmpty)
        for point in result {
            #expect(abs(point.gradientPercent) < 1)
        }
    }

    @Test("Uphill terrain produces positive gradient")
    func uphillTerrain() {
        // 10 points, each +10m altitude (10% gradient over 100m steps)
        let points = makeTrack(pointCount: 10, altitudeStep: 10)
        let result = ElevationPaceScatterCalculator.compute(trackPoints: points)
        #expect(!result.isEmpty)
        for point in result {
            #expect(point.gradientPercent > 0)
        }
    }

    @Test("Extreme gradients above 50 percent are filtered out")
    func extremeGradientFiltered() {
        // 5 points, each +100m altitude over ~100m horizontal -> 100% gradient
        let points = makeTrack(pointCount: 5, altitudeStep: 100)
        let result = ElevationPaceScatterCalculator.compute(trackPoints: points)
        for point in result {
            #expect(abs(point.gradientPercent) <= 50)
        }
    }
}
