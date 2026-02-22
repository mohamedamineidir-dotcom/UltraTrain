import Foundation

struct WatchSessionData: Codable, Sendable, Equatable {
    let sessionId: UUID
    var date: Date
    var type: String
    var plannedDistanceKm: Double
    var plannedElevationGainM: Double
    var plannedDuration: TimeInterval
    var intensity: String
    var description: String
    var maxHeartRate: Int?
    var restingHeartRate: Int?

    var sessionTypeLabel: String {
        switch type {
        case "longRun": return "Long Run"
        case "tempo": return "Tempo"
        case "intervals": return "Intervals"
        case "verticalGain": return "Vertical Gain"
        case "backToBack": return "Back to Back"
        case "recovery": return "Recovery"
        case "crossTraining": return "Cross Training"
        default: return type.capitalized
        }
    }

    var intensityLabel: String {
        switch intensity {
        case "easy": return "Easy"
        case "moderate": return "Moderate"
        case "hard": return "Hard"
        case "maxEffort": return "Max Effort"
        default: return intensity.capitalized
        }
    }
}
