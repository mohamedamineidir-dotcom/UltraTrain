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
    func ownerApplyEdit(_ edit: OwnerSessionEdit, sessionId: UUID) async {
        guard var currentPlan = plan, let athlete else { return }
        guard let weekIndex = currentPlan.weeks.firstIndex(where: { week in
            week.sessions.contains { $0.id == sessionId }
        }) else { return }
        guard let sessionIndex = currentPlan.weeks[weekIndex].sessions.firstIndex(where: { $0.id == sessionId }) else { return }

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

        if let updatedWorkout = result.updatedWorkout,
           let workoutIndex = currentPlan.workouts.firstIndex(where: { $0.id == updatedWorkout.id }) {
            currentPlan.workouts[workoutIndex] = updatedWorkout
        }

        plan = currentPlan

        do {
            try await planRepository.updatePlan(currentPlan)
        } catch {
            Logger.training.error("Owner edit failed to persist: \(error)")
        }
    }
}
#endif
