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
    private let gainProfile: [CumulativeGainPoint]

    private(set) var selectedDistance: Double?
    private(set) var selectedAltitude: Double?
    private(set) var selectedCumulativeGain: Double?
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
        self.gainProfile = CourseGradientCalculator.buildCumulativeGainProfile(from: gradientSegments)
    }

    // MARK: - Selection

    func selectPoint(at distanceKm: Double) {
        let clamped = max(0, min(distanceKm, totalDistanceKm))
        selectedDistance = clamped
        // `< endDistanceKm` alone never matches exactly at the course's
        // final point (clamped == totalDistanceKm == the last segment's
        // endDistanceKm), leaving `selectedSegment` nil right at the
        // finish and dropping the "Terrain" readout there — falling back
        // to the last segment keeps every field populated at the edge.
        selectedSegment = gradientSegments.first {
            clamped >= $0.distanceKm && clamped < $0.endDistanceKm
        } ?? gradientSegments.last

        selectedAltitude = CourseGradientCalculator.interpolatedAltitude(
            at: clamped,
            in: gradientSegments
        )
        selectedCumulativeGain = CourseGradientCalculator.interpolatedCumulativeGain(
            at: clamped,
            in: gainProfile
        )
        selectedSplitTimes = projectedSplitTimes(at: clamped)
    }

    func clearSelection() {
        selectedDistance = nil
        selectedSegment = nil
        selectedAltitude = nil
        selectedCumulativeGain = nil
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

    /// Distance at which the course's highest point occurs — used to
    /// position the ambient glow behind the chart's summit.
    var peakDistanceKm: Double {
        elevationProfile.max(by: { $0.altitudeM < $1.altitudeM })?.distanceKm ?? 0
    }

    /// Y-axis domain for the altitude chart, derived from this course's
    /// own elevation range with proportional headroom — a 900m peak gets
    /// a ceiling a couple hundred meters above it, a 4000m peak gets
    /// proportionally more, instead of a fixed literal that's wrong for
    /// almost every course. Also sidesteps a Swift Charts quirk where
    /// leaving the Y domain fully automatic makes it visibly unstable
    /// (jumping to unrelated bounds) once the drag-selection RuleMark is
    /// added/removed.
    var altitudeDomain: ClosedRange<Double> {
        let minAlt = minAltitude
        let maxAlt = maxAltitude
        let span = max(maxAlt - minAlt, 50)
        let topPadding = max(250, maxAlt * 0.12)
        let bottomPadding = max(30, span * 0.06)
        let lower = minAlt - bottomPadding
        let upper = maxAlt + topPadding
        return lower < upper ? lower...upper : lower...(lower + 1)
    }

    /// X-axis domain for the distance chart — ends just past this
    /// course's actual total distance (2% padding) rather than an
    /// automatically-scaled range that can overshoot or destabilize
    /// during interaction, same rationale as `altitudeDomain`.
    var distanceDomain: ClosedRange<Double> {
        let endPadding = max(0.3, totalDistanceKm * 0.02)
        return 0...(totalDistanceKm + endPadding)
    }

    var selectedGradientText: String? {
        guard let segment = selectedSegment else { return nil }
        let sign = segment.gradientPercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", segment.gradientPercent))%"
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
