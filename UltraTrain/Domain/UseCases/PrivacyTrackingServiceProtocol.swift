import Foundation

enum TrackingAuthorizationStatus: String, Sendable {
    case notDetermined
    case restricted
    case denied
    case authorized

    var displayDescription: String {
        switch self {
        case .notDetermined: "Not Requested"
        case .restricted: "Restricted"
        case .denied: "Denied"
        case .authorized: "Authorized"
        }
    }
}

protocol PrivacyTrackingServiceProtocol: Sendable {
    var authorizationStatus: TrackingAuthorizationStatus { get }
    func requestAuthorization() async -> TrackingAuthorizationStatus
}
