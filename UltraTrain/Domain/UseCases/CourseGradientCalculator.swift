import Foundation

struct GradientSegment: Identifiable, Equatable, Sendable {
    let id = UUID()
    var distanceKm: Double
    var endDistanceKm: Double
    var altitudeM: Double
    var endAltitudeM: Double
    var gradientPercent: Double
    var category: GradientCategory

    static func == (lhs: GradientSegment, rhs: GradientSegment) -> Bool {
        lhs.distanceKm == rhs.distanceKm
            && lhs.endDistanceKm == rhs.endDistanceKm
            && lhs.altitudeM == rhs.altitudeM
            && lhs.endAltitudeM == rhs.endAltitudeM
            && lhs.gradientPercent == rhs.gradientPercent
            && lhs.category == rhs.category
    }
}

enum CourseGradientCalculator {

    private static let sampleIntervalM: Double = 100

    // MARK: - Build Gradient Profile

    static func buildGradientProfile(from trackPoints: [TrackPoint]) -> [GradientSegment] {
        guard trackPoints.count >= 2 else { return [] }

        let sampled = sampleAtInterval(trackPoints, intervalM: sampleIntervalM)
        guard sampled.count >= 2 else { return [] }

        var segments: [GradientSegment] = []

        for i in 1..<sampled.count {
            let prev = sampled[i - 1]
            let curr = sampled[i]

            let horizontalM = RunStatisticsCalculator.haversineDistance(
                lat1: prev.latitude, lon1: prev.longitude,
                lat2: curr.latitude, lon2: curr.longitude
            )

            guard horizontalM > 0 else { continue }

            let elevationDiff = curr.altitudeM - prev.altitudeM
            let gradient = (elevationDiff / horizontalM) * 100

            segments.append(GradientSegment(
                distanceKm: prev.cumulativeDistanceKm,
                endDistanceKm: curr.cumulativeDistanceKm,
                altitudeM: prev.altitudeM,
                endAltitudeM: curr.altitudeM,
                gradientPercent: gradient,
                category: GradientCategory.from(gradient: gradient)
            ))
        }

        return segments
    }

    // MARK: - Interpolated Altitude

    static func interpolatedAltitude(
        at distanceKm: Double,
        in segments: [GradientSegment]
    ) -> Double? {
        guard let segment = segments.first(where: {
            distanceKm >= $0.distanceKm && distanceKm <= $0.endDistanceKm
        }) else {
            return segments.last?.endAltitudeM
        }

        let segmentLength = segment.endDistanceKm - segment.distanceKm
        guard segmentLength > 0 else { return segment.altitudeM }

        let fraction = (distanceKm - segment.distanceKm) / segmentLength
        return segment.altitudeM + fraction * (segment.endAltitudeM - segment.altitudeM)
    }

    // MARK: - Sampling

    private struct SampledPoint {
        var latitude: Double
        var longitude: Double
        var altitudeM: Double
        var cumulativeDistanceKm: Double
    }

    private static func sampleAtInterval(
        _ points: [TrackPoint],
        intervalM: Double
    ) -> [SampledPoint] {
        guard let first = points.first else { return [] }

        var result: [SampledPoint] = [
            SampledPoint(
                latitude: first.latitude,
                longitude: first.longitude,
                altitudeM: first.altitudeM,
                cumulativeDistanceKm: 0
            )
        ]

        var cumulativeM: Double = 0
        var lastSampledM: Double = 0

        for i in 1..<points.count {
            let segmentM = RunStatisticsCalculator.haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
            cumulativeM += segmentM

            if cumulativeM - lastSampledM >= intervalM {
                result.append(SampledPoint(
                    latitude: points[i].latitude,
                    longitude: points[i].longitude,
                    altitudeM: points[i].altitudeM,
                    cumulativeDistanceKm: cumulativeM / 1000
                ))
                lastSampledM = cumulativeM
            }
        }

        if let last = points.last, cumulativeM - lastSampledM > 10 {
            result.append(SampledPoint(
                latitude: last.latitude,
                longitude: last.longitude,
                altitudeM: last.altitudeM,
                cumulativeDistanceKm: cumulativeM / 1000
            ))
        }

        return result
    }
}
