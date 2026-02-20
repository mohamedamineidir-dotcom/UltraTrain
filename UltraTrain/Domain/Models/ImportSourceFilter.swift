import Foundation

enum ImportSourceFilter: String, CaseIterable, Sendable {
    case manual
    case strava
    case healthKit

    var displayName: String {
        switch self {
        case .manual: "Manual"
        case .strava: "Strava"
        case .healthKit: "HealthKit"
        }
    }
}
