import Foundation

enum ZoneComplianceCalculator {

    struct ZoneCompliance: Equatable, Sendable {
        let targetZone: Int
        let timeInTargetZone: TimeInterval
        let totalTimeWithHR: TimeInterval
        let compliancePercent: Double
        let zoneDistribution: [Int: Double]
        let rating: ComplianceRating
    }

    enum ComplianceRating: String, Sendable, Equatable {
        case excellent
        case good
        case fair
        case poor
    }

    static func calculate(
        trackPoints: [TrackPoint],
        targetZone: Int,
        maxHeartRate: Int,
        customThresholds: [Int]? = nil
    ) -> ZoneCompliance {
        guard trackPoints.count >= 2 else {
            return ZoneCompliance(
                targetZone: targetZone,
                timeInTargetZone: 0,
                totalTimeWithHR: 0,
                compliancePercent: 0,
                zoneDistribution: [:],
                rating: .poor
            )
        }

        var zoneDurations: [Int: TimeInterval] = [:]
        var totalDuration: TimeInterval = 0
        var targetDuration: TimeInterval = 0

        for i in 1..<trackPoints.count {
            guard let hr = trackPoints[i].heartRate, hr > 0 else { continue }
            let timeDelta = trackPoints[i].timestamp.timeIntervalSince(trackPoints[i - 1].timestamp)
            guard timeDelta > 0, timeDelta < 60 else { continue }

            let zone = RunStatisticsCalculator.heartRateZone(
                heartRate: hr, maxHeartRate: maxHeartRate, customThresholds: customThresholds
            )
            zoneDurations[zone, default: 0] += timeDelta
            totalDuration += timeDelta
            if zone == targetZone {
                targetDuration += timeDelta
            }
        }

        let compliancePercent = totalDuration > 0 ? (targetDuration / totalDuration) * 100 : 0

        var distribution: [Int: Double] = [:]
        for (zone, duration) in zoneDurations {
            distribution[zone] = totalDuration > 0 ? (duration / totalDuration) * 100 : 0
        }

        let rating: ComplianceRating
        switch compliancePercent {
        case 90...: rating = .excellent
        case 70..<90: rating = .good
        case 50..<70: rating = .fair
        default: rating = .poor
        }

        return ZoneCompliance(
            targetZone: targetZone,
            timeInTargetZone: targetDuration,
            totalTimeWithHR: totalDuration,
            compliancePercent: compliancePercent,
            zoneDistribution: distribution,
            rating: rating
        )
    }
}
