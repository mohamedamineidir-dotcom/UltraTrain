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
        let distLabel = snapshot.isMetric
            ? String(localized: "vcue.dist.kilometers", defaultValue: "kilometers")
            : String(localized: "vcue.dist.miles", defaultValue: "miles")
        let rounded = Int(distanceValue)

        var message = "\(rounded) \(distLabel)."
        if let pace = snapshot.currentPace, pace > 0, pace.isFinite {
            let paceStr = spokenPace(pace, isMetric: snapshot.isMetric)
            message += String(localized: "vcue.paceSuffix", defaultValue: " Pace: \(paceStr).")
        }
        return VoiceCue(type: .distanceSplit, message: message, priority: .medium)
    }

    static func timeSplitCue(snapshot: RunSnapshot) -> VoiceCue {
        let timeStr = spokenDuration(snapshot.elapsedTime)
        let unit: UnitPreference = snapshot.isMetric ? .metric : .imperial
        let distValue = UnitFormatter.distanceValue(snapshot.distanceKm, unit: unit)
        let distLabel = snapshot.isMetric
            ? String(localized: "vcue.dist.kilometers", defaultValue: "kilometers")
            : String(localized: "vcue.dist.miles", defaultValue: "miles")

        let message = String(localized: "vcue.timeSplit", defaultValue: "\(timeStr) elapsed. Distance: \(String(format: "%.1f", distValue)) \(distLabel).")
        return VoiceCue(type: .timeSplit, message: message, priority: .low)
    }

    // MARK: - HR Zone

    static func heartRateZoneChangeCue(snapshot: RunSnapshot) -> VoiceCue {
        let zoneName = snapshot.currentZoneName ?? String(localized: "vcue.unknownZone", defaultValue: "unknown")
        let message = String(localized: "vcue.enteringZone", defaultValue: "Entering zone \(zoneName).")
        return VoiceCue(type: .heartRateZoneChange, message: message, priority: .medium)
    }

    // MARK: - Events

    static func nutritionReminderCue() -> VoiceCue {
        VoiceCue(type: .nutritionReminder, message: String(localized: "vcue.nutrition", defaultValue: "Time for nutrition."), priority: .high)
    }

    static func checkpointCue(name: String, timeDelta: TimeInterval?) -> VoiceCue {
        var message = String(localized: "vcue.checkpoint.reached", defaultValue: "Checkpoint \(name) reached.")
        if let delta = timeDelta {
            let absDelta = abs(delta)
            let timeStr = spokenDuration(absDelta)
            if delta < 0 {
                message += String(localized: "vcue.ahead", defaultValue: " \(timeStr) ahead of plan.")
            } else if delta > 0 {
                message += String(localized: "vcue.behind", defaultValue: " \(timeStr) behind plan.")
            } else {
                message += String(localized: "vcue.onSchedule", defaultValue: " Right on schedule.")
            }
        }
        return VoiceCue(type: .checkpointCrossing, message: message, priority: .high)
    }

    static func pacingAlertCue(message: String) -> VoiceCue {
        VoiceCue(type: .pacingAlert, message: message, priority: .high)
    }

    static func checkpointArrivalCue(name: String, timeDelta: TimeInterval?) -> VoiceCue {
        var message = String(localized: "vcue.arrived", defaultValue: "Arrived at \(name).")
        if let delta = timeDelta {
            let absDelta = abs(delta)
            let timeStr = spokenDuration(absDelta)
            if delta < 0 {
                message += String(localized: "vcue.ahead", defaultValue: " \(timeStr) ahead of plan.")
            } else if delta > 0 {
                message += String(localized: "vcue.behind", defaultValue: " \(timeStr) behind plan.")
            } else {
                message += String(localized: "vcue.onSchedule", defaultValue: " Right on schedule.")
            }
        }
        return VoiceCue(type: .checkpointArrival, message: message, priority: .high)
    }

    static func offCourseWarningCue(distanceM: Double) -> VoiceCue {
        let meters = Int(distanceM)
        let message = String(localized: "vcue.offCourse", defaultValue: "Warning. You are \(meters) meters off course.")
        return VoiceCue(type: .offCourseWarning, message: message, priority: .high)
    }

    static func zoneDriftCue(currentZone: Int, targetZone: Int, duration: TimeInterval) -> VoiceCue {
        let durationStr = spokenDuration(duration)
        let direction = currentZone > targetZone
            ? String(localized: "vcue.slowDown", defaultValue: "Slow down")
            : String(localized: "vcue.pickUp", defaultValue: "Pick up the pace")
        let message = String(localized: "vcue.zoneDrift", defaultValue: "\(direction). Zone \(currentZone) for \(durationStr), target is zone \(targetZone).")
        return VoiceCue(type: .zoneDriftAlert, message: message, priority: .high)
    }

    // MARK: - Intervals

    static func intervalPhaseStartCue(
        phaseType: IntervalPhaseType,
        intervalNumber: Int?,
        totalIntervals: Int?
    ) -> VoiceCue {
        var message: String
        switch phaseType {
        case .warmUp:
            message = String(localized: "vcue.warmup", defaultValue: "Warm up. Easy pace.")
        case .work:
            if let num = intervalNumber, let total = totalIntervals {
                message = String(localized: "vcue.work.numbered", defaultValue: "Go! Interval \(num) of \(total).")
            } else {
                message = String(localized: "vcue.work.generic", defaultValue: "Go! Work interval.")
            }
        case .recovery:
            message = String(localized: "vcue.recover", defaultValue: "Recover. Easy pace.")
        case .coolDown:
            message = String(localized: "vcue.cooldown", defaultValue: "Cool down. Easy pace.")
        }
        return VoiceCue(type: .intervalPhaseStart, message: message, priority: .high)
    }

    static func intervalCountdownCue(seconds: Int) -> VoiceCue {
        VoiceCue(type: .intervalCountdown, message: "\(seconds)", priority: .high)
    }

    static func intervalWorkoutCompleteCue(
        totalWorkTime: TimeInterval,
        totalIntervals: Int
    ) -> VoiceCue {
        let timeStr = spokenDuration(totalWorkTime)
        let message = String(localized: "vcue.intervalComplete", defaultValue: "Interval workout complete. \(totalIntervals) intervals in \(timeStr).")
        return VoiceCue(type: .intervalWorkoutComplete, message: message, priority: .high)
    }

    // MARK: - Run State

    static func runStateCue(type: VoiceCueType) -> VoiceCue {
        let message: String
        switch type {
        case .runStarted: message = String(localized: "vcue.runStarted", defaultValue: "Run started. Good luck!")
        case .runPaused: message = String(localized: "vcue.runPaused", defaultValue: "Run paused.")
        case .runResumed: message = String(localized: "vcue.runResumed", defaultValue: "Run resumed.")
        case .autoPaused: message = String(localized: "vcue.autoPaused", defaultValue: "Auto paused.")
        default: message = ""
        }
        return VoiceCue(type: type, message: message, priority: .medium)
    }

    // MARK: - Formatting Helpers

    private static func spokenPace(_ secondsPerKm: TimeInterval, isMetric: Bool) -> String {
        let unit: UnitPreference = isMetric ? .metric : .imperial
        let converted = UnitFormatter.paceValue(secondsPerKm, unit: unit)
        guard converted > 0, converted.isFinite else { return String(localized: "vcue.pace.unknown", defaultValue: "unknown") }
        let minutes = Int(converted) / 60
        let seconds = Int(converted) % 60
        let unitLabel = isMetric
            ? String(localized: "vcue.pace.perKm", defaultValue: "per kilometer")
            : String(localized: "vcue.pace.perMile", defaultValue: "per mile")
        if seconds == 0 {
            return String(localized: "vcue.pace.minOnly", defaultValue: "\(minutes) minutes \(unitLabel)")
        }
        return String(localized: "vcue.pace.minSec", defaultValue: "\(minutes) minutes \(seconds) seconds \(unitLabel)")
    }

    static func spokenDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        var parts: [String] = []
        if hours > 0 {
            let word = hours == 1
                ? String(localized: "vcue.dur.hour", defaultValue: "hour")
                : String(localized: "vcue.dur.hours", defaultValue: "hours")
            parts.append("\(hours) \(word)")
        }
        if minutes > 0 {
            let word = minutes == 1
                ? String(localized: "vcue.dur.minute", defaultValue: "minute")
                : String(localized: "vcue.dur.minutes", defaultValue: "minutes")
            parts.append("\(minutes) \(word)")
        }
        if secs > 0 && hours == 0 {
            let word = secs == 1
                ? String(localized: "vcue.dur.second", defaultValue: "second")
                : String(localized: "vcue.dur.seconds", defaultValue: "seconds")
            parts.append("\(secs) \(word)")
        }
        return parts.isEmpty ? String(localized: "vcue.dur.zero", defaultValue: "0 seconds") : parts.joined(separator: " ")
    }
}
