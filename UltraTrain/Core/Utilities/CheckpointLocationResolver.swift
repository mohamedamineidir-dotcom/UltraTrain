import CoreLocation
import Foundation

enum CheckpointLocationResolver {

    static func resolveLocations(
        checkpoints: [Checkpoint],
        along trackPoints: [TrackPoint]
    ) -> [(checkpoint: Checkpoint, coordinate: CLLocationCoordinate2D)] {
        guard !checkpoints.isEmpty, trackPoints.count >= 2 else { return [] }

        let sorted = checkpoints.sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }
        var results: [(Checkpoint, CLLocationCoordinate2D)] = []

        for checkpoint in sorted {
            let targetM = checkpoint.distanceFromStartKm * 1000
            var resolved = false

            var runningDistance: Double = 0
            for i in 1..<trackPoints.count {
                let prev = trackPoints[i - 1]
                let curr = trackPoints[i]
                let segmentM = RunStatisticsCalculator.haversineDistance(
                    lat1: prev.latitude, lon1: prev.longitude,
                    lat2: curr.latitude, lon2: curr.longitude
                )
                runningDistance += segmentM

                if runningDistance >= targetM {
                    let overshoot = runningDistance - targetM
                    let fraction = segmentM > 0 ? (segmentM - overshoot) / segmentM : 0
                    let lat = prev.latitude + (curr.latitude - prev.latitude) * fraction
                    let lon = prev.longitude + (curr.longitude - prev.longitude) * fraction
                    results.append((checkpoint, CLLocationCoordinate2D(latitude: lat, longitude: lon)))
                    resolved = true
                    break
                }
            }

            if !resolved, let last = trackPoints.last {
                results.append((checkpoint, CLLocationCoordinate2D(
                    latitude: last.latitude,
                    longitude: last.longitude
                )))
            }
        }

        return results
    }
}
