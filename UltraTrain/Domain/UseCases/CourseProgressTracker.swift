import Foundation

struct CourseProgress: Equatable, Sendable {
    var distanceAlongCourseKm: Double
    var percentComplete: Double
    var nearestCoursePointIndex: Int
    var distanceOffCourseM: Double
    var isOffCourse: Bool
    var nextCheckpoint: Checkpoint?
    var distanceToNextCheckpointKm: Double?
}

enum CourseProgressTracker {

    static let offCourseThresholdM: Double = 200.0

    // MARK: - Track Progress

    static func trackProgress(
        latitude: Double,
        longitude: Double,
        courseRoute: [TrackPoint],
        checkpoints: [Checkpoint],
        previousDistanceKm: Double = 0
    ) -> CourseProgress {
        guard courseRoute.count >= 2 else {
            return CourseProgress(
                distanceAlongCourseKm: 0,
                percentComplete: 0,
                nearestCoursePointIndex: 0,
                distanceOffCourseM: 0,
                isOffCourse: false,
                nextCheckpoint: nil,
                distanceToNextCheckpointKm: nil
            )
        }

        let nearestResult = findNearestPoint(
            latitude: latitude,
            longitude: longitude,
            courseRoute: courseRoute,
            previousDistanceKm: previousDistanceKm
        )

        let distAlongKm = cumulativeDistance(
            to: nearestResult.index, in: courseRoute
        )

        let totalKm = cumulativeDistance(
            to: courseRoute.count - 1, in: courseRoute
        )
        let percent = totalKm > 0 ? (distAlongKm / totalKm) * 100.0 : 0

        let isOff = nearestResult.distanceM > offCourseThresholdM

        let nextCP = checkpoints
            .sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }
            .first { $0.distanceFromStartKm > distAlongKm }

        let distToNextKm = nextCP.map { $0.distanceFromStartKm - distAlongKm }

        return CourseProgress(
            distanceAlongCourseKm: distAlongKm,
            percentComplete: min(percent, 100),
            nearestCoursePointIndex: nearestResult.index,
            distanceOffCourseM: nearestResult.distanceM,
            isOffCourse: isOff,
            nextCheckpoint: nextCP,
            distanceToNextCheckpointKm: distToNextKm
        )
    }

    // MARK: - Cumulative Distance

    static func cumulativeDistance(to index: Int, in points: [TrackPoint]) -> Double {
        guard index > 0, points.count >= 2 else { return 0 }
        let bound = min(index, points.count - 1)
        var total: Double = 0
        for i in 1...bound {
            total += RunStatisticsCalculator.haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
        }
        return total / 1000.0
    }

    // MARK: - Private

    private struct NearestResult {
        let index: Int
        let distanceM: Double
    }

    private static func findNearestPoint(
        latitude: Double,
        longitude: Double,
        courseRoute: [TrackPoint],
        previousDistanceKm: Double
    ) -> NearestResult {
        let previousIndex = indexForDistance(
            previousDistanceKm, in: courseRoute
        )

        let windowBehind = 50
        let windowAhead = courseRoute.count
        let startIdx = max(0, previousIndex - windowBehind)
        let endIdx = min(courseRoute.count - 1, previousIndex + windowAhead)

        var bestIndex = startIdx
        var bestDist = Double.greatestFiniteMagnitude

        for i in startIdx...endIdx {
            let d = RunStatisticsCalculator.haversineDistance(
                lat1: latitude, lon1: longitude,
                lat2: courseRoute[i].latitude, lon2: courseRoute[i].longitude
            )
            if d < bestDist {
                bestDist = d
                bestIndex = i
            }
        }

        return NearestResult(index: bestIndex, distanceM: bestDist)
    }

    private static func indexForDistance(
        _ distanceKm: Double, in points: [TrackPoint]
    ) -> Int {
        guard points.count >= 2, distanceKm > 0 else { return 0 }
        var cumulative: Double = 0
        for i in 1..<points.count {
            cumulative += RunStatisticsCalculator.haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            ) / 1000.0
            if cumulative >= distanceKm {
                return i
            }
        }
        return points.count - 1
    }
}
