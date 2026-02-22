import Foundation

@Observable
@MainActor
final class InteractiveCourseProfileViewModel {
    let gradientSegments: [GradientSegment]
    let elevationProfile: [ElevationProfilePoint]
    let checkpoints: [Checkpoint]
    let totalDistanceKm: Double

    private(set) var selectedDistance: Double?
    private(set) var selectedAltitude: Double?
    private(set) var selectedSegment: GradientSegment?

    init(courseRoute: [TrackPoint], checkpoints: [Checkpoint]) {
        self.checkpoints = checkpoints
        self.gradientSegments = CourseGradientCalculator.buildGradientProfile(from: courseRoute)
        self.elevationProfile = ElevationCalculator.elevationProfile(from: courseRoute)
        self.totalDistanceKm = elevationProfile.last?.distanceKm ?? 0
    }

    // MARK: - Selection

    func selectPoint(at distanceKm: Double) {
        let clamped = max(0, min(distanceKm, totalDistanceKm))
        selectedDistance = clamped
        selectedSegment = gradientSegments.first {
            clamped >= $0.distanceKm && clamped < $0.endDistanceKm
        }
        selectedAltitude = CourseGradientCalculator.interpolatedAltitude(
            at: clamped,
            in: gradientSegments
        )
    }

    func clearSelection() {
        selectedDistance = nil
        selectedSegment = nil
        selectedAltitude = nil
    }

    // MARK: - Computed Helpers

    var minAltitude: Double {
        elevationProfile.map(\.altitudeM).min() ?? 0
    }

    var maxAltitude: Double {
        elevationProfile.map(\.altitudeM).max() ?? 0
    }

    var selectedGradientText: String? {
        guard let segment = selectedSegment else { return nil }
        let sign = segment.gradientPercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", segment.gradientPercent))%"
    }

    var selectedDistanceText: String? {
        guard let dist = selectedDistance else { return nil }
        return String(format: "%.2f km", dist)
    }

    var selectedAltitudeText: String? {
        guard let alt = selectedAltitude else { return nil }
        return String(format: "%.0f m", alt)
    }
}
