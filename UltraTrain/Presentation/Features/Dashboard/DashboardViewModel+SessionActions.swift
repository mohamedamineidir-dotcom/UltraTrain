import Foundation
import os

// MARK: - Session Actions (for Next Session card)

extension DashboardViewModel {

    /// Locates `nextSession` inside the plan and returns its week / session
    /// indices. Needed because `planRepository.updateSession` persists a
    /// single session but we also want to mirror the change in the local
    /// `plan` cache so the dashboard refreshes immediately.
    private func findNextSessionIndices() -> (weekIndex: Int, sessionIndex: Int, session: TrainingSession)? {
        guard let plan, let session = nextSession else { return nil }
        for (weekIdx, week) in plan.weeks.enumerated() {
            if let sessionIdx = week.sessions.firstIndex(where: { $0.id == session.id }) {
                return (weekIdx, sessionIdx, session)
            }
        }
        return nil
    }

    /// Marks `nextSession` completed with optional manual stats, mirroring
    /// TrainingPlanViewModel.completeSessionManually. Invoked by the
    /// SessionValidationView presented from the Next Session card.
    func completeNextSessionManually(
        distanceKm: Double?,
        durationSeconds: TimeInterval?,
        elevationGainM: Double?,
        feeling: PerceivedFeeling?,
        exertion: Int?
    ) async {
        guard var currentPlan = plan,
              let indices = findNextSessionIndices() else { return }

        var session = indices.session
        session.isCompleted = true
        session.actualDistanceKm = distanceKm
        session.actualDurationSeconds = durationSeconds
        session.actualElevationGainM = elevationGainM
        session.perceivedFeeling = feeling
        session.perceivedExertion = exertion

        currentPlan.weeks[indices.weekIndex].sessions[indices.sessionIndex] = session

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
            Logger.training.info("Dashboard: session \(session.id) marked completed")
            // Completion shifts the tolerance range — refresh the forecast.
            await refreshFinishEstimate()
        } catch {
            fitnessError = error.localizedDescription
            Logger.training.error("Dashboard: failed to complete session: \(error)")
        }
    }

    /// Marks `nextSession` skipped with the given reason, mirroring
    /// TrainingPlanViewModel.skipSession. The skip reason flows into the
    /// plan-adjustment pipeline on the Training Plan tab.
    func skipNextSession(reason: SkipReason) async {
        guard var currentPlan = plan,
              let indices = findNextSessionIndices() else { return }

        var session = indices.session
        session.isSkipped = true
        session.skipReason = reason

        currentPlan.weeks[indices.weekIndex].sessions[indices.sessionIndex] = session

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
            Logger.training.info("Dashboard: session \(session.id) skipped, reason=\(reason.rawValue)")
            // Skipping widens the forecast range — refresh so the user sees it.
            await refreshFinishEstimate()
        } catch {
            fitnessError = error.localizedDescription
            Logger.training.error("Dashboard: failed to skip session: \(error)")
        }
    }

    /// Links a completed run to `nextSession`. Used when the validation sheet
    /// picks a recent CompletedRun via recentRunsProvider.
    func linkNextSessionToRun(runId: UUID) async {
        guard var currentPlan = plan,
              let indices = findNextSessionIndices() else { return }

        currentPlan.weeks[indices.weekIndex].sessions[indices.sessionIndex].linkedRunId = runId
        currentPlan.weeks[indices.weekIndex].sessions[indices.sessionIndex].isCompleted = true

        do {
            try await planRepository.savePlan(currentPlan)
            try await runRepository.updateLinkedSession(
                runId: runId,
                sessionId: currentPlan.weeks[indices.weekIndex].sessions[indices.sessionIndex].id
            )
            plan = currentPlan
            Logger.training.info("Dashboard: linked run \(runId) to next session")
        } catch {
            fitnessError = error.localizedDescription
            Logger.training.error("Dashboard: failed to link run: \(error)")
        }
    }

    /// Re-runs the finish-time estimator with the athlete's latest training
    /// data and persists the result. Called after validate/skip so the
    /// forecast range tightens/loosens based on updated completion history.
    func refreshFinishEstimate() async {
        guard !isRefreshingEstimate else { return }
        isRefreshingEstimate = true
        await loadFinishEstimate()
        isRefreshingEstimate = false
    }

    /// Recent unlinked runs near the next session's date (used by the
    /// validation sheet to offer quick-link options).
    func recentUnlinkedRuns(near date: Date, limit: Int = 10) async -> [CompletedRun] {
        do {
            let runs = try await runRepository.getRecentRuns(limit: limit * 2)
            let threeWeeks: TimeInterval = 21 * 24 * 3600
            return runs
                .filter { $0.linkedSessionId == nil && abs($0.date.timeIntervalSince(date)) <= threeWeeks }
                .prefix(limit)
                .map { $0 }
        } catch {
            Logger.training.error("Dashboard: failed to load recent runs: \(error)")
            return []
        }
    }
}
