import Foundation

enum PaceDistributionCalculator {

    struct PaceBucket: Identifiable, Equatable, Sendable {
        let id: Int
        var rangeLabel: String
        var rangeLowerSeconds: Double
        var durationSeconds: TimeInterval
        var distanceKm: Double
        var percentage: Double
    }

    // MARK: - Public

    static func compute(
        trackPoints: [TrackPoint],
        bucketWidthSeconds: Double = 30
    ) -> [PaceBucket] {
        guard trackPoints.count >= 2, bucketWidthSeconds > 0 else { return [] }

        // Accumulate raw segment data per bucket
        var bucketDuration: [Int: TimeInterval] = [:]
        var bucketDistance: [Int: Double] = [:]

        for i in 1..<trackPoints.count {
            let prev = trackPoints[i - 1]
            let curr = trackPoints[i]

            let timeDelta = curr.timestamp.timeIntervalSince(prev.timestamp)
            guard timeDelta > 0, timeDelta <= 10 else { continue }

            let distanceM = RunStatisticsCalculator.haversineDistance(
                lat1: prev.latitude, lon1: prev.longitude,
                lat2: curr.latitude, lon2: curr.longitude
            )
            let distanceKm = distanceM / 1000
            guard distanceKm > 0 else { continue }

            let paceSecondsPerKm = timeDelta / distanceKm

            // Filter unreasonable paces: faster than 2:00/km (120s) or slower than 15:00/km (900s)
            guard paceSecondsPerKm >= 120, paceSecondsPerKm <= 900 else { continue }

            let bucketIndex = Int(floor(paceSecondsPerKm / bucketWidthSeconds))
            bucketDuration[bucketIndex, default: 0] += timeDelta
            bucketDistance[bucketIndex, default: 0] += distanceKm
        }

        guard !bucketDuration.isEmpty else { return [] }

        let totalDuration = bucketDuration.values.reduce(0, +)
        guard totalDuration > 0 else { return [] }

        let sortedKeys = bucketDuration.keys.sorted()

        return sortedKeys.enumerated().map { index, key in
            let lowerSeconds = Double(key) * bucketWidthSeconds
            let upperSeconds = lowerSeconds + bucketWidthSeconds
            let label = formatPaceRange(lower: lowerSeconds, upper: upperSeconds)
            let duration = bucketDuration[key] ?? 0
            let distance = bucketDistance[key] ?? 0
            let pct = (duration / totalDuration) * 100

            return PaceBucket(
                id: index,
                rangeLabel: label,
                rangeLowerSeconds: lowerSeconds,
                durationSeconds: duration,
                distanceKm: distance,
                percentage: pct
            )
        }
    }

    // MARK: - Private

    private static func formatPaceRange(lower: Double, upper: Double) -> String {
        let lowerStr = formatMinutesSeconds(lower)
        let upperStr = formatMinutesSeconds(upper)
        return "\(lowerStr)-\(upperStr)"
    }

    private static func formatMinutesSeconds(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
