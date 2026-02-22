import Foundation

enum WatchRunCalculator {

    // MARK: - Distance

    static func haversineDistance(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        let earthRadiusM: Double = 6_371_000
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusM * c
    }

    static func totalDistanceKm(_ points: [WatchTrackPoint]) -> Double {
        guard points.count >= 2 else { return 0 }
        var total: Double = 0
        for i in 1..<points.count {
            total += haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
        }
        return total / 1000
    }

    // MARK: - Elevation

    static func elevationChanges(_ points: [WatchTrackPoint]) -> (gainM: Double, lossM: Double) {
        guard points.count >= 2 else { return (0, 0) }
        var gain: Double = 0
        var loss: Double = 0
        for i in 1..<points.count {
            let diff = points[i].altitudeM - points[i - 1].altitudeM
            if diff > 0 {
                gain += diff
            } else {
                loss += abs(diff)
            }
        }
        return (gain, loss)
    }

    // MARK: - Pace

    static func averagePace(distanceKm: Double, duration: TimeInterval) -> Double {
        guard distanceKm > 0 else { return 0 }
        return duration / distanceKm
    }

    static func formatPace(_ secondsPerKm: Double) -> String {
        guard secondsPerKm > 0, secondsPerKm.isFinite else { return "--:--" }
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Splits

    static func buildSplits(from points: [WatchTrackPoint]) -> [WatchSplit] {
        guard points.count >= 2 else { return [] }

        var splits: [WatchSplit] = []
        var cumulativeDistance: Double = 0
        var splitStartIndex = 0
        var currentKm = 1

        for i in 1..<points.count {
            let segmentDistance = haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
            cumulativeDistance += segmentDistance

            if cumulativeDistance >= Double(currentKm) * 1000 {
                let splitDuration = points[i].timestamp.timeIntervalSince(points[splitStartIndex].timestamp)
                let elevationChange = points[i].altitudeM - points[splitStartIndex].altitudeM
                let heartRates = points[splitStartIndex...i].compactMap(\.heartRate)
                let avgHR = heartRates.isEmpty ? nil : heartRates.reduce(0, +) / heartRates.count

                splits.append(WatchSplit(
                    id: UUID(),
                    kilometerNumber: currentKm,
                    duration: splitDuration,
                    elevationChangeM: elevationChange,
                    averageHeartRate: avgHR
                ))

                splitStartIndex = i
                currentKm += 1
            }
        }

        return splits
    }

    // MARK: - Live Split Detection

    static func liveSplitCheck(
        trackPoints: [WatchTrackPoint],
        previousSplitCount: Int
    ) -> WatchSplit? {
        let currentSplits = buildSplits(from: trackPoints)
        guard currentSplits.count > previousSplitCount,
              let newSplit = currentSplits.last else { return nil }
        return newSplit
    }
}
