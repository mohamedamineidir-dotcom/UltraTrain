import Foundation

enum RacePacingAlertCalculator {

    struct Input: Sendable {
        let currentPaceSecondsPerKm: Double
        let segmentTargetPaceSecondsPerKm: Double
        let segmentName: String
        let distanceKm: Double
        let elapsedTimeSinceLastAlert: TimeInterval
        let previousAlertType: PacingAlertType?
    }

    static func evaluate(_ input: Input) -> PacingAlert? {
        guard input.distanceKm >= AppConfiguration.PacingAlerts.minDistanceKm else { return nil }
        guard input.elapsedTimeSinceLastAlert >= AppConfiguration.PacingAlerts.cooldownSeconds else { return nil }
        guard input.currentPaceSecondsPerKm > 0,
              input.segmentTargetPaceSecondsPerKm > 0 else { return nil }

        let deviationPercent = ((input.currentPaceSecondsPerKm - input.segmentTargetPaceSecondsPerKm)
                                / input.segmentTargetPaceSecondsPerKm) * 100
        let absDeviation = abs(deviationPercent)

        if absDeviation <= AppConfiguration.PacingAlerts.onPaceBandPercent {
            if let prev = input.previousAlertType, prev == .tooFast || prev == .tooSlow {
                return PacingAlert(
                    id: UUID(),
                    type: .backOnPace,
                    severity: .positive,
                    message: "Back on target pace!",
                    deviationPercent: deviationPercent
                )
            }
            return nil
        }

        guard absDeviation >= AppConfiguration.PacingAlerts.minorDeviationPercent else { return nil }

        let isTooSlow = deviationPercent > 0
        let type: PacingAlertType = isTooSlow ? .tooSlow : .tooFast
        let severity: PacingAlertSeverity = absDeviation >= AppConfiguration.PacingAlerts.majorDeviationPercent
            ? .major : .minor

        let message = buildMessage(
            type: type,
            severity: severity,
            deviationPercent: absDeviation,
            segmentName: input.segmentName
        )

        return PacingAlert(
            id: UUID(),
            type: type,
            severity: severity,
            message: message,
            deviationPercent: deviationPercent
        )
    }

    private static func buildMessage(
        type: PacingAlertType,
        severity: PacingAlertSeverity,
        deviationPercent: Double,
        segmentName: String
    ) -> String {
        let pct = Int(deviationPercent)
        return switch (type, severity) {
        case (.tooFast, .major): "\(segmentName): Way too fast! \(pct)% above target"
        case (.tooFast, .minor): "\(segmentName): Slightly fast — \(pct)% above target"
        case (.tooSlow, .major): "\(segmentName): Falling behind! \(pct)% below target"
        case (.tooSlow, .minor): "\(segmentName): Slightly slow — \(pct)% below target"
        default: ""
        }
    }
}
