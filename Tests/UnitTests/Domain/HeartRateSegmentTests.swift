import Foundation
import Testing
@testable import UltraTrain

@Suite("Heart Rate Segment Builder Tests")
struct HeartRateSegmentTests {

    private func makePoints(count: Int, hrRange: ClosedRange<Int> = 140...160) -> [TrackPoint] {
        let baseDate = Date.now
        var points: [TrackPoint] = []
        for i in 0..<count {
            let distKm = Double(i) * 0.01
            points.append(TrackPoint(
                latitude: 48.0 + distKm * 0.009,
                longitude: 2.0,
                altitudeM: 100,
                timestamp: baseDate.addingTimeInterval(Double(i) * 3.6),
                heartRate: Int.random(in: hrRange)
            ))
        }
        return points
    }

    @Test("Builds segments from track points with HR data")
    func buildsSegments() {
        let points = makePoints(count: 300)
        let segments = RunStatisticsCalculator.buildHeartRateSegments(from: points, maxHeartRate: 190)

        #expect(!segments.isEmpty)
        #expect(segments[0].kilometerNumber == 1)
        #expect(segments[0].averageHeartRate > 0)
        #expect(segments[0].zone >= 1 && segments[0].zone <= 5)
        #expect(segments[0].coordinates.count >= 2)
    }

    @Test("Zone assignment matches maxHR thresholds")
    func zoneAssignment() {
        let baseDate = Date.now
        // Create points with consistent HR of 170 (170/190 = 89.5% → zone 4)
        var points: [TrackPoint] = []
        for i in 0..<200 {
            let dist = Double(i) * 0.005
            points.append(TrackPoint(
                latitude: 48.0 + dist * 0.009,
                longitude: 2.0,
                altitudeM: 100,
                timestamp: baseDate.addingTimeInterval(Double(i) * 3.6),
                heartRate: 170
            ))
        }

        let segments = RunStatisticsCalculator.buildHeartRateSegments(from: points, maxHeartRate: 190)

        guard let first = segments.first else {
            Issue.record("Expected at least one segment")
            return
        }
        #expect(first.averageHeartRate == 170)
        #expect(first.zone == 4)
    }

    @Test("Returns empty for insufficient points")
    func emptyForFewPoints() {
        let segments = RunStatisticsCalculator.buildHeartRateSegments(
            from: [TrackPoint(latitude: 48, longitude: 2, altitudeM: 100, timestamp: .now, heartRate: 150)],
            maxHeartRate: 190
        )
        #expect(segments.isEmpty)
    }

    @Test("Returns empty for zero maxHeartRate")
    func emptyForZeroMaxHR() {
        let points = makePoints(count: 200)
        let segments = RunStatisticsCalculator.buildHeartRateSegments(from: points, maxHeartRate: 0)
        #expect(segments.isEmpty)
    }
}
