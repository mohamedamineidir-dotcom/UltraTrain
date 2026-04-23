import Foundation
import os

// MARK: - Interval Performance Feedback
//
// IR-1: capture per-rep paces + RPE + completion for road intervals / tempo
// sessions. IR-2 (future) consumes the persisted feedback to refine future
// target paces.

extension TrainingPlanViewModel {

    /// Whether this plan is for a road race — gates whether the per-rep
    /// feedback sheet is offered at all. Derived from the A-race distance.
    /// Trail / ultra intervals use a different feedback model (RPE + HR +
    /// VMP rather than pace) and are handled in a separate feature.
    var isRoadPlan: Bool {
        guard let race = targetRace else { return false }
        return race.distanceKm <= 45 && race.elevationGainM < 1000
    }

    /// Returns true when a given road session qualifies for per-rep feedback
    /// capture: intervals or tempo, structured workout attached, not a rest
    /// day. The sheet is only offered when this returns true.
    func sessionQualifiesForIntervalFeedback(
        weekIndex: Int,
        sessionIndex: Int
    ) -> Bool {
        guard isRoadPlan,
              let plan,
              weekIndex < plan.weeks.count,
              sessionIndex < plan.weeks[weekIndex].sessions.count else { return false }
        let session = plan.weeks[weekIndex].sessions[sessionIndex]
        guard session.type == .intervals || session.type == .tempo else { return false }
        guard session.intervalWorkoutId != nil else { return false }
        return true
    }

    /// Target pace in sec/km for a given road session, using the athlete's
    /// current fitness. Returns nil when the pace profile isn't data-derived
    /// (athlete has no PRs / VMA / goal) — in that case the UI shouldn't
    /// fabricate a per-km target.
    func targetPacePerKm(weekIndex: Int, sessionIndex: Int) -> Double? {
        guard let plan, let athlete, let race = targetRace,
              weekIndex < plan.weeks.count,
              sessionIndex < plan.weeks[weekIndex].sessions.count else { return nil }
        let session = plan.weeks[weekIndex].sessions[sessionIndex]
        let phase = plan.weeks[weekIndex].phase
        return RoadSessionTargetPace.target(
            for: session,
            phase: phase,
            athlete: athlete,
            raceDistanceKm: race.distanceKm
        )
    }

    /// Total prescribed work reps across a session's attached workout.
    /// Returns 0 when no structured workout exists.
    func prescribedRepCount(weekIndex: Int, sessionIndex: Int) -> Int {
        guard let plan,
              weekIndex < plan.weeks.count,
              sessionIndex < plan.weeks[weekIndex].sessions.count else { return 0 }
        let session = plan.weeks[weekIndex].sessions[sessionIndex]
        guard let workoutId = session.intervalWorkoutId,
              let workout = plan.workouts.first(where: { $0.id == workoutId }) else { return 0 }
        return workout.intervalCount
    }

    /// Loads an existing feedback entry for a session (so re-opening the
    /// sheet seeds prior answers). Returns nil when none exists or the repo
    /// isn't wired.
    func loadIntervalFeedback(sessionId: UUID) async -> IntervalPerformanceFeedback? {
        guard let repo = intervalPerformanceRepository else { return nil }
        do {
            return try await repo.get(for: sessionId)
        } catch {
            Logger.training.error("Failed to load interval feedback: \(error)")
            return nil
        }
    }

    /// Persists per-rep feedback. The athlete's mark-completed flow already
    /// ran — this only adds the feedback record.
    func saveIntervalFeedback(_ feedback: IntervalPerformanceFeedback) async {
        guard let repo = intervalPerformanceRepository else { return }
        do {
            try await repo.save(feedback)
            Logger.training.info("Saved interval feedback for session \(feedback.sessionId)")
        } catch {
            Logger.training.error("Failed to save interval feedback: \(error)")
            self.error = error.localizedDescription
        }
    }
}
