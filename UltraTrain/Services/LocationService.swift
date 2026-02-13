import Foundation
import CoreLocation
import os

enum LocationAuthStatus: Sendable {
    case notDetermined
    case denied
    case authorizedWhenInUse
    case authorizedAlways
}

@Observable
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {

    // MARK: - State

    var authorizationStatus: LocationAuthStatus = .notDetermined
    var currentLocation: CLLocation?
    var isTracking = false
    var error: String?

    // MARK: - Private

    private let locationManager = CLLocationManager()
    private var locationContinuation: AsyncStream<CLLocation>.Continuation?

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        updateAuthStatus()
    }

    // MARK: - Authorization

    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Tracking

    func startTracking() -> AsyncStream<CLLocation> {
        AsyncStream { [weak self] continuation in
            guard let self else { return }
            self.locationContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.stopTracking()
                }
            }
            self.configureForActiveTracking()
            self.locationManager.startUpdatingLocation()
            self.isTracking = true
            Logger.tracking.info("GPS tracking started")
        }
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationContinuation?.finish()
        locationContinuation = nil
        isTracking = false
        Logger.tracking.info("GPS tracking stopped")
    }

    func pauseTracking() {
        locationManager.stopUpdatingLocation()
        Logger.tracking.info("GPS tracking paused")
    }

    func resumeTracking() {
        configureForActiveTracking()
        locationManager.startUpdatingLocation()
        Logger.tracking.info("GPS tracking resumed")
    }

    // MARK: - Configuration

    private func configureForActiveTracking() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = AppConfiguration.GPS.activeRunDistanceFilter
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
    }

    // MARK: - Auth Status

    private func updateAuthStatus() {
        authorizationStatus = switch locationManager.authorizationStatus {
        case .notDetermined: .notDetermined
        case .restricted, .denied: .denied
        case .authorizedWhenInUse: .authorizedWhenInUse
        case .authorizedAlways: .authorizedAlways
        @unknown default: .denied
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let validLocations = locations.filter {
            $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy <= 50
        }
        Task { @MainActor in
            for location in validLocations {
                self.currentLocation = location
                self.locationContinuation?.yield(location)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.updateAuthStatus()
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            self.error = error.localizedDescription
            Logger.tracking.error("Location error: \(error)")
        }
    }
}
