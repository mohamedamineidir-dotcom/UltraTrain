import Foundation
import os

@Observable
@MainActor
final class RouteLibraryViewModel {

    // MARK: - Dependencies

    private let routeRepository: any RouteRepository
    private let runRepository: any RunRepository

    // MARK: - State

    var routes: [SavedRoute] = []
    var recentRunsWithGPS: [CompletedRun] = []
    var isLoading = false
    var error: String?
    var searchText: String = ""

    var filteredRoutes: [SavedRoute] {
        guard !searchText.isEmpty else { return routes }
        let query = searchText.lowercased()
        return routes.filter { $0.name.lowercased().contains(query) }
    }

    // MARK: - Init

    init(
        routeRepository: any RouteRepository,
        runRepository: any RunRepository
    ) {
        self.routeRepository = routeRepository
        self.runRepository = runRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            routes = try await routeRepository.getRoutes()
        } catch {
            self.error = error.localizedDescription
            Logger.persistence.error("Failed to load routes: \(error)")
        }

        do {
            let recent = try await runRepository.getRecentRuns(limit: 50)
            recentRunsWithGPS = recent.filter { $0.gpsTrack.count >= 2 }
        } catch {
            Logger.persistence.debug("Could not load runs for route conversion: \(error)")
        }

        isLoading = false
    }

    // MARK: - Import GPX

    func importGPX(data: Data) async {
        do {
            let parseResult = try GPXParser().parse(data)
            let courseResult = try CourseImportUseCase.importCourse(from: parseResult)

            let route = SavedRoute(
                id: UUID(),
                name: courseResult.name ?? "Imported Route",
                distanceKm: courseResult.distanceKm,
                elevationGainM: courseResult.elevationGainM,
                elevationLossM: courseResult.elevationLossM,
                trackPoints: courseResult.trackPoints,
                courseRoute: courseResult.courseRoute,
                checkpoints: courseResult.checkpoints,
                source: .gpxImport,
                createdAt: .now
            )

            try await routeRepository.saveRoute(route)
            routes.insert(route, at: 0)
            Logger.persistence.info("Imported GPX route: \(route.name)")
        } catch {
            self.error = error.localizedDescription
            Logger.persistence.error("GPX import failed: \(error)")
        }
    }

    // MARK: - Create from Run

    func createFromRun(_ run: CompletedRun) async {
        do {
            let route = try ConvertRunToRouteUseCase.execute(from: run)
            try await routeRepository.saveRoute(route)
            routes.insert(route, at: 0)
        } catch {
            self.error = error.localizedDescription
            Logger.persistence.error("Failed to create route from run: \(error)")
        }
    }

    // MARK: - Delete

    func deleteRoute(id: UUID) async {
        do {
            try await routeRepository.deleteRoute(id: id)
            routes.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
            Logger.persistence.error("Failed to delete route: \(error)")
        }
    }
}
