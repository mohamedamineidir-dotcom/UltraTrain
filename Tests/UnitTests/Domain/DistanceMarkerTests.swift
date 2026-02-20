import Foundation
import Testing
@testable import UltraTrain

@Suite("Distance Marker Builder Tests")
struct DistanceMarkerTests {

    private func makeTrack(distanceKm: Double) -> [TrackPoint] {
        let baseDate = Date.now
        let pointsPerKm = 100
        let totalPoints = Int(distanceKm * Double(pointsPerKm))
        var points: [TrackPoint] = []
        for i in 0..<totalPoints {
            let km = Double(i) / Double(pointsPerKm)
            points.append(TrackPoint(
                latitude: 48.0 + km * 0.009,
                longitude: 2.0,
                altitudeM: 100,
                timestamp: baseDate.addingTimeInterval(km * 360)
            ))
        }
        return points
    }

    @Test("Markers placed at km boundaries")
    func markersAtBoundaries() {
        let points = makeTrack(distanceKm: 5.5)
        let markers = RunStatisticsCalculator.buildDistanceMarkers(from: points)

        #expect(markers.count == 5)
        #expect(markers[0].km == 1)
        #expect(markers[1].km == 2)
        #expect(markers[4].km == 5)
    }

    @Test("Returns empty for single point")
    func emptyForSinglePoint() {
        let markers = RunStatisticsCalculator.buildDistanceMarkers(from: [
            TrackPoint(latitude: 48, longitude: 2, altitudeM: 100, timestamp: .now)
        ])
        #expect(markers.isEmpty)
    }

    @Test("Marker coordinates are valid")
    func validCoordinates() {
        let points = makeTrack(distanceKm: 3)
        let markers = RunStatisticsCalculator.buildDistanceMarkers(from: points)

        for marker in markers {
            #expect(marker.coordinate.0 >= 48.0)
            #expect(marker.coordinate.0 <= 49.0)
            #expect(marker.coordinate.1 == 2.0)
        }
    }
}
