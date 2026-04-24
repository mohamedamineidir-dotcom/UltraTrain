import Foundation

/// Projects injury-risk signals (ACWR spike, monotony) for the NEXT 7
/// days of the plan, not retrospectively. Complements the historical
/// `TrainingLoadCalculator` which looks at completed runs only — this
/// lets the plan view warn the athlete BEFORE they execute a week
/// that's going to push ACWR past 1.5 or monotony past 2.0.
///
/// Research basis:
///   • Gabbett 2016 "The training-injury prevention paradox" — ACWR
///     >1.5 associated with 2-4× injury risk in team sports; applies
///     in endurance training literature too.
///   • Foster 1998 — training monotony (mean / std. dev of daily
///     load over 7 days). >2.0 correlates with overtraining +
///     illness markers.
///
/// Strategy:
///   • Chronic load (4-week trailing average) computed from actual
///     session loads when the session is completed and has actual
///     metrics; otherwise falls back to the session's planned load.
///   • Acute projection = planned load of the 7 days immediately
///     following `asOf`.
///   • Monotony projection computed from the daily load distribution
///     of those 7 planned days.
enum PlanInjuryRiskProjector {

    struct Projection: Equatable, Sendable {
        let projectedACWR: Double
        let projectedMonotony: Double
        let weeklyChronicLoad: Double     // 4-week trailing avg
        let weeklyAcuteLoad: Double       // next 7 days planned
        let flags: [Flag]
    }

    enum Flag: String, Equatable, Sendable {
        /// Planned next-7-day load pushes ACWR above 1.5 — elevated
        /// injury risk. Most actionable warning.
        case acwrSpike
        /// Planned week drops ACWR below 0.8 — a cutback week can be
        /// fine, but a sustained drop is detraining. Surfaced with a
        /// gentler tone.
        case acwrDetraining
        /// Monotony > 2.0 on the planned week — not enough variation
        /// between hard and easy days. Research links this to
        /// overreaching and illness.
        case highMonotony
    }

    // MARK: - Thresholds

    /// Gabbett's commonly-quoted upper safe ACWR. Above this = sharp
    /// rise in injury risk in the literature.
    private static let acwrSpikeThreshold: Double = 1.5
    private static let acwrDetrainingThreshold: Double = 0.8
    /// Foster's commonly-cited threshold for "too monotonous".
    private static let monotonyThreshold: Double = 2.0

    // MARK: - Public

    /// Returns a projection for the 7 days starting at `asOf`. When the
    /// plan has no upcoming sessions or insufficient history, returns
    /// nil — the UI treats that as "nothing to warn about".
    static func project(
        plan: TrainingPlan,
        asOf date: Date = .now
    ) -> Projection? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        // Acute window: next 7 days (inclusive of today).
        let acuteEnd = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let acuteSessions = plan.weeks.flatMap(\.sessions).filter {
            let s = calendar.startOfDay(for: $0.date)
            return s >= today && s < acuteEnd && !$0.isSkipped
        }
        guard !acuteSessions.isEmpty else { return nil }
        let acuteLoad = acuteSessions.reduce(0.0) { $0 + plannedLoad($1) }

        // Chronic window: trailing 28 days BEFORE today. Prefer actual
        // metrics from completed sessions, fall back to planned for
        // sessions that are completed-without-stats.
        let chronicStart = calendar.date(byAdding: .day, value: -28, to: today) ?? today
        let chronicSessions = plan.weeks.flatMap(\.sessions).filter {
            let s = calendar.startOfDay(for: $0.date)
            return s >= chronicStart && s < today
        }
        // Need at least ~2 weeks of history for ACWR to be meaningful.
        guard chronicSessions.count >= 6 else { return nil }
        let chronicTotal = chronicSessions.reduce(0.0) { $0 + actualOrPlannedLoad($1) }
        let chronicWeekly = chronicTotal / 4.0  // 28 days → 4 weeks

        guard chronicWeekly > 0 else { return nil }
        let acwr = acuteLoad / chronicWeekly

        // Monotony: daily load distribution across the 7 acute days.
        var dailyLoads = Array(repeating: 0.0, count: 7)
        for session in acuteSessions {
            let daysFromToday = calendar.dateComponents(
                [.day], from: today, to: calendar.startOfDay(for: session.date)
            ).day ?? 0
            if daysFromToday >= 0 && daysFromToday < 7 {
                dailyLoads[daysFromToday] += plannedLoad(session)
            }
        }
        let monotony = fosterMonotony(dailyLoads: dailyLoads)

        var flags: [Flag] = []
        if acwr > acwrSpikeThreshold {
            flags.append(.acwrSpike)
        } else if acwr < acwrDetrainingThreshold {
            flags.append(.acwrDetraining)
        }
        if monotony > monotonyThreshold {
            flags.append(.highMonotony)
        }

        return Projection(
            projectedACWR: acwr,
            projectedMonotony: monotony,
            weeklyChronicLoad: chronicWeekly,
            weeklyAcuteLoad: acuteLoad,
            flags: flags
        )
    }

    // MARK: - Load helpers

    /// Runs/hikes: distance + elevation/100 (matches existing
    /// TrainingLoadCalculator.effortLoad). Strength / rest contribute
    /// ~0 to loading risk — planned as nil-distance, nil-elevation
    /// sessions are covered.
    private static func plannedLoad(_ session: TrainingSession) -> Double {
        guard session.type != .rest else { return 0 }
        let km = session.plannedDistanceKm
        let elev = session.plannedElevationGainM
        if km > 0 || elev > 0 {
            return km + (elev / 100.0)
        }
        // Duration fallback for sessions without distance/elevation
        // targets (e.g. time-based intervals). ~5.5 min/km proxy →
        // converts seconds to km-equivalent.
        return session.plannedDuration > 0 ? session.plannedDuration / 330.0 : 0
    }

    private static func actualOrPlannedLoad(_ session: TrainingSession) -> Double {
        guard !session.isSkipped else { return 0 }
        if let km = session.actualDistanceKm, km > 0 {
            return km + ((session.actualElevationGainM ?? 0) / 100.0)
        }
        if session.isCompleted {
            return plannedLoad(session)
        }
        // Upcoming-but-not-yet-today shouldn't reach here given the
        // caller filters to strictly-past sessions, but guard anyway.
        return 0
    }

    private static func fosterMonotony(dailyLoads: [Double]) -> Double {
        let mean = dailyLoads.reduce(0.0, +) / Double(dailyLoads.count)
        guard mean > 0 else { return 0 }
        let variance = dailyLoads.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) } / Double(dailyLoads.count)
        let stddev = variance.squareRoot()
        // All-identical days (e.g. a streak with the same load every
        // day) produces zero variance and mathematical infinity.
        // Cap at 10 so downstream comparisons don't explode.
        guard stddev > 0 else { return 10.0 }
        return min(mean / stddev, 10.0)
    }
}
