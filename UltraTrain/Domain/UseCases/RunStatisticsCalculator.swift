import Foundation

enum RunStatisticsCalculator {

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

    static func totalDistanceKm(_ points: [TrackPoint]) -> Double {
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

    static func buildSplits(from points: [TrackPoint]) -> [Split] {
        guard points.count >= 2 else { return [] }

        var splits: [Split] = []
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

                splits.append(Split(
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

    // MARK: - Heart Rate Zone

    static func heartRateZone(heartRate: Int, maxHeartRate: Int) -> Int {
        guard maxHeartRate > 0 else { return 1 }
        let percent = Double(heartRate) / Double(maxHeartRate) * 100
        switch percent {
        case ..<60: return 1
        case 60..<70: return 2
        case 70..<80: return 3
        case 80..<90: return 4
        default: return 5
        }
    }

    // MARK: - Heart Rate Zone Distribution

    private static let zoneNames = ["Recovery", "Aerobic", "Tempo", "Threshold", "VO2max"]

    static func heartRateZoneDistribution(
        from points: [TrackPoint],
        maxHeartRate: Int
    ) -> [HeartRateZoneDistribution] {
        var zoneDurations: [Int: TimeInterval] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        var totalDurationWithHR: TimeInterval = 0

        for i in 1..<points.count {
            guard let hr = points[i].heartRate, points[i - 1].heartRate != nil else { continue }
            let timeDelta = points[i].timestamp.timeIntervalSince(points[i - 1].timestamp)
            guard timeDelta > 0, timeDelta < 60 else { continue }

            let zone = heartRateZone(heartRate: hr, maxHeartRate: maxHeartRate)
            zoneDurations[zone, default: 0] += timeDelta
            totalDurationWithHR += timeDelta
        }

        return (1...5).map { zone in
            let duration = zoneDurations[zone] ?? 0
            let percentage = totalDurationWithHR > 0 ? (duration / totalDurationWithHR) * 100 : 0
            return HeartRateZoneDistribution(
                zone: zone,
                zoneName: zoneNames[zone - 1],
                durationSeconds: duration,
                percentage: percentage
            )
        }
    }

    // MARK: - Route Segments

    static func buildRouteSegments(from points: [TrackPoint]) -> [RouteSegment] {
        guard points.count >= 2 else { return [] }

        var segments: [RouteSegment] = []
        var cumulativeDistanceM: Double = 0
        var segmentStartIndex = 0
        var currentKm = 1

        for i in 1..<points.count {
            let distM = haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
            cumulativeDistanceM += distM

            if cumulativeDistanceM >= Double(currentKm) * 1000 {
                let segmentPoints = Array(points[segmentStartIndex...i])
                let duration = points[i].timestamp.timeIntervalSince(points[segmentStartIndex].timestamp)
                let pace = duration > 0 ? duration : 0

                segments.append(RouteSegment(
                    coordinates: segmentPoints.map { ($0.latitude, $0.longitude) },
                    paceSecondsPerKm: pace,
                    kilometerNumber: currentKm
                ))

                segmentStartIndex = i
                currentKm += 1
            }
        }

        // Final partial segment
        if segmentStartIndex < points.count - 1 {
            let segmentPoints = Array(points[segmentStartIndex..<points.count])
            let duration = points[points.count - 1].timestamp.timeIntervalSince(points[segmentStartIndex].timestamp)
            let partialDistKm = (cumulativeDistanceM - Double(currentKm - 1) * 1000) / 1000
            let pace = partialDistKm > 0 ? duration / partialDistKm : 0

            segments.append(RouteSegment(
                coordinates: segmentPoints.map { ($0.latitude, $0.longitude) },
                paceSecondsPerKm: pace,
                kilometerNumber: currentKm
            ))
        }

        return segments
    }

    // MARK: - Plan Comparison

    static func buildPlanComparison(run: CompletedRun, session: TrainingSession) -> PlanComparison {
        let plannedPace = session.plannedDistanceKm > 0
            ? session.plannedDuration / session.plannedDistanceKm
            : 0

        return PlanComparison(
            plannedDistanceKm: session.plannedDistanceKm,
            actualDistanceKm: run.distanceKm,
            plannedElevationGainM: session.plannedElevationGainM,
            actualElevationGainM: run.elevationGainM,
            plannedDuration: session.plannedDuration,
            actualDuration: run.duration,
            plannedPaceSecondsPerKm: plannedPace,
            actualPaceSecondsPerKm: run.averagePaceSecondsPerKm,
            sessionType: session.type,
            sessionDescription: session.description
        )
    }
}
