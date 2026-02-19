import Foundation

enum RaceCourseProfileCalculator {

    static func elevationProfile(from checkpoints: [Checkpoint]) -> [ElevationProfilePoint] {
        let sorted = checkpoints.sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }
        guard !sorted.isEmpty else { return [] }

        return sorted.map { cp in
            ElevationProfilePoint(
                distanceKm: cp.distanceFromStartKm,
                altitudeM: cp.elevationM
            )
        }
    }

    static func elevationChanges(from checkpoints: [Checkpoint]) -> (gainM: Double, lossM: Double) {
        let sorted = checkpoints.sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }
        guard sorted.count >= 2 else { return (0, 0) }

        var gain: Double = 0
        var loss: Double = 0
        for i in 1..<sorted.count {
            let diff = sorted[i].elevationM - sorted[i - 1].elevationM
            if diff > 0 {
                gain += diff
            } else {
                loss += abs(diff)
            }
        }
        return (gain, loss)
    }
}
