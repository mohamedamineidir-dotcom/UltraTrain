import AppTrackingTransparency
import os

final class PrivacyTrackingService: PrivacyTrackingServiceProtocol, @unchecked Sendable {

    var authorizationStatus: TrackingAuthorizationStatus {
        mapStatus(ATTrackingManager.trackingAuthorizationStatus)
    }

    func requestAuthorization() async -> TrackingAuthorizationStatus {
        Logger.privacy.info("Requesting ATT authorization")
        let status = await ATTrackingManager.requestTrackingAuthorization()
        let mapped = mapStatus(status)
        Logger.privacy.info("ATT authorization result: \(mapped.rawValue)")
        return mapped
    }

    private func mapStatus(_ status: ATTrackingManager.AuthorizationStatus) -> TrackingAuthorizationStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorized: .authorized
        @unknown default: .denied
        }
    }
}
