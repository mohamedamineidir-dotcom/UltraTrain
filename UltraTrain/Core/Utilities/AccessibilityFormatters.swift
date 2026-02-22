import Foundation

enum AccessibilityFormatters {

    /// Converts pace string like "5:30" into VoiceOver-friendly text.
    static func pace(_ paceString: String, unit: UnitPreference) -> String {
        let parts = paceString.split(separator: ":").map(String.init)
        guard parts.count == 2,
              let minutes = Int(parts[0]),
              let seconds = Int(parts[1]) else {
            return paceString
        }
        let unitName = unit == .metric
            ? String(localized: "per kilometer")
            : String(localized: "per mile")
        let m = String(localized: "min")
        let s = String(localized: "sec")
        if seconds == 0 {
            return "\(minutes) \(m) \(unitName)"
        }
        return "\(minutes) \(m) \(seconds) \(s) \(unitName)"
    }

    /// Converts seconds into VoiceOver-friendly text.
    static func duration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let h = String(localized: "hr")
        let m = String(localized: "min")

        if hours > 0 && minutes > 0 {
            return "\(hours) \(h) \(minutes) \(m)"
        }
        if hours > 0 {
            return "\(hours) \(h)"
        }
        return "\(minutes) \(m)"
    }

    /// Converts elevation in meters to VoiceOver-friendly text.
    static func elevation(_ meters: Double, unit: UnitPreference) -> String {
        let value = UnitFormatter.elevationValue(meters, unit: unit)
        let unitName = unit == .metric
            ? String(localized: "m")
            : String(localized: "ft")
        return "\(Int(value)) \(unitName) D+"
    }

    /// Converts distance in km to VoiceOver-friendly text.
    static func distance(_ km: Double, unit: UnitPreference) -> String {
        let value = UnitFormatter.distanceValue(km, unit: unit)
        let unitName = unit == .metric
            ? String(localized: "km")
            : String(localized: "mi")
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        return "\(formatted) \(unitName)"
    }

    /// Returns e.g. "145 bpm".
    static func heartRate(_ bpm: Int) -> String {
        "\(bpm) \(String(localized: "bpm"))"
    }

    /// Returns e.g. "85%".
    static func percentage(_ value: Double) -> String {
        "\(Int(value))%"
    }

    /// Returns e.g. "March 3 to March 9".
    static func dateRange(from start: Date, to end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        let to = String(localized: "to")
        return "\(formatter.string(from: start)) \(to) \(formatter.string(from: end))"
    }

    /// Returns a chart summary label for VoiceOver.
    static func chartSummary(title: String, dataPoints: Int, trend: String? = nil) -> String {
        var result = "\(title). \(dataPoints) \(String(localized: "results"))."
        if let trend {
            result += " \(trend)."
        }
        return result
    }
}
