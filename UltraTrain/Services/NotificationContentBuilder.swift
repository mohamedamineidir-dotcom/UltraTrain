import Foundation

enum NotificationContentBuilder {

    static func trainingReminderBody(_ session: TrainingSession) -> String {
        var parts: [String] = []
        let typeName: String = switch session.type {
        case .longRun: "Long Run"
        case .tempo: "Tempo"
        case .intervals: "Intervals"
        case .verticalGain: "Vertical Gain"
        case .backToBack: "Back-to-Back"
        case .recovery: "Recovery Run"
        case .crossTraining: "Cross Training"
        case .rest: "Rest Day"
        }
        parts.append(typeName)
        if session.plannedDistanceKm > 0 {
            parts.append(String(format: "%.1f km", session.plannedDistanceKm))
        }
        if session.plannedElevationGainM > 0 {
            parts.append(String(format: "%.0f m D+", session.plannedElevationGainM))
        }
        return "Tomorrow: " + parts.joined(separator: " \u{2014} ")
    }

    static func raceCountdownBody(raceName: String, daysRemaining: Int) -> String {
        if daysRemaining == 1 {
            return "Your race \(raceName) is tomorrow! Good luck!"
        } else if daysRemaining <= 7 {
            return "Your race \(raceName) is in \(daysRemaining) days!"
        } else {
            let weeks = daysRemaining / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s") until \(raceName). Stay focused!"
        }
    }

    static func recoveryReminderBody() -> String {
        "Rest day \u{2014} remember to stretch, hydrate, and recover well."
    }

    static func weeklySummaryBody(distanceKm: Double, elevationM: Double, runCount: Int) -> String {
        let distStr = String(format: "%.1f", distanceKm)
        let elevStr = String(format: "%.0f", elevationM)
        return "This week: \(distStr) km, \(elevStr) m D+ across \(runCount) run\(runCount == 1 ? "" : "s"). Keep it up!"
    }
}
