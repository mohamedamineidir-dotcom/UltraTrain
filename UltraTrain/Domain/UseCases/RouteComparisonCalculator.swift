import Foundation

enum RouteComparisonCalculator {

    struct RouteComparison: Equatable, Sendable {
        let maxDeviationMeters: Double
        let averageDeviationMeters: Double
        let totalActualDistanceKm: Double
        let totalPlannedDistanceKm: Double
        let deviationSegments: [DeviationSegment]
    }

    struct DeviationSegment: Equatable, Sendable {
        let startIndex: Int
        let endIndex: Int
        let averageDeviationMeters: Double
        let isSignificant: Bool
    }

    static func compare(
        actual: [TrackPoint],
        planned: [TrackPoint]
    ) -> RouteComparison {
        guard !actual.isEmpty, !planned.isEmpty else {
            return RouteComparison(
                maxDeviationMeters: 0,
                averageDeviationMeters: 0,
                totalActualDistanceKm: 0,
                totalPlannedDistanceKm: 0,
                deviationSegments: []
            )
        }

        let actualDist = RunStatisticsCalculator.totalDistanceKm(actual)
        let plannedDist = RunStatisticsCalculator.totalDistanceKm(planned)

        var totalDeviation: Double = 0
        var maxDeviation: Double = 0
        var deviations: [(index: Int, meters: Double)] = []

        for (i, point) in actual.enumerated() {
            let nearest = nearestDistanceToRoute(
                point: point,
                route: planned
            )
            deviations.append((index: i, meters: nearest))
            totalDeviation += nearest
            if nearest > maxDeviation {
                maxDeviation = nearest
            }
        }

        let avgDeviation = totalDeviation / Double(actual.count)
        let segments = buildDeviationSegments(deviations: deviations)

        return RouteComparison(
            maxDeviationMeters: maxDeviation,
            averageDeviationMeters: avgDeviation,
            totalActualDistanceKm: actualDist,
            totalPlannedDistanceKm: plannedDist,
            deviationSegments: segments
        )
    }

    // MARK: - Private

    private static func nearestDistanceToRoute(
        point: TrackPoint,
        route: [TrackPoint]
    ) -> Double {
        var minDist = Double.greatestFiniteMagnitude

        for i in 0..<max(1, route.count - 1) {
            let segStart = route[i]
            let segEnd = i + 1 < route.count ? route[i + 1] : route[i]
            let dist = pointToSegmentDistance(
                point: point,
                segStart: segStart,
                segEnd: segEnd
            )
            if dist < minDist {
                minDist = dist
            }
        }

        return minDist == .greatestFiniteMagnitude ? 0 : minDist
    }

    private static func pointToSegmentDistance(
        point: TrackPoint,
        segStart: TrackPoint,
        segEnd: TrackPoint
    ) -> Double {
        let dx = segEnd.longitude - segStart.longitude
        let dy = segEnd.latitude - segStart.latitude

        if dx == 0 && dy == 0 {
            return RunStatisticsCalculator.haversineDistance(
                lat1: point.latitude, lon1: point.longitude,
                lat2: segStart.latitude, lon2: segStart.longitude
            )
        }

        let t = max(0, min(1,
            ((point.longitude - segStart.longitude) * dx
                + (point.latitude - segStart.latitude) * dy)
                / (dx * dx + dy * dy)
        ))

        let projLat = segStart.latitude + t * dy
        let projLon = segStart.longitude + t * dx

        return RunStatisticsCalculator.haversineDistance(
            lat1: point.latitude, lon1: point.longitude,
            lat2: projLat, lon2: projLon
        )
    }

    private static func buildDeviationSegments(
        deviations: [(index: Int, meters: Double)]
    ) -> [DeviationSegment] {
        guard !deviations.isEmpty else { return [] }

        let significantThreshold: Double = 100
        var segments: [DeviationSegment] = []
        var segStart: Int?
        var segSum: Double = 0
        var segCount: Int = 0

        for dev in deviations {
            if dev.meters > significantThreshold {
                if segStart == nil { segStart = dev.index }
                segSum += dev.meters
                segCount += 1
            } else if let start = segStart {
                segments.append(DeviationSegment(
                    startIndex: start,
                    endIndex: dev.index - 1,
                    averageDeviationMeters: segSum / Double(segCount),
                    isSignificant: true
                ))
                segStart = nil
                segSum = 0
                segCount = 0
            }
        }

        if let start = segStart, segCount > 0 {
            segments.append(DeviationSegment(
                startIndex: start,
                endIndex: deviations[deviations.count - 1].index,
                averageDeviationMeters: segSum / Double(segCount),
                isSignificant: true
            ))
        }

        return segments
    }
}
