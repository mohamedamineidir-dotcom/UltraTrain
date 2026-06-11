import Foundation

/// Reactive menstrual-cycle adaptation: triggered when the athlete
/// logs a skip with `.menstrualCycle` reason, surfaces a single
/// pattern-level recommendation when ≥2 such skips land inside a
/// 7-day window. No predictive logic, no cycle-phase calculator, no
/// anchor-date input, the engine only responds to what the athlete
/// chose to share via the skip reason.
///
/// This is intentionally minimal. UltraTrain does not ask cycle-anchor
/// dates, predict bleed days, or surface phase-specific cues. The
/// product call is that asking those questions in an app feels too
/// intrusive; the reactive flow gives athletes a way to communicate
/// when their cycle is affecting training without being interrogated
/// upfront.
enum MenstrualAdaptationCalculator {

    /// Detects ≥2 menstrual-cycle skips inside a 7-day window across
    /// the supplied weeks. When that fires, surfaces a single
    /// pattern-level recommendation that names the signal explicitly:
    /// the athlete is already dropping load via skips, the
    /// recommendation just makes the deload structural in framing
    /// (no auto plan mutation, the skips themselves are doing the
    /// work).
    static func analyzeMultiSkipPattern(
        weeks: [TrainingWeek],
        now: Date = .now,
        windowDays: Int = 7
    ) -> [PlanAdjustmentRecommendation] {
        guard let windowStart = Calendar.current.date(
            byAdding: .day, value: -windowDays, to: now
        ) else { return [] }

        let menstrualSkips = weeks.flatMap(\.sessions).filter { session in
            session.isSkipped
                && session.skipReason == .menstrualCycle
                && session.date >= windowStart
                && session.date <= now
        }

        guard menstrualSkips.count >= 2 else { return [] }

        return [PlanAdjustmentRecommendation(
            id: UUID(),
            type: .menstrualMultiSkipPattern,
            severity: .recommended,
            title: String(localized: "mac.title", defaultValue: "Cycle pattern this week, name it"),
            message: String(localized: "mac.msg", defaultValue: "You've logged \(menstrualSkips.count) cycle-related skips in the last week. Your body's already dialled the load, let this week be a soft deload (easy + recovery only, no key quality), then resume normal training next week. McNulty 2020: when symptoms drive availability, listen."),
            actionLabel: String(localized: "common.gotIt", defaultValue: "Got it"),
            affectedSessionIds: menstrualSkips.map(\.id)
        )]
    }
}
