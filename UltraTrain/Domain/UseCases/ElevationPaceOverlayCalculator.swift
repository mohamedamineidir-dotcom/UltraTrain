import Foundation

enum ElevationPaceOverlayCalculator {

    struct OverlayDataPoint: Identifiable, Equatable, Sendable {
        let id = UUID()
        var distanceKm: Double
        var altitudeM: Double
        var normalizedAltitude: Double
    }

    struct PaceOverlayPoint: Identifiable, Equatable, Sendable {
        let id = UUID()
        var distanceKm: Double
        var paceSecondsPerKm: Double
        var normalizedPace: Double
        var paceCategory: PaceCategory
    }

    enum PaceCategory: Sendable {
        case faster
        case average
        case slower
    }

    // MARK: - Completed Run Overlay

    static func buildOverlay(
        elevationProfile: [ElevationProfilePoint],
        splits: [Split]
    ) -> (elevation: [OverlayDataPoint], pace: [PaceOverlayPoint]) {
        let elevationPoints = normalizeElevation(elevationProfile)
        let pacePoints = normalizePace(splits)
        return (elevationPoints, pacePoints)
    }

    // MARK: - Race Course Overlay

    static func buildRaceCourseOverlay(
        checkpoints: [Checkpoint],
        checkpointSplits: [CheckpointSplit]
    ) -> (elevation: [OverlayDataPoint], pace: [PaceOverlayPoint]) {
        let profilePoints = RaceCourseProfileCalculator.elevationProfile(from: checkpoints)
        let elevationPoints = normalizeElevation(profilePoints)

        let segPaces = segmentPaces(from: checkpointSplits)
        guard !segPaces.isEmpty else { return (elevationPoints, []) }

        let paces = segPaces.map(\.paceSecondsPerKm)
        let minPace = paces.min()!
        let maxPace = paces.max()!
        let avgPace = paces.reduce(0, +) / Double(paces.count)
        let range = maxPace - minPace

        let pacePoints = segPaces.map { seg in
            let normalized = range > 0 ? 1.0 - (seg.paceSecondsPerKm - minPace) / range : 0.5
            let category = classify(pace: seg.paceSecondsPerKm, average: avgPace)
            return PaceOverlayPoint(
                distanceKm: seg.distanceKm,
                paceSecondsPerKm: seg.paceSecondsPerKm,
                normalizedPace: normalized,
                paceCategory: category
            )
        }

        return (elevationPoints, pacePoints)
    }

    static func segmentPaces(
        from splits: [CheckpointSplit]
    ) -> [(distanceKm: Double, paceSecondsPerKm: Double)] {
        splits.compactMap { split in
            guard split.segmentDistanceKm > 0 else { return nil }
            let pace = split.expectedTime / split.segmentDistanceKm
            let midpoint = split.distanceFromStartKm - split.segmentDistanceKm / 2
            return (distanceKm: midpoint, paceSecondsPerKm: pace)
        }
    }

    // MARK: - Private

    private static func normalizeElevation(
        _ profile: [ElevationProfilePoint]
    ) -> [OverlayDataPoint] {
        guard !profile.isEmpty else { return [] }
        let altitudes = profile.map(\.altitudeM)
        let minAlt = altitudes.min()!
        let maxAlt = altitudes.max()!
        let range = maxAlt - minAlt

        return profile.map { point in
            let normalized = range > 0 ? (point.altitudeM - minAlt) / range : 0.5
            return OverlayDataPoint(
                distanceKm: point.distanceKm,
                altitudeM: point.altitudeM,
                normalizedAltitude: normalized
            )
        }
    }

    private static func normalizePace(
        _ splits: [Split]
    ) -> [PaceOverlayPoint] {
        guard !splits.isEmpty else { return [] }
        let paces = splits.map(\.duration)
        let minPace = paces.min()!
        let maxPace = paces.max()!
        let avgPace = paces.reduce(0, +) / Double(paces.count)
        let range = maxPace - minPace

        return splits.map { split in
            let normalized = range > 0
                ? 1.0 - (split.duration - minPace) / range
                : 0.5
            let category = classify(pace: split.duration, average: avgPace)
            return PaceOverlayPoint(
                distanceKm: Double(split.kilometerNumber) - 0.5,
                paceSecondsPerKm: split.duration,
                normalizedPace: normalized,
                paceCategory: category
            )
        }
    }

    private static func classify(pace: Double, average: Double) -> PaceCategory {
        if pace < average * 0.95 { return .faster }
        if pace > average * 1.05 { return .slower }
        return .average
    }
}
