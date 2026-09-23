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
        let workout = session.intervalWorkoutId.flatMap { id in
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
}
#endif
