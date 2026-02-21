import Foundation

enum ZoneDriftAlertCalculator {

    struct ZoneDriftAlert: Equatable, Sendable {
        let message: String
        let currentZone: Int
        let targetZone: Int
        let driftDuration: TimeInterval
        let severity: DriftSeverity
    }

    enum DriftSeverity: String, Sendable, Equatable {
        case mild
        case moderate
        case significant
    }

    struct DriftConfig: Sendable {
        let mildThresholdSeconds: TimeInterval
        let moderateThresholdSeconds: TimeInterval
        let significantThresholdSeconds: TimeInterval
        let cooldownSeconds: TimeInterval

        static var `default`: DriftConfig {
            DriftConfig(
                mildThresholdSeconds: AppConfiguration.HRZoneAlerts.mildDriftSeconds,
                moderateThresholdSeconds: AppConfiguration.HRZoneAlerts.moderateDriftSeconds,
                significantThresholdSeconds: AppConfiguration.HRZoneAlerts.significantDriftSeconds,
                cooldownSeconds: AppConfiguration.HRZoneAlerts.alertCooldownSeconds
            )
        }
    }

    static func evaluate(
        state: LiveHRZoneTracker.LiveZoneState,
        config: DriftConfig = .default
    ) -> ZoneDriftAlert? {
        guard let target = state.targetZone else { return nil }
        guard !state.isInTargetZone else { return nil }

        let driftDuration = state.timeInCurrentZone
        guard driftDuration >= config.mildThresholdSeconds else { return nil }

        let severity: DriftSeverity
        if driftDuration >= config.significantThresholdSeconds {
            severity = .significant
        } else if driftDuration >= config.moderateThresholdSeconds {
            severity = .moderate
        } else {
            severity = .mild
        }

        let direction = state.currentZone > target ? "Slow down" : "Pick up pace"
        let durationFormatted = formatDuration(driftDuration)
        let message = "\(direction) — Zone \(state.currentZone) for \(durationFormatted), target is Zone \(target)"

        return ZoneDriftAlert(
            message: message,
            currentZone: state.currentZone,
            targetZone: target,
            driftDuration: driftDuration,
            severity: severity
        )
    }

    private static func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
