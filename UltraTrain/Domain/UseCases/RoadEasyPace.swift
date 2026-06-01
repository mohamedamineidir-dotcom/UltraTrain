import Foundation

/// Easy / recovery training pace range (sec/km) for an athlete, derived
/// from the *same* road pace profile that powers coach advice and the
/// workout builder. The session-detail "Pace & HR Targets" card used to
/// recompute easy pace independently (threshold × 1.25–1.35), which drifted
/// a few seconds from the calibrated 5K-based easy range the coach card
/// shows. Sharing one source keeps the two cards identical.
enum RoadEasyPace {

    /// Returns the calibrated easy pace range, or nil when the athlete has
    /// no fitness signal (no PR, no measured VMA). In that case callers
    /// fall back to the generic estimate, matching the coach card which
    /// also stays silent on pace without data.
    static func range(for athlete: Athlete) -> ClosedRange<Double>? {
        let hasPR = athlete.personalBests.contains { $0.timeSeconds > 0 }
        let hasVMA = (athlete.vmaKmh ?? 0) > 0
        guard hasPR || hasVMA else { return nil }

        // Easy pace is anchored to 5K fitness alone, independent of the
        // race distance or goal, so a neutral race distance is fine here.
        let profile = RoadPaceCalculator.paceProfile(
            goalTime: nil,
            raceDistanceKm: 42.195,
            personalBests: athlete.personalBests,
            vmaKmh: athlete.vmaKmh,
            experience: athlete.experienceLevel
        )
        return profile.easyPacePerKm
    }
}
