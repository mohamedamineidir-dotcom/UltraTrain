import Foundation
import Testing
@testable import UltraTrain

@Suite("Run Statistics Calculator Tests")
struct RunStatisticsCalculatorTests {

    // MARK: - Haversine Distance

    @Test("Haversine distance between known coordinates")
    func haversineKnownCoordinates() {
        // Paris (48.8566, 2.3522) to London (51.5074, -0.1278) ≈ 343.5 km
        let distanceM = RunStatisticsCalculator.haversineDistance(
            lat1: 48.8566, lon1: 2.3522,
            lat2: 51.5074, lon2: -0.1278
        )
        let distanceKm = distanceM / 1000
        #expect(distanceKm > 340 && distanceKm < 350)
    }

    @Test("Haversine distance same point returns zero")
    func haversineSamePoint() {
        let distance = RunStatisticsCalculator.haversineDistance(
            lat1: 48.8566, lon1: 2.3522,
            lat2: 48.8566, lon2: 2.3522
        )
        #expect(distance == 0)
    }

    // MARK: - Total Distance

    @Test("Total distance empty array returns zero")
    func totalDistanceEmpty() {
        #expect(RunStatisticsCalculator.totalDistanceKm([]) == 0)
    }

    @Test("Total distance single point returns zero")
    func totalDistanceSinglePoint() {
        let point = makeTrackPoint(lat: 48.0, lon: 2.0)
        #expect(RunStatisticsCalculator.totalDistanceKm([point]) == 0)
    }

    @Test("Total distance two points returns haversine distance")
    func totalDistanceTwoPoints() {
        let p1 = makeTrackPoint(lat: 48.8566, lon: 2.3522)
        let p2 = makeTrackPoint(lat: 48.8576, lon: 2.3532)
        let distance = RunStatisticsCalculator.totalDistanceKm([p1, p2])
        #expect(distance > 0)
    }

    @Test("Total distance multiple points is cumulative")
    func totalDistanceMultiplePoints() {
        let points = [
            makeTrackPoint(lat: 48.8566, lon: 2.3522),
            makeTrackPoint(lat: 48.8576, lon: 2.3532),
            makeTrackPoint(lat: 48.8586, lon: 2.3542),
        ]
        let total = RunStatisticsCalculator.totalDistanceKm(points)
        let directDistance = RunStatisticsCalculator.totalDistanceKm([points[0], points[2]])
        // Cumulative via waypoint should be >= direct distance
        #expect(total >= directDistance * 0.99)
    }

    // MARK: - Elevation

    @Test("Elevation ascending only returns gain")
    func elevationAscending() {
        let points = [
            makeTrackPoint(lat: 0, lon: 0, altitude: 100),
            makeTrackPoint(lat: 0, lon: 0, altitude: 150),
            makeTrackPoint(lat: 0, lon: 0, altitude: 200),
        ]
        let (gain, loss) = RunStatisticsCalculator.elevationChanges(points)
        #expect(gain == 100)
        #expect(loss == 0)
    }

    @Test("Elevation descending only returns loss")
    func elevationDescending() {
        let points = [
            makeTrackPoint(lat: 0, lon: 0, altitude: 300),
            makeTrackPoint(lat: 0, lon: 0, altitude: 200),
            makeTrackPoint(lat: 0, lon: 0, altitude: 100),
        ]
        let (gain, loss) = RunStatisticsCalculator.elevationChanges(points)
        #expect(gain == 0)
        #expect(loss == 200)
    }

    @Test("Elevation mixed returns both gain and loss")
    func elevationMixed() {
        let points = [
            makeTrackPoint(lat: 0, lon: 0, altitude: 100),
            makeTrackPoint(lat: 0, lon: 0, altitude: 200), // +100
            makeTrackPoint(lat: 0, lon: 0, altitude: 150), // -50
            makeTrackPoint(lat: 0, lon: 0, altitude: 250), // +100
        ]
        let (gain, loss) = RunStatisticsCalculator.elevationChanges(points)
        #expect(gain == 200)
        #expect(loss == 50)
    }

    // MARK: - Pace

    @Test("Average pace known values")
    func averagePaceKnown() {
        let pace = RunStatisticsCalculator.averagePace(distanceKm: 10, duration: 3600)
        #expect(pace == 360) // 6:00 /km
    }

    @Test("Average pace zero distance returns zero")
    func averagePaceZeroDistance() {
        let pace = RunStatisticsCalculator.averagePace(distanceKm: 0, duration: 3600)
        #expect(pace == 0)
    }

    @Test("Format pace correctly")
    func formatPace() {
        #expect(RunStatisticsCalculator.formatPace(360) == "6:00")
        #expect(RunStatisticsCalculator.formatPace(332) == "5:32")
        #expect(RunStatisticsCalculator.formatPace(0) == "--:--")
    }

    @Test("Format duration correctly")
    func formatDuration() {
        #expect(RunStatisticsCalculator.formatDuration(3661) == "1:01:01")
        #expect(RunStatisticsCalculator.formatDuration(600) == "10:00")
        #expect(RunStatisticsCalculator.formatDuration(59) == "00:59")
    }

    // MARK: - Heart Rate Zone

    @Test("Heart rate zones")
    func heartRateZones() {
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 100, maxHeartRate: 200) == 1)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 130, maxHeartRate: 200) == 2)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 150, maxHeartRate: 200) == 3)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 170, maxHeartRate: 200) == 4)
        #expect(RunStatisticsCalculator.heartRateZone(heartRate: 190, maxHeartRate: 200) == 5)
    }

    // MARK: - Helpers

    private func makeTrackPoint(
        lat: Double, lon: Double, altitude: Double = 0, seconds: TimeInterval = 0
    ) -> TrackPoint {
        TrackPoint(
            latitude: lat,
            longitude: lon,
            altitudeM: altitude,
            timestamp: Date(timeIntervalSinceReferenceDate: seconds),
            heartRate: nil
        )
    }
}
