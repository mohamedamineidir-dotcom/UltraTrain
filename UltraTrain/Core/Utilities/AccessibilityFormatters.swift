import Foundation

enum AccessibilityFormatters {

    /// Converts pace string like "5:30" into VoiceOver-friendly text.
    /// Returns e.g. "5 minutes 30 seconds per kilometer".
    static func pace(_ paceString: String, unit: UnitPreference) -> String {
        let parts = paceString.split(separator: ":").map(String.init)
        guard parts.count == 2,
              let minutes = Int(parts[0]),
              let seconds = Int(parts[1]) else {
            return paceString
        }
        let unitName = unit == .metric ? "kilometer" : "mile"
        if seconds == 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") per \(unitName)"
        }
        return "\(minutes) minute\(minutes == 1 ? "" : "s") \(seconds) second\(seconds == 1 ? "" : "s") per \(unitName)"
    }

    /// Converts seconds into VoiceOver-friendly text.
    /// Returns e.g. "1 hour 15 minutes".
    static func duration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    }

    /// Converts elevation in meters to VoiceOver-friendly text.
    /// Returns e.g. "450 meters elevation gain".
    static func elevation(_ meters: Double, unit: UnitPreference) -> String {
        let value = UnitFormatter.elevationValue(meters, unit: unit)
        let unitName = unit == .metric ? "meters" : "feet"
        return "\(Int(value)) \(unitName) elevation gain"
    }

    /// Converts distance in km to VoiceOver-friendly text.
    /// Returns e.g. "21.5 kilometers".
    static func distance(_ km: Double, unit: UnitPreference) -> String {
        let value = UnitFormatter.distanceValue(km, unit: unit)
        let unitName = unit == .metric ? "kilometers" : "miles"
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        return "\(formatted) \(unitName)"
    }
}
