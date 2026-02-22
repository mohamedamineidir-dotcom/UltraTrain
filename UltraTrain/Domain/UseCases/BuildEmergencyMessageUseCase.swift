import Foundation

enum BuildEmergencyMessageUseCase {

    static func build(
        alertType: SafetyAlertType,
        latitude: Double?,
        longitude: Double?,
        distanceKm: Double,
        elapsedTime: TimeInterval,
        includeLocation: Bool
    ) -> String {
        var lines: [String] = []

        lines.append("⚠️ EMERGENCY ALERT: \(alertType.displayName)")
        lines.append("")
        lines.append("An emergency alert was triggered from the UltraTrain running app.")
        lines.append("")

        switch alertType {
        case .sos:
            lines.append("The runner manually triggered an SOS.")
        case .fallDetected:
            lines.append("A possible fall/crash was detected.")
        case .noMovement:
            lines.append("No movement has been detected for several minutes.")
        case .safetyTimerExpired:
            lines.append("The safety check-in timer has expired without response.")
        }

        lines.append("")
        let min = Int(elapsedTime) / 60
        lines.append("Run stats: \(String(format: "%.1f", distanceKm)) km in \(min) min")

        if includeLocation, let lat = latitude, let lon = longitude {
            lines.append("")
            lines.append("Last known location:")
            lines.append("https://maps.apple.com/?ll=\(lat),\(lon)&q=Runner%20Location")
        }

        return lines.joined(separator: "\n")
    }
}
