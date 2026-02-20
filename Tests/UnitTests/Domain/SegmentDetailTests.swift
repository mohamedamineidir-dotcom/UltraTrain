import Foundation
import Testing
@testable import UltraTrain

@Suite("Segment Detail Builder Tests")
struct SegmentDetailTests {

    private func makeTrack(distanceKm: Double, withHR: Bool = true) -> [TrackPoint] {
        let baseDate = Date.now
        let pointsPerKm = 100
        let totalPoints = Int(distanceKm * Double(pointsPerKm))
        var points: [TrackPoint] = []
        for i in 0..<totalPoints {
            let km = Double(i) / Double(pointsPerKm)
            points.append(TrackPoint(
                latitude: 48.0 + km * 0.009,
                longitude: 2.0,
                altitudeM: 100 + km * 50,
                timestamp: baseDate.addingTimeInterval(km * 360),
                heartRate: withHR ? 155 : nil
            ))
        }
        return points
    }

    @Test("Builds segment details with pace and elevation")
    func buildsDetails() {
        let points = makeTrack(distanceKm: 3.5)
        let details = RunStatisticsCalculator.buildSegmentDetails(
            from: points,
            splits: [],
            maxHeartRate: 190
        )

        #expect(details.count == 3)
        #expect(details[0].kilometerNumber == 1)
        #expect(details[0].paceSecondsPerKm > 0)
        #expect(details[0].elevationChangeM > 0)
    }

    @Test("Includes HR and zone when available")
    func includesHR() {
        let points = makeTrack(distanceKm: 2.5, withHR: true)
        let details = RunStatisticsCalculator.buildSegmentDetails(
            from: points,
            splits: [],
            maxHeartRate: 190
        )

        guard let first = details.first else {
            Issue.record("Expected at least one detail")
            return
        }
        #expect(first.averageHeartRate == 155)
        #expect(first.zone != nil)
    }

    @Test("HR is nil when no heart rate data")
    func noHRData() {
        let points = makeTrack(distanceKm: 2.5, withHR: false)
        let details = RunStatisticsCalculator.buildSegmentDetails(
            from: points,
            splits: [],
            maxHeartRate: 190
        )

        guard let first = details.first else {
            Issue.record("Expected at least one detail")
            return
        }
        #expect(first.averageHeartRate == nil)
        #expect(first.zone == nil)
    }

    @Test("Midpoint coordinate is within segment range")
    func midpointCoordinate() {
        let points = makeTrack(distanceKm: 2.5)
        let details = RunStatisticsCalculator.buildSegmentDetails(
            from: points,
            splits: [],
            maxHeartRate: nil
        )

        guard let first = details.first else {
            Issue.record("Expected at least one detail")
            return
        }
        #expect(first.coordinate.0 >= 48.0)
        #expect(first.coordinate.0 <= 49.0)
    }
}
