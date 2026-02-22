import Foundation
import CoreLocation
import MapKit
import os

@Observable
@MainActor
final class RouteDrawingViewModel {

    enum DrawingMode: String, CaseIterable {
        case waypoints
        case checkpoints
    }

    // MARK: - State

    var waypoints: [CLLocationCoordinate2D] = []
    var snappedSegments: [[CLLocationCoordinate2D]] = []
    var checkpoints: [Checkpoint] = []
    var routeName: String = ""
    var isResolving = false
    var drawingMode: DrawingMode = .waypoints

    // MARK: - Computed

    var allRouteCoordinates: [CLLocationCoordinate2D] {
        snappedSegments.flatMap { $0 }
    }

    var totalDistanceKm: Double {
        let coords = allRouteCoordinates
        guard coords.count >= 2 else { return 0 }
        var total: Double = 0
        for i in 1..<coords.count {
            let loc1 = CLLocation(latitude: coords[i - 1].latitude, longitude: coords[i - 1].longitude)
            let loc2 = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
            total += loc1.distance(from: loc2)
        }
        return total / 1000.0
    }

    var canSave: Bool {
        waypoints.count >= 2 && !allRouteCoordinates.isEmpty
    }

    // MARK: - Waypoint Actions

    func addWaypoint(_ coordinate: CLLocationCoordinate2D) {
        let previousWaypoint = waypoints.last
        waypoints.append(coordinate)

        guard let previous = previousWaypoint else { return }

        isResolving = true
        Task {
            let segment = await resolveSegment(from: previous, to: coordinate)
            snappedSegments.append(segment)
            isResolving = false
        }
    }

    func undoLastWaypoint() {
        guard !waypoints.isEmpty else { return }
        waypoints.removeLast()
        if !snappedSegments.isEmpty {
            snappedSegments.removeLast()
        }
    }

    func clearAll() {
        waypoints.removeAll()
        snappedSegments.removeAll()
        checkpoints.removeAll()
        routeName = ""
    }

    // MARK: - Checkpoint Actions

    func placeCheckpoint(at coordinate: CLLocationCoordinate2D) {
        let routeCoords = allRouteCoordinates
        guard !routeCoords.isEmpty else { return }

        let tappedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var closestCoord = routeCoords[0]
        var closestDistance = Double.greatestFiniteMagnitude

        for coord in routeCoords {
            let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let dist = tappedLocation.distance(from: loc)
            if dist < closestDistance {
                closestDistance = dist
                closestCoord = coord
            }
        }

        let distanceFromStart = distanceAlongRoute(to: closestCoord)

        let checkpoint = Checkpoint(
            id: UUID(),
            name: "CP \(checkpoints.count + 1)",
            distanceFromStartKm: distanceFromStart,
            elevationM: 0,
            hasAidStation: false,
            latitude: closestCoord.latitude,
            longitude: closestCoord.longitude
        )
        checkpoints.append(checkpoint)
    }

    func removeCheckpoint(_ checkpoint: Checkpoint) {
        checkpoints.removeAll { $0.id == checkpoint.id }
    }

    // MARK: - Save

    func saveRoute(routeRepository: any RouteRepository) async throws {
        let coords = allRouteCoordinates
        let trackPoints = coords.map { coord in
            TrackPoint(
                latitude: coord.latitude,
                longitude: coord.longitude,
                altitudeM: 0,
                timestamp: Date.distantPast,
                heartRate: nil
            )
        }

        var route = try DrawRouteUseCase.buildRoute(
            name: routeName,
            trackPoints: trackPoints,
            checkpoints: checkpoints.isEmpty ? [] : checkpoints
        )

        if !checkpoints.isEmpty {
            route.checkpoints = checkpoints
        }

        try await routeRepository.saveRoute(route)
        Logger.routePlanning.info("Saved drawn route: \(route.name)")
    }

    // MARK: - Private

    private func resolveSegment(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) async -> [CLLocationCoordinate2D] {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .walking

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            if let route = response.routes.first {
                let pointCount = route.polyline.pointCount
                let mapPoints = route.polyline.points()
                var coords: [CLLocationCoordinate2D] = []
                for i in 0..<pointCount {
                    coords.append(mapPoints[i].coordinate)
                }
                return coords
            }
        } catch {
            Logger.routePlanning.debug("MKDirections failed, using straight line: \(error)")
        }

        return [start, end]
    }

    private func distanceAlongRoute(to target: CLLocationCoordinate2D) -> Double {
        let coords = allRouteCoordinates
        var cumulativeM: Double = 0
        for i in 1..<coords.count {
            let prev = CLLocation(latitude: coords[i - 1].latitude, longitude: coords[i - 1].longitude)
            let current = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
            cumulativeM += prev.distance(from: current)

            if abs(coords[i].latitude - target.latitude) < 1e-8
                && abs(coords[i].longitude - target.longitude) < 1e-8 {
                return cumulativeM / 1000.0
            }
        }
        return cumulativeM / 1000.0
    }
}
