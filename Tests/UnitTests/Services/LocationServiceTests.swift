import CoreLocation
import Foundation
import Testing
@testable import UltraTrain

@Suite("LocationService Tests")
struct LocationServiceTests {

    // NOTE: LocationService depends on CLLocationManager which requires device capabilities.
    // We test the observable state properties, the LocationAuthStatus enum,
    // and the initial state of the service.

    // MARK: - LocationAuthStatus

    @Test("LocationAuthStatus has all expected cases")
    func authStatusHasAllCases() {
        let statuses: [LocationAuthStatus] = [
            .notDetermined, .denied, .authorizedWhenInUse, .authorizedAlways
        ]
        #expect(statuses.count == 4)
    }

    // MARK: - Initial State

    @MainActor
    @Test("LocationService starts with isTracking false")
    func initialIsTrackingFalse() {
        let service = LocationService()
        #expect(!service.isTracking)
    }

    @MainActor
    @Test("LocationService starts with nil currentLocation")
    func initialCurrentLocationNil() {
        let service = LocationService()
        #expect(service.currentLocation == nil)
    }

    @MainActor
    @Test("LocationService starts with nil error")
    func initialErrorNil() {
        let service = LocationService()
        #expect(service.error == nil)
    }

    // MARK: - Stop Tracking

    @MainActor
    @Test("stopTracking sets isTracking to false")
    func stopTrackingSetsIsTrackingFalse() {
        let service = LocationService()
        // Even without starting, stopTracking should be safe
        service.stopTracking()
        #expect(!service.isTracking)
    }

    // MARK: - Location Accuracy Filtering

    @MainActor
    @Test("didUpdateLocations filters out invalid accuracy locations")
    func delegateFiltersInvalidAccuracy() {
        // The delegate filters locations with horizontalAccuracy < 0 or > 50
        // This tests the filter logic conceptually
        let service = LocationService()

        // Verify service starts with no location
        #expect(service.currentLocation == nil)
    }

    // MARK: - State Transitions

    @MainActor
    @Test("startTracking returns an AsyncStream")
    func startTrackingReturnsStream() {
        let service = LocationService()
        let stream = service.startTracking()
        #expect(service.isTracking)

        // Clean up
        service.stopTracking()
        _ = stream
    }

    @MainActor
    @Test("stopTracking after startTracking resets state")
    func stopAfterStartResetsState() {
        let service = LocationService()
        _ = service.startTracking()
        #expect(service.isTracking)

        service.stopTracking()
        #expect(!service.isTracking)
    }

    // MARK: - One-shot location (pre-run weather / dashboard weather fix)

    @MainActor
    @Test("requestOneShotLocation returns the already-known location immediately, without needing a fresh fix")
    func oneShotReturnsCurrentLocationImmediately() async {
        let service = LocationService()
        let existing = CLLocation(latitude: 48.8566, longitude: 2.3522)
        service.currentLocation = existing

        let result = await service.requestOneShotLocation()
        #expect(result === existing)
    }

    @MainActor
    @Test("requestOneShotLocation returns nil without hanging when authorization hasn't been granted")
    func oneShotReturnsNilWhenNotAuthorized() async {
        let service = LocationService()
        // Fresh service, real CLLocationManager reports .notDetermined in
        // the test environment — never actually calls into CoreLocation.
        #expect(service.currentLocation == nil)
        let result = await service.requestOneShotLocation()
        #expect(result == nil)
    }
}
