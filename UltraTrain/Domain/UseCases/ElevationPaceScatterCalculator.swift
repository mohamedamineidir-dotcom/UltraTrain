import Foundation

enum ElevationPaceScatterCalculator {

    struct GradientPacePoint: Identifiable, Equatable, Sendable {
        let id: Int
        var gradientPercent: Double
        var paceSecondsPerKm: Double
        var distanceKm: Double
        var kilometerNumber: Int
    }

    // MARK: - Public

    static func compute(
        trackPoints: [TrackPoint],
        segmentLengthMeters: Double = 200
    ) -> [GradientPacePoint] {
        guard trackPoints.count >= 2, segmentLengthMeters > 0 else { return [] }

        var results: [GradientPacePoint] = []
        var segmentStartIndex = 0
        var accumulatedDistanceM: Double = 0
        var totalCumulativeDistanceM: Double = 0
        var pointId = 0

        for i in 1..<trackPoints.count {
            let prev = trackPoints[i - 1]
            let curr = trackPoints[i]

            let stepDistM = RunStatisticsCalculator.haversineDistance(
                lat1: prev.latitude, lon1: prev.longitude,
                lat2: curr.latitude, lon2: curr.longitude
            )

            accumulatedDistanceM += stepDistM
            totalCumulativeDistanceM += stepDistM

            if accumulatedDistanceM >= segmentLengthMeters {
                let startPoint = trackPoints[segmentStartIndex]
                let endPoint = trackPoints[i]

                let timeDelta = endPoint.timestamp.timeIntervalSince(startPoint.timestamp)
                guard timeDelta > 0 else {
                    segmentStartIndex = i
                    accumulatedDistanceM = 0
                    continue
                }

                let segmentDistKm = accumulatedDistanceM / 1000
                guard segmentDistKm > 0 else {
                    segmentStartIndex = i
                    accumulatedDistanceM = 0
                    continue
                }

                let paceSecondsPerKm = timeDelta / segmentDistKm

                // Filter unreasonable paces
                guard paceSecondsPerKm >= 120, paceSecondsPerKm <= 900 else {
                    segmentStartIndex = i
                    accumulatedDistanceM = 0
                    continue
                }

                let altitudeDiff = endPoint.altitudeM - startPoint.altitudeM
                let horizontalDistM = accumulatedDistanceM
                let gradientPercent = horizontalDistM > 0
                    ? (altitudeDiff / horizontalDistM) * 100
                    : 0

                // Filter extreme gradients
                guard abs(gradientPercent) <= 50 else {
                    segmentStartIndex = i
                    accumulatedDistanceM = 0
                    continue
                }

                let kmNumber = Int(totalCumulativeDistanceM / 1000)

                results.append(GradientPacePoint(
                    id: pointId,
                    gradientPercent: gradientPercent,
                    paceSecondsPerKm: paceSecondsPerKm,
                    distanceKm: segmentDistKm,
                    kilometerNumber: max(kmNumber, 1)
                ))

                pointId += 1
                segmentStartIndex = i
                accumulatedDistanceM = 0
            }
        }

        return results
    }
}
