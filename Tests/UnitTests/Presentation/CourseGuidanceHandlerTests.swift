import Foundation
import Testing
@testable import UltraTrain

@Suite("CourseGuidanceHandler Tests")
struct CourseGuidanceHandlerTests {

    // MARK: - Helpers

    private func makeStraightRoute(pointCount: Int, spacing: Double = 0.001) -> [TrackPoint] {
        let baseDate = Date(timeIntervalSince1970: 1_000_000)
        return (0..<pointCount).map { i in
            TrackPoint(
                latitude: 45.0 + Double(i) * spacing,
                longitude: 6.0,
                altitudeM: 500,
                timestamp: baseDate.addingTimeInterval(Double(i) * 30),
                heartRate: nil
            )
        }
    }

    private func makeCheckpoint(
        name: String,
        distanceKm: Double,
        id: UUID = UUID()
    ) -> Checkpoint {
        Checkpoint(
            id: id,
            name: name,
            distanceFromStartKm: distanceKm,
            elevationM: 500,
            hasAidStation: true
        )
    }

    @MainActor
    private func makeHandler(
        route: [TrackPoint]? = nil,
        checkpoints: [Checkpoint] = [],
        checkpointSplits: [CheckpointSplit]? = nil
    ) -> CourseGuidanceHandler {
        let courseRoute = route ?? makeStraightRoute(pointCount: 20)
        let totalKm = CourseProgressTracker.cumulativeDistance(
            to: courseRoute.count - 1,
            in: courseRoute
        )
        return CourseGuidanceHandler(
            courseRoute: courseRoute,
            checkpoints: checkpoints,
            checkpointSplits: checkpointSplits,
            totalDistanceKm: totalKm
        )
    }

    // MARK: - Tick

    @Test("tick updates currentProgress")
    @MainActor
    func tick_updatesCurrentProgress() {
        let handler = makeHandler()
        #expect(handler.currentProgress == nil)

        handler.tick(
            latitude: 45.005,
            longitude: 6.0,
            elapsedTime: 600,
            currentPaceSecondsPerKm: 360
        )

        #expect(handler.currentProgress != nil)
        #expect(handler.currentProgress!.percentComplete > 0)
    }

    @Test("Checkpoint arrival triggers arrivedCheckpoint")
    @MainActor
    func tick_checkpointArrival_triggersArrivedCheckpoint() {
        let cp = makeCheckpoint(name: "Aid 1", distanceKm: 0.0)
        let handler = makeHandler(checkpoints: [cp])

        // Tick at the very start where checkpoint is at distance 0
        handler.tick(
            latitude: 45.0,
            longitude: 6.0,
            elapsedTime: 0,
            currentPaceSecondsPerKm: 360
        )

        #expect(handler.arrivedCheckpoint != nil)
        #expect(handler.arrivedCheckpoint?.name == "Aid 1")
    }

    @Test("Off-course detection sets isOffCourse")
    @MainActor
    func tick_offCourse_setsIsOffCourse() {
        let handler = makeHandler()

        // Tick with a position far from the course
        handler.tick(
            latitude: 46.0,
            longitude: 7.0,
            elapsedTime: 600,
            currentPaceSecondsPerKm: 360
        )

        #expect(handler.isOffCourse == true)
    }

    @Test("ETA calculation with pace data returns value for next checkpoint")
    @MainActor
    func tick_withPaceData_computesNextCheckpointETA() {
        let cp = makeCheckpoint(name: "CP 1", distanceKm: 1.5)
        let handler = makeHandler(checkpoints: [cp])

        handler.tick(
            latitude: 45.0,
            longitude: 6.0,
            elapsedTime: 0,
            currentPaceSecondsPerKm: 360
        )

        #expect(handler.nextCheckpointName == "CP 1")
        #expect(handler.nextCheckpointDistanceKm != nil)
        #expect(handler.nextCheckpointETA != nil)
    }
}
