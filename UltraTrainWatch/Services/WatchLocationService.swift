import CoreLocation
import os

enum WatchLocationAuthStatus: Sendable {
    case notDetermined
    case denied
    case authorized
}

@Observable
@MainActor
final class WatchLocationService: NSObject, @unchecked Sendable {

    // MARK: - State

    var authStatus: WatchLocationAuthStatus = .notDetermined

    // MARK: - Private

    private let locationManager = CLLocationManager()
    private var locationContinuation: AsyncStream<CLLocation>.Continuation?

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = WatchConfiguration.GPS.distanceFilterM
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
        updateAuthStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Tracking

    func startTracking() -> AsyncStream<CLLocation> {
        AsyncStream { continuation in
            self.locationContinuation = continuation
            self.locationManager.startUpdatingLocation()
            Logger.watch.info("Watch GPS tracking started")

            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.locationManager.stopUpdatingLocation()
                    Logger.watch.info("Watch GPS tracking stopped via stream termination")
                }
            }
        }
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationContinuation?.finish()
        locationContinuation = nil
        Logger.watch.info("Watch GPS tracking stopped")
    }

    func pauseTracking() {
        locationManager.stopUpdatingLocation()
        Logger.watch.info("Watch GPS tracking paused")
    }

    func resumeTracking() {
        locationManager.startUpdatingLocation()
        Logger.watch.info("Watch GPS tracking resumed")
    }

    // MARK: - Private

    private func updateAuthStatus() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            authStatus = .notDetermined
        case .denied, .restricted:
            authStatus = .denied
        case .authorizedWhenInUse, .authorizedAlways:
            authStatus = .authorized
        @unknown default:
            authStatus = .denied
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WatchLocationService: CLLocationManagerDelegate {

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let filtered = locations.filter {
            $0.horizontalAccuracy <= WatchConfiguration.GPS.maxAccuracyM
        }
        Task { @MainActor in
            for location in filtered {
                self.locationContinuation?.yield(location)
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: any Error
    ) {
        Logger.watch.error("Watch location error: \(error)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.updateAuthStatus()
        }
    }
}
