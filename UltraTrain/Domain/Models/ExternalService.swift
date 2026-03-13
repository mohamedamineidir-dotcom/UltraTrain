import Foundation

enum ExternalService: String, CaseIterable, Codable, Sendable {
    case strava
    case appleHealth
    case garminConnect
    case coros
    case suunto

    var displayName: String {
        switch self {
        case .strava:        "Strava"
        case .appleHealth:   "Apple Health"
        case .garminConnect: "Garmin Connect"
        case .coros:         "Coros"
        case .suunto:        "Suunto"
        }
    }

    var icon: String {
        switch self {
        case .strava:        "figure.run.circle.fill"
        case .appleHealth:   "heart.circle.fill"
        case .garminConnect: "applewatch.radiowaves.left.and.right"
        case .coros:         "watchface.applewatch.case"
        case .suunto:        "compass.drawing"
        }
    }
}
