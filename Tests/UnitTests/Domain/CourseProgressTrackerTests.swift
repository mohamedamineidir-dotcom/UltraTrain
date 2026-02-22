import Foundation
import Testing
@testable import UltraTrain

@Suite("CourseProgressTracker Tests")
struct CourseProgressTrackerTests {

    // MARK: - Helpers

    /// Creates a straight-line route along a constant longitude with specified point count.
    /// Each point is ~111m apart (0.001 deg latitude).
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

    private func makeCheckpoints() -> [Checkpoint] {
        [
            Checkpoint(
                id: UUID(),
                name: "Aid Station 1",
                distanceFromStartKm: 0.5,
                elevationM: 500,
                hasAidStation: true
            ),
            Checkpoint(
                id: UUID(),
                name: "Aid Station 2",
                distanceFromStartKm: 1.0,
                elevationM: 500,
                hasAidStation: true
            )
        ]
    }

    // MARK: - trackProgress

    @Test("trackProgress with single-point route returns zero progress")
    func trackProgress_singlePointRoute_returnsZeroProgress() {
        let route = makeStraightRoute(pointCount: 1)
        let result = CourseProgressTracker.trackProgress(
            latitude: 45.0,
            longitude: 6.0,
            courseRoute: route,
            checkpoints: []
        )
        #expect(result.percentComplete == 0)
        #expect(result.distanceAlongCourseKm == 0)
    }

    @Test("trackProgress at start position returns 0% progress")
    func trackProgress_atStart_returnsZeroPercent() {
        let route = makeStraightRoute(pointCount: 20)
        let result = CourseProgressTracker.trackProgress(
            latitude: 45.0,
            longitude: 6.0,
            courseRoute: route,
            checkpoints: []
        )
        #expect(result.percentComplete < 5)
        #expect(result.nearestCoursePointIndex == 0)
    }

    @Test("trackProgress near middle returns approximately 50% progress")
    func trackProgress_nearMiddle_returnsAbout50Percent() {
        let route = makeStraightRoute(pointCount: 20)
        // Mid point: index 10 of 20 points → lat = 45.0 + 10 * 0.001 = 45.010
        let result = CourseProgressTracker.trackProgress(
            latitude: 45.010,
            longitude: 6.0,
            courseRoute: route,
            checkpoints: []
        )
        #expect(result.percentComplete > 40)
        #expect(result.percentComplete < 60)
    }

    @Test("Off-course detection when more than 200m from course")
    func trackProgress_offCourse_detectsWhenFarFromRoute() {
        let route = makeStraightRoute(pointCount: 10)
        // Place the runner ~555m east (0.005 degrees longitude at 45°N ≈ 394m)
        // Use a larger offset to be sure
        let result = CourseProgressTracker.trackProgress(
            latitude: 45.005,
            longitude: 6.01,
            courseRoute: route,
            checkpoints: []
        )
        #expect(result.isOffCourse == true)
        #expect(result.distanceOffCourseM > CourseProgressTracker.offCourseThresholdM)
    }

    @Test("On-course when less than 200m from course")
    func trackProgress_onCourse_detectsWhenNearRoute() {
        let route = makeStraightRoute(pointCount: 10)
        // Runner is right on the course
        let result = CourseProgressTracker.trackProgress(
            latitude: 45.005,
            longitude: 6.0,
            courseRoute: route,
            checkpoints: []
        )
        #expect(result.isOffCourse == false)
        #expect(result.distanceOffCourseM < CourseProgressTracker.offCourseThresholdM)
    }

    @Test("Next checkpoint identification returns upcoming checkpoint")
    func trackProgress_nextCheckpoint_returnsUpcoming() {
        let route = makeStraightRoute(pointCount: 20, spacing: 0.001)
        let checkpoints = makeCheckpoints()

        // Runner at start → next checkpoint should be Aid Station 1
        let result = CourseProgressTracker.trackProgress(
            latitude: 45.0,
            longitude: 6.0,
            courseRoute: route,
            checkpoints: checkpoints
        )
        #expect(result.nextCheckpoint != nil)
        #expect(result.nextCheckpoint?.name == "Aid Station 1")
        #expect(result.distanceToNextCheckpointKm != nil)
    }

    @Test("cumulativeDistance computation is correct")
    func cumulativeDistance_returnsCorrectDistance() {
        let route = makeStraightRoute(pointCount: 10)
        // Distance from index 0 to index 0 should be 0
        let distAtZero = CourseProgressTracker.cumulativeDistance(to: 0, in: route)
        #expect(distAtZero == 0)

        // Distance from index 0 to last should be > 0
        let distAtEnd = CourseProgressTracker.cumulativeDistance(to: 9, in: route)
        #expect(distAtEnd > 0)

        // 9 segments of ~111m = ~0.999 km
        #expect(distAtEnd > 0.9)
        #expect(distAtEnd < 1.1)
    }
}
