import Foundation

enum NotificationContentBuilder {

    static func trainingReminderBody(_ session: TrainingSession) -> String {
        var parts: [String] = []
        let typeName: String = switch session.type {
        case .longRun: String(localized: "notif.type.longRun", defaultValue: "Long Run")
        case .tempo: String(localized: "notif.type.tempo", defaultValue: "Tempo")
        case .intervals: String(localized: "notif.type.intervals", defaultValue: "Intervals")
        case .verticalGain: String(localized: "notif.type.verticalGain", defaultValue: "Uphill Intervals")
        case .backToBack: String(localized: "notif.type.backToBack", defaultValue: "Back-to-Back")
        case .recovery: String(localized: "notif.type.recovery", defaultValue: "Recovery Run")
        case .crossTraining: String(localized: "notif.type.crossTraining", defaultValue: "Cross Training")
        case .strengthConditioning: String(localized: "notif.type.strength", defaultValue: "Strength & Conditioning")
        case .race: String(localized: "notif.type.race", defaultValue: "Race Day")
        case .rest: String(localized: "notif.type.rest", defaultValue: "Rest Day")
        }
        parts.append(typeName)
        if session.plannedDistanceKm > 0 {
            parts.append(String(format: "%.1f km", session.plannedDistanceKm))
        }
        if session.plannedElevationGainM > 0 {
            parts.append(String(format: "%.0f m D+", session.plannedElevationGainM))
        }
        return String(localized: "notif.tomorrowPrefix", defaultValue: "Tomorrow: ") + parts.joined(separator: ", ")
    }

    static func raceCountdownBody(raceName: String, daysRemaining: Int) -> String {
        if daysRemaining == 1 {
            return String(localized: "notif.race.tomorrow", defaultValue: "Your race \(raceName) is tomorrow! Good luck!")
        } else if daysRemaining <= 7 {
            return String(localized: "notif.race.days", defaultValue: "Your race \(raceName) is in \(daysRemaining) days!")
        } else {
            let weeks = daysRemaining / 7
            let weekWord = weeks == 1
                ? String(localized: "notif.week", defaultValue: "week")
                : String(localized: "notif.weeks", defaultValue: "weeks")
            return String(localized: "notif.race.weeks", defaultValue: "\(weeks) \(weekWord) until \(raceName). Stay focused!")
        }
    }

    static func recoveryReminderBody() -> String {
        String(localized: "notif.recovery", defaultValue: "Rest day, remember to stretch, hydrate, and recover well.")
    }

    static func weeklySummaryBody(distanceKm: Double, elevationM: Double, runCount: Int) -> String {
        let distStr = String(format: "%.1f", distanceKm)
        let elevStr = String(format: "%.0f", elevationM)
        let runWord = runCount == 1
            ? String(localized: "notif.run", defaultValue: "run")
            : String(localized: "notif.runs", defaultValue: "runs")
        return String(localized: "notif.weekly", defaultValue: "This week: \(distStr) km, \(elevStr) m D+ across \(runCount) \(runWord). Keep it up!")
    }
}
