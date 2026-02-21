import Foundation
import Testing
@testable import UltraTrain

@Suite("CourseImportUseCase Tests")
struct CourseImportUseCaseTests {

    // MARK: - Helpers

    private func makeTrackPointsForDistance(
        distanceKm: Double,
        pointCount: Int = 100,
        altitudeStart: Double = 500,
        altitudeGain: Double = 0
    ) -> [TrackPoint] {
        let totalDegrees = distanceKm / 111.0
        let step = totalDegrees / Double(pointCount - 1)
        let altStep = pointCount > 1 ? altitudeGain / Double(pointCount - 1) : 0
        return (0..<pointCount).map { i in
            TrackPoint(
                latitude: Double(i) * step,
                longitude: 0,
                altitudeM: altitudeStart + Double(i) * altStep,
                timestamp: Date.now.addingTimeInterval(Double(i) * 60),
                heartRate: nil
            )
        }
    }

    // MARK: - Checkpoint Interval

    @Test("Checkpoint interval is 10km for races under 50km")
    func intervalUnder50km() {
        #expect(CourseImportUseCase.checkpointInterval(for: 30) == 10)
        #expect(CourseImportUseCase.checkpointInterval(for: 49.9) == 10)
    }

    @Test("Checkpoint interval is 15km for races 50-100km")
    func interval50to100km() {
        #expect(CourseImportUseCase.checkpointInterval(for: 50) == 15)
        #expect(CourseImportUseCase.checkpointInterval(for: 75) == 15)
        #expect(CourseImportUseCase.checkpointInterval(for: 99.9) == 15)
    }

    @Test("Checkpoint interval is 20km for races over 100km")
    func intervalOver100km() {
        #expect(CourseImportUseCase.checkpointInterval(for: 100) == 20)
        #expect(CourseImportUseCase.checkpointInterval(for: 170) == 20)
    }

    // MARK: - Import

    @Test("Import valid course calculates distance and elevation")
    func importValidCourse() throws {
        let points = makeTrackPointsForDistance(
            distanceKm: 50,
            pointCount: 200,
            altitudeStart: 500,
            altitudeGain: 1000
        )
        let parseResult = GPXParseResult(name: "Test Course", date: .now, trackPoints: points)
        let result = try CourseImportUseCase.importCourse(from: parseResult)

        #expect(result.distanceKm > 40)
        #expect(result.elevationGainM > 0)
        #expect(result.name == "Test Course")
        #expect(!result.checkpoints.isEmpty)
    }

