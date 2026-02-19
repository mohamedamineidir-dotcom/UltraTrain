import Foundation

enum ElevationCalculator {

    // MARK: - Elevation Changes

    static func elevationChanges(_ points: [TrackPoint]) -> (gainM: Double, lossM: Double) {
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

    // MARK: - Elevation Profile

    static func elevationProfile(from points: [TrackPoint]) -> [ElevationProfilePoint] {
        guard points.count >= 2 else { return [] }

        var result: [ElevationProfilePoint] = []
        var cumulativeDistanceM: Double = 0
        let sampleIntervalM: Double = 50

        result.append(ElevationProfilePoint(
            distanceKm: 0,
            altitudeM: points[0].altitudeM
        ))

        var lastSampledDistance: Double = 0

        for i in 1..<points.count {
            let segmentM = RunStatisticsCalculator.haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
            cumulativeDistanceM += segmentM

            if cumulativeDistanceM - lastSampledDistance >= sampleIntervalM {
                result.append(ElevationProfilePoint(
                    distanceKm: cumulativeDistanceM / 1000,
                    altitudeM: points[i].altitudeM
                ))
                lastSampledDistance = cumulativeDistanceM
            }
        }

        let lastPoint = points[points.count - 1]
        if cumulativeDistanceM - lastSampledDistance > 10 {
            result.append(ElevationProfilePoint(
                distanceKm: cumulativeDistanceM / 1000,
                altitudeM: lastPoint.altitudeM
            ))
        }

        return result
    }

    // MARK: - Elevation Segments

    static func buildElevationSegments(from points: [TrackPoint]) -> [ElevationSegment] {
        guard points.count >= 2 else { return [] }

        var segments: [ElevationSegment] = []
        var cumulativeDistanceM: Double = 0
        var segmentStartIndex = 0
        var currentKm = 1

        for i in 1..<points.count {
            let distM = RunStatisticsCalculator.haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
            cumulativeDistanceM += distM

            if cumulativeDistanceM >= Double(currentKm) * 1000 {
                let segmentPoints = Array(points[segmentStartIndex...i])
                let elevationChange = points[i].altitudeM - points[segmentStartIndex].altitudeM
                let horizontalDistM = segmentDistanceM(segmentPoints)
                let gradient = horizontalDistM > 0 ? (elevationChange / horizontalDistM) * 100 : 0

                segments.append(ElevationSegment(
                    coordinates: segmentPoints.map { ($0.latitude, $0.longitude) },
                    averageGradient: gradient,
                    kilometerNumber: currentKm
                ))

                segmentStartIndex = i
                currentKm += 1
            }
        }

        if segmentStartIndex < points.count - 1 {
            let segmentPoints = Array(points[segmentStartIndex..<points.count])
            let elevationChange = points[points.count - 1].altitudeM - points[segmentStartIndex].altitudeM
            let horizontalDistM = segmentDistanceM(segmentPoints)
            let gradient = horizontalDistM > 0 ? (elevationChange / horizontalDistM) * 100 : 0

            segments.append(ElevationSegment(
                coordinates: segmentPoints.map { ($0.latitude, $0.longitude) },
                averageGradient: gradient,
                kilometerNumber: currentKm
            ))
        }

        return segments
    }

    private static func segmentDistanceM(_ points: [TrackPoint]) -> Double {
        guard points.count >= 2 else { return 0 }
        var total: Double = 0
        for i in 1..<points.count {
            total += RunStatisticsCalculator.haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
        }
        return total
    }

    // MARK: - Elevation Extremes

    static func elevationExtremes(
        from profile: [ElevationProfilePoint]
    ) -> (highest: ElevationProfilePoint, lowest: ElevationProfilePoint)? {
        guard let highest = profile.max(by: { $0.altitudeM < $1.altitudeM }),
              let lowest = profile.min(by: { $0.altitudeM < $1.altitudeM }) else {
            return nil
        }
        return (highest, lowest)
    }

    // MARK: - Nearest Track Point

    static func nearestTrackPoint(
        at distanceKm: Double,
        in points: [TrackPoint]
    ) -> TrackPoint? {
        guard points.count >= 2 else { return points.first }

        let targetM = distanceKm * 1000
        var cumulativeM: Double = 0

        for i in 1..<points.count {
            let segmentM = RunStatisticsCalculator.haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
            cumulativeM += segmentM

            if cumulativeM >= targetM {
                let overshoot = cumulativeM - targetM
                let undershoot = targetM - (cumulativeM - segmentM)
                return overshoot < undershoot ? points[i] : points[i - 1]
            }
        }

        return points.last
    }
}
