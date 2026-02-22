import Foundation

enum DrawRouteUseCase {

    static func buildRoute(
        name: String,
        trackPoints: [TrackPoint],
        checkpoints: [Checkpoint] = []
    ) throws -> SavedRoute {
        guard trackPoints.count >= 2 else {
            throw DomainError.insufficientData(
                reason: "Route needs at least 2 points."
            )
        }

        let distanceKm = RunStatisticsCalculator.totalDistanceKm(trackPoints)
        let elevation = ElevationCalculator.elevationChanges(trackPoints)

        let generatedCheckpoints = checkpoints.isEmpty
            ? CourseImportUseCase.generateCheckpoints(
                trackPoints: trackPoints,
                totalDistanceKm: distanceKm
            )
            : checkpoints

        let courseRoute = CourseImportUseCase.simplifyRoute(points: trackPoints)

        return SavedRoute(
            id: UUID(),
            name: name.isEmpty ? "My Route" : name,
            distanceKm: distanceKm,
            elevationGainM: elevation.gainM,
            elevationLossM: elevation.lossM,
            trackPoints: trackPoints,
            courseRoute: courseRoute,
            checkpoints: generatedCheckpoints,
            source: .manual,
            createdAt: .now
        )
    }
}
