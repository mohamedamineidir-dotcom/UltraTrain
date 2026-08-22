import Foundation

@Observable
@MainActor
final class InteractiveCourseProfileViewModel {
    let gradientSegments: [GradientSegment]
    let elevationProfile: [ElevationProfilePoint]
    let checkpoints: [Checkpoint]
    let totalDistanceKm: Double

    /// Optimistic/expected/conservative finish times, when the caller has
    /// a finish-time estimate for this course — nil for contexts with no
    /// prediction (e.g. browsing a saved training route). Presence of
    /// this drives whether scrubbing shows a projected split time
    /// alongside altitude/gradient.
    private let scenarioTimes: (optimistic: TimeInterval, expected: TimeInterval, conservative: TimeInterval)?
    private let effortProfile: [EffortProfilePoint]
    private let totalEffortKm: Double

    private(set) var selectedDistance: Double?
    private(set) var selectedAltitude: Double?
    private(set) var selectedSegment: GradientSegment?
    private(set) var selectedSplitTimes: (optimistic: TimeInterval, expected: TimeInterval, conservative: TimeInterval)?

    init(
        courseRoute: [TrackPoint],
        checkpoints: [Checkpoint],
        scenarioTimes: (optimistic: TimeInterval, expected: TimeInterval, conservative: TimeInterval)? = nil
    ) {
        self.checkpoints = checkpoints
        self.gradientSegments = CourseGradientCalculator.buildGradientProfile(from: courseRoute)
        self.elevationProfile = ElevationCalculator.elevationProfile(from: courseRoute)
        self.totalDistanceKm = elevationProfile.last?.distanceKm ?? 0
        self.scenarioTimes = scenarioTimes
        self.effortProfile = CourseGradientCalculator.buildEffortProfile(from: gradientSegments)
        self.totalEffortKm = effortProfile.last?.cumulativeEffortKm ?? 0
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
        selectedSplitTimes = projectedSplitTimes(at: clamped)
    }

    func clearSelection() {
        selectedDistance = nil
        selectedSegment = nil
        selectedAltitude = nil
        selectedSplitTimes = nil
    }

    private func projectedSplitTimes(
        at distanceKm: Double
    ) -> (optimistic: TimeInterval, expected: TimeInterval, conservative: TimeInterval)? {
        guard let scenarioTimes, totalEffortKm > 0,
              let effortAtPoint = CourseGradientCalculator.interpolatedCumulativeEffort(
                at: distanceKm, in: effortProfile
              ) else { return nil }
        let fraction = min(max(effortAtPoint / totalEffortKm, 0), 1)
        return (
            optimistic: scenarioTimes.optimistic * fraction,
            expected: scenarioTimes.expected * fraction,
            conservative: scenarioTimes.conservative * fraction
        )
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

    /// Whether this instance was given a finish-time estimate at all —
    /// lets the view decide whether to reserve space for split-time UI.
    var hasScenarioTimes: Bool { scenarioTimes != nil }

    var selectedOptimisticSplitText: String? {
        selectedSplitTimes.map { Self.formatSplit($0.optimistic) }
    }

    var selectedExpectedSplitText: String? {
        selectedSplitTimes.map { Self.formatSplit($0.expected) }
    }

    var selectedConservativeSplitText: String? {
        selectedSplitTimes.map { Self.formatSplit($0.conservative) }
    }

    private static func formatSplit(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return String(format: "%dh%02d", h, m)
    }
}
