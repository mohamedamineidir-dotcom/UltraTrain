import Foundation
import Testing
@testable import UltraTrain

@Suite("ElevationCalculator Tests")
struct ElevationCalculatorTests {

    // MARK: - Helpers

    private func makeProfile(_ altitudes: [(distanceKm: Double, altitudeM: Double)]) -> [ElevationProfilePoint] {
        altitudes.map { ElevationProfilePoint(distanceKm: $0.distanceKm, altitudeM: $0.altitudeM) }
    }

    private func makeTrackPoints(count: Int, spacing: Double = 0.001) -> [TrackPoint] {
        let baseDate = Date.now
        return (0..<count).map { i in
            TrackPoint(
                latitude: 45.0 + Double(i) * spacing,
                longitude: 6.0,
                altitudeM: 500.0 + Double(i) * 10,
                timestamp: baseDate.addingTimeInterval(Double(i) * 10),
                heartRate: nil
            )
        }
    }

    // MARK: - Elevation Extremes

    @Test("Elevation extremes returns highest and lowest")
    func extremesHappyPath() {
        let profile = makeProfile([
            (0, 500), (1, 800), (2, 300), (3, 600)
        ])
        let result = ElevationCalculator.elevationExtremes(from: profile)
        #expect(result != nil)
        #expect(result!.highest.altitudeM == 800)
        #expect(result!.lowest.altitudeM == 300)
    }

    @Test("Elevation extremes returns nil for empty profile")
    func extremesEmpty() {
        let result = ElevationCalculator.elevationExtremes(from: [])
        #expect(result == nil)
    }

    @Test("Elevation extremes single point returns same for both")
    func extremesSinglePoint() {
        let profile = makeProfile([(0, 500)])
        let result = ElevationCalculator.elevationExtremes(from: profile)
        #expect(result != nil)
        #expect(result!.highest.altitudeM == 500)
        #expect(result!.lowest.altitudeM == 500)
    }

    // MARK: - Nearest Track Point

    @Test("Nearest track point at zero returns first point")
    func nearestAtZero() {
        let points = makeTrackPoints(count: 10)
        let result = ElevationCalculator.nearestTrackPoint(at: 0, in: points)
        #expect(result != nil)
        #expect(result!.latitude == points[0].latitude)
    }

    @Test("Nearest track point beyond end returns last point")
    func nearestBeyondEnd() {
        let points = makeTrackPoints(count: 5)
        let result = ElevationCalculator.nearestTrackPoint(at: 100, in: points)
        #expect(result != nil)
        #expect(result!.latitude == points[4].latitude)
    }

    // MARK: - Elevation Changes (delegated)

    @Test("Elevation changes ascending")
    func elevationChangesAscending() {
        let points = [
            TrackPoint(latitude: 0, longitude: 0, altitudeM: 100, timestamp: .now, heartRate: nil),
            TrackPoint(latitude: 0, longitude: 0, altitudeM: 200, timestamp: .now, heartRate: nil),
        ]
        let (gain, loss) = ElevationCalculator.elevationChanges(points)
        #expect(gain == 100)
        #expect(loss == 0)
    }
}
