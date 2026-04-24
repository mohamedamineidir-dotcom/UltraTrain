import Foundation

/// Detects sustained patterns of missed or under-executed training so
/// the plan view can warn the athlete before continuing to prescribe
/// work the recent data no longer supports.
///
/// Per-skip handling already happens in `SkipAdaptationCalculator` —
/// it reacts to individual skips with localised suggestions. This
/// detector fills the gap one level up: sustained patterns over 2-3
/// weeks that warrant a full plan rebalance rather than a session
/// tweak. Surfacing these early prevents the common failure mode
/// where an athlete misses a block of training but the plan keeps
/// prescribing pace targets derived from fitness the athlete never
/// built.
///
/// Pure domain — callers read the output and decide what to show.
enum MissedSessionPatternDetector {

    struct Pattern: Equatable, Sendable {
        let flags: [Flag]
        /// Count of skipped running sessions in the trailing window.
        let skipCountRecent: Int
        /// Days since the last completed session. 0 when there's a
        /// completion today; large numbers = inactivity.
        let daysSinceLastCompletion: Int
        /// Quality sessions (intervals, tempo, long run, B2B) in the
        /// window that were skipped OR completed at under the 70%
        /// actual/planned threshold.
        let qualityDriftCount: Int
    }

    enum Flag: String, Equatable, Sendable {
        /// Three or more skipped running sessions in the last 14 days.
        /// Most actionable — suggests a regeneration.
        case multiSessionSkip
        /// Two or more quality sessions skipped or under-executed.
        /// Quality work is what builds the specific adaptations the
        /// plan's later blocks assume; missing them breaks
        /// periodisation.
        case qualitySessionDrift
        /// Seven or more days with no completed training. Could be
        /// vacation, illness, or injury — either way the plan's
        /// chronic load no longer matches reality.
        case extendedInactivity
    }

    // MARK: - Thresholds

    private static let windowDays = 14
    private static let multiSkipThreshold = 3
    private static let qualityDriftThreshold = 2
    private static let inactivityDaysThreshold = 7
    /// Actual/planned ratio below which we count a completed session
    /// as "under-executed" for the quality-drift flag. 0.70 is
    /// intentionally forgiving — we're catching real drift, not
    /// penalising athletes who had a slightly short run.
    private static let underExecutedRatio: Double = 0.70

    // MARK: - Public

    /// Returns a detected pattern when at least one flag fires.
    /// Returns nil when everything looks normal (preferred over
    /// returning an empty flags array so banner code can
    /// `if let pattern` cleanly).
    static func detect(
        plan: TrainingPlan,
        asOf date: Date = .now
    ) -> Pattern? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        guard let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: today) else {
            return nil
        }

        let windowSessions = plan.weeks.flatMap(\.sessions).filter {
            let s = calendar.startOfDay(for: $0.date)
            return s >= windowStart && s <= today && $0.type != .rest
        }

        let skippedSessions = windowSessions.filter(\.isSkipped)
        let skipCount = skippedSessions.count

        // Quality sessions in the window that are skipped OR whose
        // actual distance falls below 70% of planned.
        let qualityTypes: Set<SessionType> = [.intervals, .tempo, .longRun, .backToBack]
        let qualityInWindow = windowSessions.filter { qualityTypes.contains($0.type) }
        let qualityDrift = qualityInWindow.filter { session in
            if session.isSkipped { return true }
            guard session.isCompleted else { return false }
            guard session.plannedDistanceKm > 0 else { return false }
            guard let actual = session.actualDistanceKm, actual >= 0 else { return false }
            return actual / session.plannedDistanceKm < underExecutedRatio
        }.count

        // Days since last completed session — use any completed
        // running session, regardless of being in the window.
        let allCompleted = plan.weeks.flatMap(\.sessions)
            .filter { $0.isCompleted && $0.type != .rest }
            .map { calendar.startOfDay(for: $0.date) }
        let lastCompletionDay = allCompleted.max()
        let daysSinceLast: Int
        if let lastCompletionDay {
            daysSinceLast = calendar.dateComponents([.day], from: lastCompletionDay, to: today).day ?? 0
        } else {
            // No completions at all — treat as "same as window" rather
            // than a 9999 day figure so a freshly-generated plan
            // doesn't trip the inactivity flag on day 0.
            daysSinceLast = 0
        }

        var flags: [Flag] = []
        if skipCount >= multiSkipThreshold {
            flags.append(.multiSessionSkip)
        }
        if qualityDrift >= qualityDriftThreshold {
            flags.append(.qualitySessionDrift)
        }
        if daysSinceLast >= inactivityDaysThreshold {
            flags.append(.extendedInactivity)
        }

        guard !flags.isEmpty else { return nil }
        return Pattern(
            flags: flags,
            skipCountRecent: skipCount,
            daysSinceLastCompletion: daysSinceLast,
            qualityDriftCount: qualityDrift
        )
    }
}
