import Foundation
import os

// MARK: - Session Actions

extension TrainingPlanViewModel {

    // MARK: - Toggle Session

    func toggleSessionCompletion(weekIndex: Int, sessionIndex: Int) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        var session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        session.isCompleted.toggle()
        currentPlan.weeks[weekIndex].sessions[sessionIndex] = session

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
            await updateWidgets()
            checkForAdjustments()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to update session: \(error)")
        }
    }

    // MARK: - Skip

    func skipSession(weekIndex: Int, sessionIndex: Int) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        var session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        session.isSkipped = true
        currentPlan.weeks[weekIndex].sessions[sessionIndex] = session

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
            checkForAdjustments()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to skip session: \(error)")
        }
    }

    func unskipSession(weekIndex: Int, sessionIndex: Int) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        var session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        session.isSkipped = false
        currentPlan.weeks[weekIndex].sessions[sessionIndex] = session

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
            checkForAdjustments()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to unskip session: \(error)")
        }
    }

    // MARK: - Reschedule

    func rescheduleSession(weekIndex: Int, sessionIndex: Int, to newDate: Date) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        var session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        session.date = newDate
        currentPlan.weeks[weekIndex].sessions[sessionIndex] = session
        currentPlan.weeks[weekIndex].sessions.sort { $0.date < $1.date }

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to reschedule session: \(error)")
        }
    }

    // MARK: - Swap

    func swapSessions(
        weekIndexA: Int, sessionIndexA: Int,
        weekIndexB: Int, sessionIndexB: Int
    ) async {
        guard var currentPlan = plan else { return }
        guard weekIndexA < currentPlan.weeks.count,
              sessionIndexA < currentPlan.weeks[weekIndexA].sessions.count,
              weekIndexB < currentPlan.weeks.count,
              sessionIndexB < currentPlan.weeks[weekIndexB].sessions.count else { return }

        var sessionA = currentPlan.weeks[weekIndexA].sessions[sessionIndexA]
        var sessionB = currentPlan.weeks[weekIndexB].sessions[sessionIndexB]

        let dateA = sessionA.date
        sessionA.date = sessionB.date
        sessionB.date = dateA

        currentPlan.weeks[weekIndexA].sessions[sessionIndexA] = sessionA
        currentPlan.weeks[weekIndexB].sessions[sessionIndexB] = sessionB
        currentPlan.weeks[weekIndexA].sessions.sort { $0.date < $1.date }
        if weekIndexA != weekIndexB {
            currentPlan.weeks[weekIndexB].sessions.sort { $0.date < $1.date }
        }

        do {
            try await planRepository.updateSession(sessionA)
            try await planRepository.updateSession(sessionB)
            plan = currentPlan
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to swap sessions: \(error)")
        }
    }
}
