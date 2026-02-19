import Foundation
import Testing
@testable import UltraTrain

@Suite("Elevation Segment Builder Tests")
struct ElevationSegmentBuilderTests {

    // MARK: - Helpers

    private func makeTrackPoints(
        count: Int,
        altitudeGenerator: (Int) -> Double = { _ in 500.0 }
    ) -> [TrackPoint] {
        let baseDate = Date.now
        return (0..<count).map { i in
            TrackPoint(
                latitude: 45.0 + Double(i) * 0.001,
                longitude: 6.0,
                altitudeM: altitudeGenerator(i),
                timestamp: baseDate.addingTimeInterval(Double(i) * 10),
                heartRate: nil
            )
        }
    }

    // MARK: - Empty / Edge Cases

    @Test("Empty track returns empty segments")
    func emptyTrack() {
        let result = ElevationCalculator.buildElevationSegments(from: [])
        #expect(result.isEmpty)
    }

    @Test("Single point track returns empty segments")
    func singlePoint() {
        let points = makeTrackPoints(count: 1)
        let result = ElevationCalculator.buildElevationSegments(from: points)
        #expect(result.isEmpty)
    }

    @Test("Track shorter than 1km produces no full segments, only partial")
    func shortTrack() {
        // 5 points, each ~111m apart = ~444m total — not enough for a full km
        let points = makeTrackPoints(count: 5)
        let result = ElevationCalculator.buildElevationSegments(from: points)
        // Should have 1 partial segment
        #expect(result.count == 1)
        #expect(result[0].kilometerNumber == 1)
    }

    // MARK: - Flat Track

    @Test("Flat track produces gradients near zero")
    func flatTrack() {
        // 20 points = ~2.1km, flat altitude
        let points = makeTrackPoints(count: 20) { _ in 500.0 }
        let result = ElevationCalculator.buildElevationSegments(from: points)

        #expect(result.count >= 2)
        for segment in result {
            #expect(abs(segment.averageGradient) < 1.0)
        }
    }

    // MARK: - Uphill

    @Test("Uphill track produces positive gradients")
    func uphillTrack() {
        // Each point ~111m apart, altitude increases by 20m per point
        // Gradient = 20m / 111m * 100 ≈ 18%
        let points = makeTrackPoints(count: 20) { i in 500.0 + Double(i) * 20.0 }
        let result = ElevationCalculator.buildElevationSegments(from: points)

        #expect(!result.isEmpty)
        for segment in result {
            #expect(segment.averageGradient > 0)
        }
    }

    // MARK: - Downhill

    @Test("Downhill track produces negative gradients")
    func downhillTrack() {
        let points = makeTrackPoints(count: 20) { i in 1000.0 - Double(i) * 20.0 }
        let result = ElevationCalculator.buildElevationSegments(from: points)

        #expect(!result.isEmpty)
        for segment in result {
            #expect(segment.averageGradient < 0)
        }
    }

    // MARK: - Mixed Terrain

    @Test("Mixed terrain produces correct gradient signs per segment")
    func mixedTerrain() {
        // 30 points = ~3.2km
        // First 10 points: uphill (km 1)
        // Next 10: downhill (km 2)
        // Last 10: flat (km 3 partial)
        let points = makeTrackPoints(count: 30) { i in
            if i < 10 {
                return 500.0 + Double(i) * 15.0
            } else if i < 20 {
                return 500.0 + 135.0 - Double(i - 10) * 15.0
            } else {
                return 500.0
            }
        }

        let result = ElevationCalculator.buildElevationSegments(from: points)
        #expect(result.count >= 2)

        // First segment should be uphill
        #expect(result[0].averageGradient > 0)
        // Second segment should be downhill
        #expect(result[1].averageGradient < 0)
    }

    // MARK: - Kilometer Numbers

    @Test("Segments have sequential kilometer numbers")
    func kilometerNumbers() {
        let points = makeTrackPoints(count: 30)
        let result = ElevationCalculator.buildElevationSegments(from: points)

        for (index, segment) in result.enumerated() {
            #expect(segment.kilometerNumber == index + 1)
        }
    }

    // MARK: - Coordinates

    @Test("Each segment has at least 2 coordinates")
    func segmentCoordinates() {
        let points = makeTrackPoints(count: 20)
        let result = ElevationCalculator.buildElevationSegments(from: points)

        for segment in result {
            #expect(segment.coordinates.count >= 2)
        }
    }
}
