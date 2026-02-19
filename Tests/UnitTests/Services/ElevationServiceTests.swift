import Foundation
import Testing
@testable import UltraTrain

@Suite("ElevationService Tests")
struct ElevationServiceTests {

    private func makeProfile(_ altitudes: [Double]) -> [ElevationProfilePoint] {
        altitudes.enumerated().map { i, alt in
            ElevationProfilePoint(distanceKm: Double(i) * 0.1, altitudeM: alt)
        }
    }

    // MARK: - Smoothing

    @Test("Smoothing preserves point count")
    func smoothingPreservesCount() {
        let profile = makeProfile([100, 200, 150, 300, 250, 180, 220])
        let smoothed = ElevationService.smoothElevationProfile(profile)
        #expect(smoothed.count == profile.count)
    }

    @Test("Smoothing flattens noisy data")
    func smoothingFlattensNoise() {
        let profile = makeProfile([100, 300, 100, 300, 100, 300, 100])
        let smoothed = ElevationService.smoothElevationProfile(profile, windowSize: 3)

        // Middle values should be closer to 200 than the original 100/300
        let midOriginal = profile[3].altitudeM
        let midSmoothed = smoothed[3].altitudeM
        let diff = abs(midSmoothed - 200)
        #expect(diff < abs(midOriginal - 200))
    }

    @Test("Smoothing with small data returns unchanged")
    func smoothingSmallData() {
        let profile = makeProfile([100, 200])
        let smoothed = ElevationService.smoothElevationProfile(profile, windowSize: 5)
        #expect(smoothed.count == 2)
        #expect(smoothed[0].altitudeM == 100)
        #expect(smoothed[1].altitudeM == 200)
    }

    // MARK: - Categorize Segments

    @Test("Categorize segments maps correctly")
    func categorizeSegments() {
        let segments = [
            ElevationSegment(coordinates: [(0, 0)], averageGradient: 20, kilometerNumber: 1),
            ElevationSegment(coordinates: [(0, 0)], averageGradient: 0, kilometerNumber: 2),
            ElevationSegment(coordinates: [(0, 0)], averageGradient: -20, kilometerNumber: 3),
        ]
        let result = ElevationService.categorizeSegments(segments)
        #expect(result.count == 3)
        #expect(result[0].category == .steepUp)
        #expect(result[1].category == .flat)
        #expect(result[2].category == .steepDown)
    }
}
