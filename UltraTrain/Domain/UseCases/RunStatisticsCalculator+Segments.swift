import Foundation

extension RunStatisticsCalculator {

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

    // MARK: - Heart Rate Segments

    static func buildHeartRateSegments(
        from points: [TrackPoint],
        maxHeartRate: Int,
        customThresholds: [Int]? = nil
    ) -> [HeartRateSegment] {
        guard points.count >= 2, maxHeartRate > 0 else { return [] }

        var segments: [HeartRateSegment] = []
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
                let heartRates = segmentPoints.compactMap(\.heartRate)
                let avgHR = heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / heartRates.count
                let zone = avgHR > 0 ? heartRateZone(heartRate: avgHR, maxHeartRate: maxHeartRate, customThresholds: customThresholds) : 1

                segments.append(HeartRateSegment(
                    coordinates: segmentPoints.map { ($0.latitude, $0.longitude) },
                    averageHeartRate: avgHR,
                    zone: zone,
                    kilometerNumber: currentKm
                ))

                segmentStartIndex = i
                currentKm += 1
            }
        }

        if segmentStartIndex < points.count - 1 {
            let segmentPoints = Array(points[segmentStartIndex..<points.count])
            let heartRates = segmentPoints.compactMap(\.heartRate)
            let avgHR = heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / heartRates.count
            let zone = avgHR > 0 ? heartRateZone(heartRate: avgHR, maxHeartRate: maxHeartRate, customThresholds: customThresholds) : 1

            segments.append(HeartRateSegment(
                coordinates: segmentPoints.map { ($0.latitude, $0.longitude) },
                averageHeartRate: avgHR,
                zone: zone,
                kilometerNumber: currentKm
            ))
        }

        return segments
    }

    // MARK: - Distance Markers

    static func buildDistanceMarkers(
        from points: [TrackPoint]
    ) -> [(km: Int, coordinate: (Double, Double))] {
        guard points.count >= 2 else { return [] }

        var markers: [(km: Int, coordinate: (Double, Double))] = []
        var cumulativeDistanceM: Double = 0
        var nextKm = 1

        for i in 1..<points.count {
            let distM = haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
            cumulativeDistanceM += distM

            if cumulativeDistanceM >= Double(nextKm) * 1000 {
                markers.append((km: nextKm, coordinate: (points[i].latitude, points[i].longitude)))
                nextKm += 1
            }
        }

        return markers
    }

    // MARK: - Segment Details

    static func buildSegmentDetails(
        from points: [TrackPoint],
        splits: [Split],
        maxHeartRate: Int?
    ) -> [SegmentDetail] {
        guard points.count >= 2 else { return [] }

        var details: [SegmentDetail] = []
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
                let midIndex = segmentPoints.count / 2
                let midPoint = segmentPoints[midIndex]

                let duration = points[i].timestamp.timeIntervalSince(points[segmentStartIndex].timestamp)
                let pace = duration > 0 ? duration : 0
                let elevChange = points[i].altitudeM - points[segmentStartIndex].altitudeM

                let heartRates = segmentPoints.compactMap(\.heartRate)
                let avgHR: Int? = heartRates.isEmpty ? nil : heartRates.reduce(0, +) / heartRates.count
                let zone: Int? = if let hr = avgHR, let maxHR = maxHeartRate, maxHR > 0 {
                    heartRateZone(heartRate: hr, maxHeartRate: maxHR)
                } else {
                    nil
                }

                details.append(SegmentDetail(
                    id: currentKm,
                    kilometerNumber: currentKm,
                    paceSecondsPerKm: pace,
                    elevationChangeM: elevChange,
                    averageHeartRate: avgHR,
                    zone: zone,
                    coordinate: (midPoint.latitude, midPoint.longitude)
                ))

                segmentStartIndex = i
                currentKm += 1
            }
        }

        return details
    }
}
