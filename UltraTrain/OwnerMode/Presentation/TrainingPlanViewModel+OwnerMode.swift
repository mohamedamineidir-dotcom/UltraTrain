#if OWNER_MODE
import Foundation
import os

@MainActor
extension TrainingPlanViewModel {

    /// Applies a free-form owner edit to one session, recomputes its
    /// week's chart-facing aggregates and coach advice, updates the
    /// in-memory plan (auto-propagating to any view observing
    /// `viewModel.plan`, including the week's volume charts), and
    /// persists the whole plan so the edit survives a relaunch.
    ///
    /// Drives `isApplyingOwnerEdit` (shown as a full-screen purple
    /// loading overlay by `TrainingPlanView`) for a minimum visible
    /// duration so a fast, purely-local edit still reads as a
    /// deliberate "applying your changes" step rather than a flicker.
    func ownerApplyEdit(_ edit: OwnerSessionEdit, sessionId: UUID) async {
        guard !isApplyingOwnerEdit else { return }
        isApplyingOwnerEdit = true
        let start = ContinuousClock.now

        guard var currentPlan = plan, let athlete else {
            isApplyingOwnerEdit = false
            return
        }
        guard let weekIndex = currentPlan.weeks.firstIndex(where: { week in
            week.sessions.contains { $0.id == sessionId }
        }), let sessionIndex = currentPlan.weeks[weekIndex].sessions.firstIndex(where: { $0.id == sessionId }) else {
            isApplyingOwnerEdit = false
            return
        }

        let session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        let week = currentPlan.weeks[weekIndex]
        let originalWorkoutId = session.intervalWorkoutId
        let workout = originalWorkoutId.flatMap { id in
            currentPlan.workouts.first { $0.id == id }
        }

        let result = OwnerSessionEditor.apply(
            edit,
            to: session,
            week: week,
            workout: workout,
            athlete: athlete,
            targetRace: targetRace
        )

        currentPlan.weeks[weekIndex].sessions[sessionIndex] = result.session
        currentPlan.weeks[weekIndex] = OwnerWeekAggregateRecalculator.recalculate(currentPlan.weeks[weekIndex])

        // Always reconcile against the session's ORIGINAL workout id, not
        // just whatever `result.removedWorkoutId` reports — if that id
        // didn't resolve to an actual entry in `currentPlan.workouts`
        // (a stale/mismatched reference), `workout` above came back nil,
        // a brand-new workout got built, and the old id would otherwise
        // never be cleaned up, leaving its phases as a "ghost" entry
        // that's still technically present in `plan.workouts`.
        let newWorkoutId = result.session.intervalWorkoutId
        if let originalWorkoutId, originalWorkoutId != newWorkoutId {
            currentPlan.workouts.removeAll { $0.id == originalWorkoutId }
        }
        if let removedId = result.removedWorkoutId {
            currentPlan.workouts.removeAll { $0.id == removedId }
        }
        if let updatedWorkout = result.updatedWorkout {
            if let workoutIndex = currentPlan.workouts.firstIndex(where: { $0.id == updatedWorkout.id }) {
                currentPlan.workouts[workoutIndex] = updatedWorkout
            } else {
                currentPlan.workouts.append(updatedWorkout)
            }
        }

        // Defense in depth: whatever the root cause, never let two
        // workouts with the same id reach persistence — keep the last
        // (most recently written) one for each id.
        var seenWorkoutIds = Set<UUID>()
        currentPlan.workouts = Array(currentPlan.workouts.reversed().filter { seenWorkoutIds.insert($0.id).inserted }.reversed())

        // Protects this session from the regular app's silent "urgent"
        // auto-adjustment system (see OwnerProtectedSessionStore) — it
        // has no idea this day was deliberately retyped and can
        // otherwise pick it as a target the next time ANY session is
        // toggled/completed/skipped anywhere in the plan.
        OwnerProtectedSessionStore.markProtected(sessionId)

        plan = currentPlan

        do {
            try await planRepository.updatePlan(currentPlan)
        } catch {
            Logger.training.error("Owner edit failed to persist: \(error)")
        }

        let elapsed = ContinuousClock.now - start
        let minimumDuration = Duration.seconds(2.2)
        if elapsed < minimumDuration {
            try? await Task.sleep(for: minimumDuration - elapsed)
        }
        isApplyingOwnerEdit = false
    }

    /// Adds a brand-new session to a week — used for a second training
    /// on a day that already has one. Finds the target week by date
    /// range rather than taking a week index, since the creating sheet
    /// only knows the week's start/end dates.
    func ownerCreateSession(_ newSession: TrainingSession, workout: IntervalWorkout?) async {
        guard !isApplyingOwnerEdit else { return }
        isApplyingOwnerEdit = true
        let start = ContinuousClock.now

        guard var currentPlan = plan, let athlete else {
            isApplyingOwnerEdit = false
            return
        }
        guard let weekIndex = currentPlan.weeks.firstIndex(where: { $0.contains(date: newSession.date) }) else {
            isApplyingOwnerEdit = false
            return
        }

        var session = newSession
        let week = currentPlan.weeks[weekIndex]
        session.coachAdvice = OwnerAdviceRegenerator.advice(
            for: session,
            week: week,
            athlete: athlete,
            targetRace: targetRace
        )

        currentPlan.weeks[weekIndex].sessions.append(session)
        currentPlan.weeks[weekIndex].sessions.sort { $0.date < $1.date }
        currentPlan.weeks[weekIndex] = OwnerWeekAggregateRecalculator.recalculate(currentPlan.weeks[weekIndex])

        if let workout {
            currentPlan.workouts.append(workout)
        }

        OwnerProtectedSessionStore.markProtected(session.id)

        plan = currentPlan

        do {
            try await planRepository.updatePlan(currentPlan)
        } catch {
            Logger.training.error("Owner create session failed to persist: \(error)")
        }

        let elapsed = ContinuousClock.now - start
        let minimumDuration = Duration.seconds(2.2)
        if elapsed < minimumDuration {
            try? await Task.sleep(for: minimumDuration - elapsed)
        }
        isApplyingOwnerEdit = false
    }
}
#endif
