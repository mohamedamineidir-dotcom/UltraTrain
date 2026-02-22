import Foundation

enum ConvertRunToRouteUseCase {

    static func execute(from run: CompletedRun, name: String? = nil) throws -> SavedRoute {
        guard run.gpsTrack.count >= 2 else {
            throw DomainError.insufficientData(
                reason: "This activity has no GPS data to create a route from."
            )
        }

        let distanceKm = RunStatisticsCalculator.totalDistanceKm(run.gpsTrack)
        let elevation = ElevationCalculator.elevationChanges(run.gpsTrack)
        let checkpoints = CourseImportUseCase.generateCheckpoints(
            trackPoints: run.gpsTrack,
            totalDistanceKm: distanceKm
        )
        let courseRoute = CourseImportUseCase.simplifyRoute(points: run.gpsTrack)

        let routeName = name ?? "Route from \(run.date.formatted(.dateTime.month().day().year()))"

        return SavedRoute(
            id: UUID(),
            name: routeName,
            distanceKm: distanceKm,
            elevationGainM: elevation.gainM,
            elevationLossM: elevation.lossM,
            trackPoints: run.gpsTrack,
            courseRoute: courseRoute,
            checkpoints: checkpoints,
            source: .completedRun,
            createdAt: .now,
            sourceRunId: run.id
        )
    }
}
