import Foundation

enum VoiceCueBuilder {

    struct RunSnapshot: Sendable {
        let distanceKm: Double
        let elapsedTime: TimeInterval
        let currentPace: TimeInterval?
        let elevationGainM: Double
        let currentHeartRate: Int?
        let currentZoneName: String?
        let previousZoneName: String?
        let isMetric: Bool
    }

    // MARK: - Splits

    static func distanceSplitCue(snapshot: RunSnapshot) -> VoiceCue {
        let unit: UnitPreference = snapshot.isMetric ? .metric : .imperial
        let distanceValue = UnitFormatter.distanceValue(snapshot.distanceKm, unit: unit)
        let distLabel = snapshot.isMetric ? "kilometers" : "miles"
        let rounded = Int(distanceValue)

        var message = "\(rounded) \(distLabel)."
        if let pace = snapshot.currentPace, pace > 0, pace.isFinite {
            let paceStr = spokenPace(pace, isMetric: snapshot.isMetric)
            message += " Pace: \(paceStr)."
        }
        return VoiceCue(type: .distanceSplit, message: message, priority: .medium)
    }

    static func timeSplitCue(snapshot: RunSnapshot) -> VoiceCue {
        let timeStr = spokenDuration(snapshot.elapsedTime)
        let unit: UnitPreference = snapshot.isMetric ? .metric : .imperial
        let distValue = UnitFormatter.distanceValue(snapshot.distanceKm, unit: unit)
        let distLabel = snapshot.isMetric ? "kilometers" : "miles"

        let message = "\(timeStr) elapsed. Distance: \(String(format: "%.1f", distValue)) \(distLabel)."
        return VoiceCue(type: .timeSplit, message: message, priority: .low)
    }

    // MARK: - HR Zone

    static func heartRateZoneChangeCue(snapshot: RunSnapshot) -> VoiceCue {
        let zoneName = snapshot.currentZoneName ?? "unknown"
        let message = "Entering zone \(zoneName)."
        return VoiceCue(type: .heartRateZoneChange, message: message, priority: .medium)
    }

    // MARK: - Events

    static func nutritionReminderCue() -> VoiceCue {
        VoiceCue(type: .nutritionReminder, message: "Time for nutrition.", priority: .high)
    }

    static func checkpointCue(name: String, timeDelta: TimeInterval?) -> VoiceCue {
        var message = "Checkpoint \(name) reached."
        if let delta = timeDelta {
            let absDelta = abs(delta)
            let timeStr = spokenDuration(absDelta)
            if delta < 0 {
                message += " \(timeStr) ahead of plan."
            } else if delta > 0 {
                message += " \(timeStr) behind plan."
            } else {
                message += " Right on schedule."
            }
        }
        return VoiceCue(type: .checkpointCrossing, message: message, priority: .high)
    }

    static func pacingAlertCue(message: String) -> VoiceCue {
        VoiceCue(type: .pacingAlert, message: message, priority: .high)
    }

    static func zoneDriftCue(currentZone: Int, targetZone: Int, duration: TimeInterval) -> VoiceCue {
        let durationStr = spokenDuration(duration)
        let direction = currentZone > targetZone ? "Slow down" : "Pick up the pace"
        let message = "\(direction). Zone \(currentZone) for \(durationStr), target is zone \(targetZone)."
        return VoiceCue(type: .zoneDriftAlert, message: message, priority: .high)
    }

    static func runStateCue(type: VoiceCueType) -> VoiceCue {
        let message: String
        switch type {
        case .runStarted: message = "Run started. Good luck!"
        case .runPaused: message = "Run paused."
        case .runResumed: message = "Run resumed."
        case .autoPaused: message = "Auto paused."
        default: message = ""
        }
        return VoiceCue(type: type, message: message, priority: .medium)
    }

    // MARK: - Formatting Helpers

    private static func spokenPace(_ secondsPerKm: TimeInterval, isMetric: Bool) -> String {
        let unit: UnitPreference = isMetric ? .metric : .imperial
        let converted = UnitFormatter.paceValue(secondsPerKm, unit: unit)
        guard converted > 0, converted.isFinite else { return "unknown" }
        let minutes = Int(converted) / 60
        let seconds = Int(converted) % 60
        let unitLabel = isMetric ? "per kilometer" : "per mile"
        if seconds == 0 {
            return "\(minutes) minutes \(unitLabel)"
        }
        return "\(minutes) minutes \(seconds) seconds \(unitLabel)"
    }

    static func spokenDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        var parts: [String] = []
        if hours > 0 {
            parts.append("\(hours) \(hours == 1 ? "hour" : "hours")")
        }
        if minutes > 0 {
            parts.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")")
        }
        if secs > 0 && hours == 0 {
            parts.append("\(secs) \(secs == 1 ? "second" : "seconds")")
        }
        return parts.isEmpty ? "0 seconds" : parts.joined(separator: " ")
    }
}
