import Foundation

/// Returns the athlete's target pace (sec/km) for a road intervals or tempo
/// session — the number the athlete should compare actual per-rep paces to
/// when they capture feedback.
///
/// Mirrors `RoadCoachAdviceGenerator.intervalAdvice` and `tempoAdvice` pace
/// selection so the feedback sheet shows the same pace the athlete read on
/// the session detail. Keeping this in one place means if we change how a
/// pace is derived for an intervals-in-peak session, coach advice and
/// feedback capture stay in sync automatically.
enum RoadSessionTargetPace {

    /// Returns the target pace in seconds/km, or nil when the session has no
    /// pace prescription (non-road, or non-intervals/non-tempo types).
    ///
    /// Threads the athlete's declared goal-time through so the computed
    /// profile stays data-derived for athletes who have set a goal but no
    /// PRs / VMA. Without this, the IR-1 feedback sheet would silently
    /// never appear for those athletes.
    static func target(
        for session: TrainingSession,
        phase: TrainingPhase,
        athlete: Athlete,
        race: Race
    ) -> Double? {
        guard session.type == .intervals || session.type == .tempo else { return nil }

        let goalTime: TimeInterval?
        switch race.goalType {
        case .targetTime(let time):
            goalTime = time
        case .targetRanking:
            goalTime = race.estimatedDuration(experience: athlete.experienceLevel) * 0.93
        case .finish:
            goalTime = nil
        }

        let profile = RoadPaceCalculator.paceProfile(
            goalTime: goalTime,
            raceDistanceKm: race.distanceKm,
            personalBests: athlete.personalBests,
            vmaKmh: athlete.vmaKmh,
            experience: athlete.experienceLevel
        )

        // Pace values only carry meaning when we have real data to anchor
        // them. If the profile fell through to tier defaults, surface nil —
        // the UI reads this as "show effort labels, skip per-rep pace entry."
        guard profile.isDataDerived else { return nil }

        switch session.type {
        case .intervals:
            switch phase {
            case .base, .build:
                return profile.intervalPacePerKm
            case .peak, .taper, .race:
                return profile.racePacePerKm
            case .recovery:
                return profile.intervalPacePerKm
            }
        case .tempo:
            switch phase {
            case .base, .build:
                return profile.thresholdPacePerKm
            case .peak, .taper, .race:
                return profile.racePacePerKm
            case .recovery:
                return profile.thresholdPacePerKm
            }
        default:
            return nil
        }
    }
}
