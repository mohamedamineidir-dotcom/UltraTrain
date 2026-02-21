import Foundation

struct CourseImportResult: Equatable, Sendable {
    var distanceKm: Double
    var elevationGainM: Double
    var elevationLossM: Double
    var checkpoints: [Checkpoint]
    var trackPoints: [TrackPoint]
    var courseRoute: [TrackPoint]
    var name: String?

    static func == (lhs: CourseImportResult, rhs: CourseImportResult) -> Bool {
        lhs.distanceKm == rhs.distanceKm
            && lhs.elevationGainM == rhs.elevationGainM
            && lhs.elevationLossM == rhs.elevationLossM
            && lhs.checkpoints == rhs.checkpoints
            && lhs.courseRoute.count == rhs.courseRoute.count
            && lhs.name == rhs.name
    }
}

enum CourseImportUseCase {

    static func importCourse(from parseResult: GPXParseResult) throws -> CourseImportResult {
        let points = parseResult.trackPoints
        guard points.count >= 2 else {
            throw DomainError.importFailed(reason: "GPX file contains fewer than 2 track points.")
        }

        let distanceKm = RunStatisticsCalculator.totalDistanceKm(points)
        let elevation = ElevationCalculator.elevationChanges(points)
        let checkpoints = generateCheckpoints(
            trackPoints: points,
            totalDistanceKm: distanceKm
        )

        let courseRoute = simplifyRoute(points: points)

        return CourseImportResult(
            distanceKm: distanceKm,
            elevationGainM: elevation.gainM,
            elevationLossM: elevation.lossM,
            checkpoints: checkpoints,
            trackPoints: points,
            courseRoute: courseRoute,
            name: parseResult.name
        )
    }

    // MARK: - Checkpoint Generation

    static func generateCheckpoints(
        trackPoints: [TrackPoint],
        totalDistanceKm: Double
    ) -> [Checkpoint] {
        let intervalKm = checkpointInterval(for: totalDistanceKm)
        guard intervalKm > 0, totalDistanceKm > intervalKm else { return [] }

        var checkpoints: [Checkpoint] = []
        var nextCheckpointKm = intervalKm

        while nextCheckpointKm < totalDistanceKm {
            let nearestPoint = ElevationCalculator.nearestTrackPoint(
                at: nextCheckpointKm,
                in: trackPoints
            )
            checkpoints.append(Checkpoint(
                id: UUID(),
                name: "KM \(Int(nextCheckpointKm))",
                distanceFromStartKm: nextCheckpointKm,
                elevationM: nearestPoint?.altitudeM ?? 0,
                hasAidStation: false
            ))
            nextCheckpointKm += intervalKm
        }

        return checkpoints
    }

    static func checkpointInterval(for distanceKm: Double) -> Double {
        switch distanceKm {
        case ..<50: return 10
        case 50..<100: return 15
        default: return 20
        }
    }

    // MARK: - Route Simplification

    static func simplifyRoute(
        points: [TrackPoint],
        toleranceMeters: Double = 20.0
    ) -> [TrackPoint] {
        guard points.count > 2 else { return points }
        return ramerDouglasPeucker(points: points, epsilon: toleranceMeters)
    }

    private static func ramerDouglasPeucker(
        points: [TrackPoint],
        epsilon: Double
    ) -> [TrackPoint] {
        guard points.count > 2 else { return points }

        var maxDistance: Double = 0
        var maxIndex = 0
        let first = points[0]
        let last = points[points.count - 1]

        for i in 1..<(points.count - 1) {
            let dist = perpendicularDistance(
                point: points[i],
                lineStart: first,
                lineEnd: last
            )
            if dist > maxDistance {
                maxDistance = dist
                maxIndex = i
            }
        }

        if maxDistance > epsilon {
            let left = ramerDouglasPeucker(
                points: Array(points[0...maxIndex]),
                epsilon: epsilon
            )
            let right = ramerDouglasPeucker(
                points: Array(points[maxIndex...]),
                epsilon: epsilon
            )
            return Array(left.dropLast()) + right
        } else {
            return [first, last]
        }
    }

    private static func perpendicularDistance(
        point: TrackPoint,
        lineStart: TrackPoint,
        lineEnd: TrackPoint
    ) -> Double {
        let dx = lineEnd.longitude - lineStart.longitude
        let dy = lineEnd.latitude - lineStart.latitude

        if dx == 0 && dy == 0 {
            return RunStatisticsCalculator.haversineDistance(
                lat1: point.latitude, lon1: point.longitude,
                lat2: lineStart.latitude, lon2: lineStart.longitude
            )
        }

        let t = max(0, min(1,
            ((point.longitude - lineStart.longitude) * dx
                + (point.latitude - lineStart.latitude) * dy)
                / (dx * dx + dy * dy)
        ))

        let projLon = lineStart.longitude + t * dx
        let projLat = lineStart.latitude + t * dy

        return RunStatisticsCalculator.haversineDistance(
            lat1: point.latitude, lon1: point.longitude,
            lat2: projLat, lon2: projLon
        )
    }
}