    @Test("Import fails with fewer than 2 track points")
    func importFailsInsufficientPoints() {
        let singlePoint = [TrackPoint(
            latitude: 0, longitude: 0, altitudeM: 500,
            timestamp: .now, heartRate: nil
        )]
        let parseResult = GPXParseResult(name: nil, date: nil, trackPoints: singlePoint)

        #expect(throws: DomainError.self) {
            try CourseImportUseCase.importCourse(from: parseResult)
        }
    }

    @Test("Import fails with empty track points")
    func importFailsEmpty() {
        let parseResult = GPXParseResult(name: nil, date: nil, trackPoints: [])

        #expect(throws: DomainError.self) {
            try CourseImportUseCase.importCourse(from: parseResult)
        }
    }

    @Test("Course name is extracted from GPX")
    func courseNameExtracted() throws {
        let points = makeTrackPointsForDistance(distanceKm: 30, pointCount: 100)
        let parseResult = GPXParseResult(name: "UTMB 2025", date: .now, trackPoints: points)
        let result = try CourseImportUseCase.importCourse(from: parseResult)

        #expect(result.name == "UTMB 2025")
    }

    @Test("Nil name passes through as nil")
    func nilName() throws {
        let points = makeTrackPointsForDistance(distanceKm: 30, pointCount: 100)
        let parseResult = GPXParseResult(name: nil, date: nil, trackPoints: points)
        let result = try CourseImportUseCase.importCourse(from: parseResult)

        #expect(result.name == nil)
    }

    // MARK: - Checkpoint Generation

    @Test("No checkpoints for course shorter than interval")
    func noCheckpointsForShortCourse() {
        let points = makeTrackPointsForDistance(distanceKm: 8, pointCount: 50)
        let checkpoints = CourseImportUseCase.generateCheckpoints(
            trackPoints: points,
            totalDistanceKm: 8
        )
        #expect(checkpoints.isEmpty)
    }

    @Test("Checkpoints have correct naming pattern")
    func checkpointNaming() {
        let points = makeTrackPointsForDistance(distanceKm: 35, pointCount: 200)
        let checkpoints = CourseImportUseCase.generateCheckpoints(
            trackPoints: points,
            totalDistanceKm: 35
        )
        #expect(checkpoints.count == 3)
        #expect(checkpoints[0].name == "KM 10")
        #expect(checkpoints[1].name == "KM 20")
        #expect(checkpoints[2].name == "KM 30")
    }

    @Test("All generated checkpoints have hasAidStation false")
    func checkpointsNoAidStation() throws {
        let points = makeTrackPointsForDistance(distanceKm: 50, pointCount: 200)
        let parseResult = GPXParseResult(name: nil, date: nil, trackPoints: points)
        let result = try CourseImportUseCase.importCourse(from: parseResult)

        #expect(result.checkpoints.allSatisfy { !$0.hasAidStation })
    }

    @Test("Checkpoints have correct distance values")
    func checkpointDistances() {
        let points = makeTrackPointsForDistance(distanceKm: 65, pointCount: 300)
        let checkpoints = CourseImportUseCase.generateCheckpoints(
            trackPoints: points,
            totalDistanceKm: 65
        )
        #expect(checkpoints.count == 4)
        #expect(checkpoints[0].distanceFromStartKm == 15)
        #expect(checkpoints[1].distanceFromStartKm == 30)
        #expect(checkpoints[2].distanceFromStartKm == 45)
        #expect(checkpoints[3].distanceFromStartKm == 60)
    }

    @Test("Elevation gain is calculated correctly")
    func elevationGainCalculated() throws {
        let points = makeTrackPointsForDistance(
            distanceKm: 30,
            pointCount: 100,
            altitudeStart: 200,
            altitudeGain: 1500
        )
        let parseResult = GPXParseResult(name: nil, date: nil, trackPoints: points)
        let result = try CourseImportUseCase.importCourse(from: parseResult)

        #expect(result.elevationGainM > 1400)
        #expect(result.elevationGainM < 1600)
    }

    // MARK: - Course Route (Simplified)

    @Test("Import result contains non-empty courseRoute")
    func importResultHasCourseRoute() throws {
        let points = makeTrackPointsForDistance(
            distanceKm: 50,
            pointCount: 200,
            altitudeStart: 500,
            altitudeGain: 1000
        )
        let parseResult = GPXParseResult(
            name: "Test Course",
            date: .now,
            trackPoints: points
        )
        let result = try CourseImportUseCase.importCourse(from: parseResult)

        #expect(!result.courseRoute.isEmpty)
    }

    @Test("Simplified route has fewer points than original")
    func simplifiedRouteFewerPoints() {
        let points = makeTrackPointsForDistance(
            distanceKm: 50,
            pointCount: 500,
            altitudeStart: 500,
            altitudeGain: 2000
        )
        let simplified = CourseImportUseCase.simplifyRoute(points: points)

        #expect(simplified.count < points.count)
        #expect(simplified.count >= 2)
    }

    @Test("Simplified route preserves start and end points")
    func simplifiedRoutePreservesEndpoints() {
        let points = makeTrackPointsForDistance(
            distanceKm: 30,
            pointCount: 200,
            altitudeStart: 500,
            altitudeGain: 1000
        )
        let simplified = CourseImportUseCase.simplifyRoute(points: points)

        #expect(simplified.first == points.first)
        #expect(simplified.last == points.last)
    }
}
