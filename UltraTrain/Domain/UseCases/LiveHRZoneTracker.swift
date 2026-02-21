import Foundation

enum LiveHRZoneTracker {

    struct LiveZoneState: Equatable, Sendable {
        let currentZone: Int
        let currentZoneName: String
        let timeInCurrentZone: TimeInterval
        let zoneDistribution: [Int: TimeInterval]
        let targetZone: Int?
        let isInTargetZone: Bool
    }

    private static let zoneNames = ["", "Recovery", "Aerobic", "Tempo", "Threshold", "VO2max"]

    static func update(
        heartRate: Int,
        maxHeartRate: Int,
        customThresholds: [Int]?,
        targetZone: Int?,
        previousState: LiveZoneState?,
        elapsed: TimeInterval
    ) -> LiveZoneState {
        let zone = RunStatisticsCalculator.heartRateZone(
            heartRate: heartRate,
            maxHeartRate: maxHeartRate,
            customThresholds: customThresholds
        )
        let zoneName = zone >= 1 && zone <= 5 ? zoneNames[zone] : "Unknown"

        var distribution = previousState?.zoneDistribution ?? [:]
        let timeDelta: TimeInterval
        if let prev = previousState {
            timeDelta = elapsed > 0 ? 1.0 : 0
            distribution[prev.currentZone, default: 0] += timeDelta
        } else {
            timeDelta = 0
        }

        let timeInCurrent: TimeInterval
        if let prev = previousState, prev.currentZone == zone {
            timeInCurrent = prev.timeInCurrentZone + timeDelta
        } else {
            timeInCurrent = 0
        }

        return LiveZoneState(
            currentZone: zone,
            currentZoneName: zoneName,
            timeInCurrentZone: timeInCurrent,
            zoneDistribution: distribution,
            targetZone: targetZone,
            isInTargetZone: targetZone == zone
        )
    }
}
