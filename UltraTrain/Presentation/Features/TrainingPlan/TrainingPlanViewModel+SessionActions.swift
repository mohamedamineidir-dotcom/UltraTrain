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

    // MARK: - Manual Complete with Stats

    func completeSessionManually(
        weekIndex: Int,
        sessionIndex: Int,
        distanceKm: Double?,
        durationSeconds: TimeInterval?,
        elevationGainM: Double?,
        feeling: PerceivedFeeling? = nil,
        exertion: Int? = nil
    ) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        var session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        session.isCompleted = true
        session.actualDistanceKm = distanceKm
        session.actualDurationSeconds = durationSeconds
        session.actualElevationGainM = elevationGainM
        session.perceivedFeeling = feeling
        session.perceivedExertion = exertion
        currentPlan.weeks[weekIndex].sessions[sessionIndex] = session

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan
            await updateWidgets()
            checkForAdjustments()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to complete session manually: \(error)")
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

    // MARK: - Link Session to Run

    func linkSessionToRun(weekIndex: Int, sessionIndex: Int, runId: UUID) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        do {
            currentPlan.weeks[weekIndex].sessions[sessionIndex].linkedRunId = runId
            currentPlan.weeks[weekIndex].sessions[sessionIndex].isCompleted = true
            try await planRepository.savePlan(currentPlan)
            try await runRepository?.updateLinkedSession(runId: runId, sessionId: currentPlan.weeks[weekIndex].sessions[sessionIndex].id)
            plan = currentPlan
            await updateWidgets()
            Logger.training.info("Linked run \(runId) to session")
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to link run: \(error)")
        }
    }

    func recentUnlinkedRuns(near date: Date, limit: Int = 10) async -> [CompletedRun] {
        guard let repo = runRepository else { return [] }
        do {
            let runs = try await repo.getRecentRuns(limit: limit * 2)
            let threeWeeks: TimeInterval = 21 * 24 * 3600
            return runs.filter {
                $0.linkedSessionId == nil && abs($0.date.timeIntervalSince(date)) <= threeWeeks
            }
            .prefix(limit)
            .map { $0 }
        } catch {
            Logger.training.error("Failed to load recent runs: \(error)")
            return []
        }
    }

    // MARK: - Strava Activities

    func recentStravaActivities(near date: Date) async -> [StravaActivity] {
        guard let authService = stravaAuthService, authService.isConnected(),
              let importService = stravaImportService else { return [] }
        do {
            let activities = try await importService.fetchActivities(page: 1, perPage: 50)
            let threeWeeks: TimeInterval = 21 * 24 * 3600
            return activities.filter {
                $0.type.lowercased().contains("run") &&
                abs($0.startDate.timeIntervalSince(date)) <= threeWeeks
            }
        } catch {
            Logger.training.error("Failed to fetch Strava activities: \(error)")
            return []
        }
    }

    func importAndLinkStravaActivity(
        weekIndex: Int, sessionIndex: Int, activity: StravaActivity
    ) async {
        guard let importService = stravaImportService else { return }
        guard let athlete else { return }
        do {
            let run = try await importService.importActivity(activity, athleteId: athlete.id)
            await linkSessionToRun(weekIndex: weekIndex, sessionIndex: sessionIndex, runId: run.id)
        } catch {
            self.error = "Failed to import Strava activity: \(error.localizedDescription)"
            Logger.training.error("Failed to import Strava activity: \(error)")
        }
    }
}
