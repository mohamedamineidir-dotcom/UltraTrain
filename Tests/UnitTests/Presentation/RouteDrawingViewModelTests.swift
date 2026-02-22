import Foundation
import Testing
import CoreLocation
@testable import UltraTrain

@Suite("RouteDrawingViewModel Tests")
struct RouteDrawingViewModelTests {

    @MainActor
    private func makeViewModel() -> RouteDrawingViewModel {
        RouteDrawingViewModel()
    }

    // MARK: - Initial State

    @Test("Initial state has empty waypoints")
    @MainActor
    func initialStateEmptyWaypoints() {
        let vm = makeViewModel()
        #expect(vm.waypoints.isEmpty)
        #expect(vm.snappedSegments.isEmpty)
        #expect(vm.checkpoints.isEmpty)
        #expect(vm.routeName.isEmpty)
        #expect(vm.isResolving == false)
    }

    @Test("Drawing mode defaults to waypoints")
    @MainActor
    func defaultDrawingMode() {
        let vm = makeViewModel()
        #expect(vm.drawingMode == .waypoints)
    }

    // MARK: - Add Waypoint

    @Test("Adding a waypoint increases count")
    @MainActor
    func addWaypointIncreasesCount() {
        let vm = makeViewModel()
        let coord = CLLocationCoordinate2D(latitude: 45.832, longitude: 6.865)

        vm.addWaypoint(coord)

        #expect(vm.waypoints.count == 1)
        #expect(vm.waypoints[0].latitude == 45.832)
        #expect(vm.waypoints[0].longitude == 6.865)
    }

    @Test("Adding multiple waypoints accumulates")
    @MainActor
    func addMultipleWaypoints() {
        let vm = makeViewModel()
        vm.addWaypoint(CLLocationCoordinate2D(latitude: 45.0, longitude: 6.0))
        vm.addWaypoint(CLLocationCoordinate2D(latitude: 46.0, longitude: 7.0))
        vm.addWaypoint(CLLocationCoordinate2D(latitude: 47.0, longitude: 8.0))

        #expect(vm.waypoints.count == 3)
    }

    // MARK: - Undo

    @Test("Undo removes last waypoint")
    @MainActor
    func undoRemovesLastWaypoint() {
        let vm = makeViewModel()
        vm.addWaypoint(CLLocationCoordinate2D(latitude: 45.0, longitude: 6.0))
        vm.addWaypoint(CLLocationCoordinate2D(latitude: 46.0, longitude: 7.0))

        vm.undoLastWaypoint()

        #expect(vm.waypoints.count == 1)
        #expect(vm.waypoints[0].latitude == 45.0)
    }

    @Test("Cannot undo when no waypoints exist")
    @MainActor
    func undoWithNoWaypoints() {
        let vm = makeViewModel()
        #expect(vm.waypoints.isEmpty)

        vm.undoLastWaypoint()

        #expect(vm.waypoints.isEmpty)
    }

    // MARK: - Clear

    @Test("Clear resets everything")
    @MainActor
    func clearResetsAll() {
        let vm = makeViewModel()
        vm.addWaypoint(CLLocationCoordinate2D(latitude: 45.0, longitude: 6.0))
        vm.routeName = "Mountain Trail"
        vm.checkpoints = [
            Checkpoint(
                id: UUID(),
                name: "CP1",
                distanceFromStartKm: 5,
                elevationM: 1200,
                hasAidStation: true
            )
        ]

        vm.clearAll()

        #expect(vm.waypoints.isEmpty)
        #expect(vm.snappedSegments.isEmpty)
        #expect(vm.checkpoints.isEmpty)
        #expect(vm.routeName.isEmpty)
    }

    // MARK: - Drawing Mode

    @Test("Drawing mode can be switched to checkpoints")
    @MainActor
    func switchDrawingMode() {
        let vm = makeViewModel()
        vm.drawingMode = .checkpoints
        #expect(vm.drawingMode == .checkpoints)
    }

    @Test("Drawing mode cases include waypoints and checkpoints")
    func drawingModeCases() {
        let allCases = RouteDrawingViewModel.DrawingMode.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.waypoints))
        #expect(allCases.contains(.checkpoints))
    }

    // MARK: - Computed Properties

    @Test("canSave is false with fewer than 2 waypoints")
    @MainActor
    func canSaveFalseWithOneWaypoint() {
        let vm = makeViewModel()
        vm.addWaypoint(CLLocationCoordinate2D(latitude: 45.0, longitude: 6.0))
        #expect(vm.canSave == false)
    }

    @Test("allRouteCoordinates is empty initially")
    @MainActor
    func allRouteCoordinatesEmptyInitially() {
        let vm = makeViewModel()
        #expect(vm.allRouteCoordinates.isEmpty)
    }

    @Test("totalDistanceKm is zero with no segments")
    @MainActor
    func totalDistanceZeroInitially() {
        let vm = makeViewModel()
        #expect(vm.totalDistanceKm == 0)
    }
}
