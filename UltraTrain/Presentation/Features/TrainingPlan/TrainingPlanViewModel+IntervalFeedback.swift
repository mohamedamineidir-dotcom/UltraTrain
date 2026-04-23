import Foundation
import os

// MARK: - Interval Performance Feedback
//
// IR-1: capture per-rep paces + RPE + completion for road intervals / tempo
// sessions. IR-2 (future) consumes the persisted feedback to refine future
// target paces.

extension TrainingPlanViewModel {

    /// Whether this plan is for a road race — gates whether the per-rep
    /// feedback sheet is offered at all. Uses the A-race's raceType field
    /// (aligned with TrainingPlanView+Sections) so manual and automatic
    /// road detection agree. Trail / ultra intervals use a different
    /// feedback model (RPE + HR + VMP rather than pace).
    var isRoadPlan: Bool {
        targetRace?.raceType == .road
    }

    /// Returns true when a given session qualifies for per-rep feedback:
    /// intervals or tempo on a road plan. We deliberately do NOT require a
    /// linked IntervalWorkout — some road tempo sessions don't attach one
    /// (single-block tempos), but the athlete should still be able to
    /// reflect on RPE + completion + average pace. rep count falls back to
    /// 1 in those cases.
    func sessionQualifiesForIntervalFeedback(
        weekIndex: Int,
        sessionIndex: Int
    ) -> Bool {
        guard isRoadPlan,
              let plan,
              weekIndex < plan.weeks.count,
              sessionIndex < plan.weeks[weekIndex].sessions.count else { return false }
        let session = plan.weeks[weekIndex].sessions[sessionIndex]
        return session.type == .intervals || session.type == .tempo
    }

    /// Target pace in sec/km for a given road session. Feeds the athlete's
    /// declared goal-time (when present) into the calculator so the profile
    /// stays data-derived even for athletes without PRs/VMA. Returns nil
    /// only when the athlete truly has no signal at all.
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
            race: race
        )
    }

    /// Total prescribed work reps. Uses the attached IntervalWorkout when
    /// present, otherwise falls back to 1 so single-block tempo sessions
    /// still get a feedback sheet (the athlete logs their average pace
    /// for the one block).
    func prescribedRepCount(weekIndex: Int, sessionIndex: Int) -> Int {
        guard let plan,
              weekIndex < plan.weeks.count,
              sessionIndex < plan.weeks[weekIndex].sessions.count else { return 1 }
        let session = plan.weeks[weekIndex].sessions[sessionIndex]
        if let workoutId = session.intervalWorkoutId,
           let workout = plan.workouts.first(where: { $0.id == workoutId }) {
            return max(1, workout.intervalCount)
        }
        return 1
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

    /// Loads feedback from the last 21 days across both intervals and
    /// tempo, for IR-2 refinement. The refinement use case applies its
    /// own windowing, so returning a slightly wider set is safe.
    func loadRecentIntervalFeedback() async -> [IntervalPerformanceFeedback] {
        guard let repo = intervalPerformanceRepository else { return [] }
        let cutoff = Date().addingTimeInterval(-21 * 24 * 3600)
        do {
            async let intervals = repo.getRecent(since: cutoff, sessionType: .intervals)
            async let tempo = repo.getRecent(since: cutoff, sessionType: .tempo)
            return try await intervals + tempo
        } catch {
            Logger.training.error("Failed to load recent feedback for refinement: \(error)")
            return []
        }
    }
}
