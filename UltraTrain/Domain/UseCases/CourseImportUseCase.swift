import Foundation

struct CourseImportResult: Equatable, Sendable {
    var distanceKm: Double
    var elevationGainM: Double
    var elevationLossM: Double
    var checkpoints: [Checkpoint]
    var trackPoints: [TrackPoint]
    var name: String?

    static func == (lhs: CourseImportResult, rhs: CourseImportResult) -> Bool {
        lhs.distanceKm == rhs.distanceKm
            && lhs.elevationGainM == rhs.elevationGainM
            && lhs.elevationLossM == rhs.elevationLossM
            && lhs.checkpoints == rhs.checkpoints
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

        return CourseImportResult(
            distanceKm: distanceKm,
            elevationGainM: elevation.gainM,
            elevationLossM: elevation.lossM,
            checkpoints: checkpoints,
            trackPoints: points,
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
}
