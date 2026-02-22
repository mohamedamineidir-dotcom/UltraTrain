import Foundation
import CoreLocation
import os

@Observable
@MainActor
final class OSMTrailSearchViewModel {

    // MARK: - Dependencies

    private let osmService: OSMTrailService

    // MARK: - State

    var searchText: String = ""
    var results: [OSMTrailResult] = []
    var isLoading = false
    var error: String?
    var searchLocation: CLLocationCoordinate2D?

    // MARK: - Init

    init(osmService: OSMTrailService = OSMTrailService()) {
        self.osmService = osmService
    }

    // MARK: - Search by Name

    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isLoading = true
        error = nil

        do {
            results = try await osmService.searchTrails(
                byName: query,
                near: searchLocation
            )
            Logger.routePlanning.info("OSM name search returned \(self.results.count) results")
        } catch {
            self.error = error.localizedDescription
            Logger.routePlanning.error("OSM name search failed: \(error)")
        }

        isLoading = false
    }

    // MARK: - Search Nearby

    func searchNearby(coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        error = nil
        searchLocation = coordinate

        do {
            results = try await osmService.searchTrails(near: coordinate)
            Logger.routePlanning.info("OSM nearby search returned \(self.results.count) results")
        } catch {
            self.error = error.localizedDescription
            Logger.routePlanning.error("OSM nearby search failed: \(error)")
        }

        isLoading = false
    }

    // MARK: - Import

    func importTrail(
        _ trail: OSMTrailResult,
        routeRepository: any RouteRepository
    ) async throws {
        let route = try DrawRouteUseCase.buildRoute(
            name: trail.name,
            trackPoints: trail.trackPoints
        )
        try await routeRepository.saveRoute(route)
        Logger.routePlanning.info("Imported OSM trail: \(trail.name)")
    }
}
