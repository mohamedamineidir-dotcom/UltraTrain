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
    // Bumped on every startTracking() call so a stale continuation's
    // onTermination (fired asynchronously, after a NEW stream may already
    // be active) can tell it's no longer current and must not tear down
    // the new session. See startTracking() for why this matters.
    private var trackingGeneration = 0
    #if DEBUG
    private let isUITestMode = ProcessInfo.processInfo.arguments.contains("-UITestMode")
    #endif

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            authorizationStatus = .authorizedWhenInUse
            return
        }
        #endif
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
        trackingGeneration += 1
        let generation = trackingGeneration
        // Defensive: if a previous stream's consumer is still around (this
        // should not happen once callers own a single, stable tracking
        // session — but if it ever does), tear it down synchronously
        // instead of silently orphaning it. An orphaned continuation's
        // `for await` loop never receives another location and never
        // terminates either, which looks exactly like "GPS suddenly
        // stopped updating" to whoever is still awaiting it.
        if locationContinuation != nil {
            locationManager.stopUpdatingLocation()
            locationContinuation?.finish()
            locationContinuation = nil
        }
        return AsyncStream { [weak self] continuation in
            guard let self else { return }
            self.locationContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    // Only the still-current generation may stop the
                    // location manager / clear state — a stale stream's
                    // termination firing after a newer one has already
                    // started must not tear down the new session.
                    guard let self, self.trackingGeneration == generation else { return }
                    self.stopTracking()
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
        // Left at its default (true), iOS can decide the runner has
        // "stopped" — a brief GPS dropout, standing still at the start —
        // and autonomously suspend further location callbacks with no
        // error surfaced anywhere. That silent suspension is exactly what
        // "GPS worked for a few seconds then froze" looks like from the
        // app's side.
        locationManager.pausesLocationUpdatesAutomatically = false
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
            #if DEBUG
            if self.isUITestMode { return }
            #endif
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
