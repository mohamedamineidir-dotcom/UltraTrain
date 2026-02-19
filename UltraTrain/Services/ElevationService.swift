import Foundation

enum ElevationService {

    static func smoothElevationProfile(
        _ profile: [ElevationProfilePoint],
        windowSize: Int = 5
    ) -> [ElevationProfilePoint] {
        guard profile.count >= windowSize, windowSize >= 3 else { return profile }

        let halfWindow = windowSize / 2
        return profile.enumerated().map { index, point in
            let start = max(0, index - halfWindow)
            let end = min(profile.count - 1, index + halfWindow)
            let window = profile[start...end]
            let avgAltitude = window.map(\.altitudeM).reduce(0, +) / Double(window.count)
            return ElevationProfilePoint(
                distanceKm: point.distanceKm,
                altitudeM: avgAltitude
            )
        }
    }

    static func categorizeSegments(
        _ segments: [ElevationSegment]
    ) -> [(segment: ElevationSegment, category: GradientCategory)] {
        segments.map { segment in
            (segment, GradientCategory.from(gradient: segment.averageGradient))
        }
    }
}
