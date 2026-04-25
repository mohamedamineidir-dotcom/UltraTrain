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
            refreshMissedSessionPattern()
            refreshScheduledReminders()
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
            refreshMissedSessionPattern()
            refreshScheduledReminders()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to complete session manually: \(error)")
        }
    }

    // MARK: - Skip

    func skipSession(weekIndex: Int, sessionIndex: Int, reason: SkipReason? = nil) async {
        guard var currentPlan = plan else { return }
        guard weekIndex < currentPlan.weeks.count,
              sessionIndex < currentPlan.weeks[weekIndex].sessions.count else { return }

        var session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
        session.isSkipped = true
        session.skipReason = reason
        currentPlan.weeks[weekIndex].sessions[sessionIndex] = session

        do {
            try await planRepository.updateSession(session)
            plan = currentPlan

            // Run skip-specific adaptation if reason provided
            if let reason {
                analyzeSkipAdaptation(
                    session: session,
                    reason: reason,
                    weekIndex: weekIndex,
                    plan: currentPlan
                )
            }

            checkForAdjustments()
            refreshMissedSessionPattern()
            refreshScheduledReminders()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to skip session: \(error)")
        }
    }

    private func analyzeSkipAdaptation(
        session: TrainingSession,
        reason: SkipReason,
        weekIndex: Int,
        plan: TrainingPlan
    ) {
        let currentWeek = plan.weeks[weekIndex]
        let nextWeek = weekIndex + 1 < plan.weeks.count ? plan.weeks[weekIndex + 1] : nil

        // Gather recent skip reasons from last 3 weeks for pattern detection
        let lookbackStart = max(0, weekIndex - 2)
        let recentSkipReasons: [SkipReason] = plan.weeks[lookbackStart..<weekIndex]
            .flatMap(\.sessions)
            .filter { $0.isSkipped }
            .compactMap(\.skipReason)

        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: reason,
            currentWeek: currentWeek,
            nextWeek: nextWeek,
            experience: athlete?.experienceLevel ?? .intermediate,
            recentSkipReasons: recentSkipReasons,
            totalWeeksInPlan: plan.weeks.count,
            raceDate: plan.weeks.last?.endDate
        )

        let adaptation = SkipAdaptationCalculator.analyze(context: context)

        // Merge skip-based recommendations into existing recommendations
        if !adaptation.recommendations.isEmpty {
            adjustmentRecommendations.append(contentsOf: adaptation.recommendations)
        }
    }

    /// Bulk-skip every session falling within an N-day suspension window
    /// starting today. Used for two athlete-state events a coach handles
    /// regularly:
    ///   • **Illness** — flu, cold, GI virus. 3-7 day window with reason
    ///     `.illness`. Triggers the existing missed-session pattern
    ///     detector + auto-applied volume reduction once threshold is
    ///     crossed.
    ///   • **Acute injury** — strain, sprain, sharp pain. 5-14 day
    ///     window with reason `.injury`. Same auto-rebuild path.
    ///
    /// Sessions already past (date < today) are left alone. Already-
    /// completed sessions stay completed. Recovery / cross-training
    /// sessions are intentionally skipped too — full pause means full
    /// pause, not "swap intervals for 30 min cycling."
    func suspendTraining(forDays days: Int, reason: SkipReason) async {
        guard days > 0, var currentPlan = plan else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let endDate = calendar.date(byAdding: .day, value: days, to: today) else { return }

        var skippedAny = false
        for weekIndex in currentPlan.weeks.indices {
            for sessionIndex in currentPlan.weeks[weekIndex].sessions.indices {
                let session = currentPlan.weeks[weekIndex].sessions[sessionIndex]
                let sessionDay = calendar.startOfDay(for: session.date)
                guard sessionDay >= today, sessionDay < endDate else { continue }
                guard !session.isCompleted, !session.isSkipped else { continue }
                guard session.type != .rest else { continue }

                var updated = session
                updated.isSkipped = true
                updated.skipReason = reason
                currentPlan.weeks[weekIndex].sessions[sessionIndex] = updated

                do {
                    try await planRepository.updateSession(updated)
                    skippedAny = true
                } catch {
                    Logger.training.error("Failed to skip session during suspension: \(error)")
                }
            }
        }

        guard skippedAny else { return }
        plan = currentPlan
        // Trigger the missed-session detector and the urgent
        // auto-apply path. With Commit A's auto-apply for
        // .reduceTargetDueToAccumulatedMissed at .urgent severity, the
        // remaining plan will silently de-load without the athlete
        // having to reason about it.
        checkForAdjustments()
        refreshMissedSessionPattern()
        refreshScheduledReminders()
    }

    /// Records a mid-cycle injury escalation. Updates the athlete's
    /// `hasRecentInjury` flag so future plan generation gates VO2max
    /// work, and optionally suspends training for an acute window.
    /// `painFrequency` can also be raised (e.g. `.sometimes` → `.often`)
    /// so the next plan generation switches to threshold-only base.
    ///
    /// The flag update affects every NEW session built from the
    /// regenerator after this call. Existing un-completed future
    /// sessions stay as-is until the plan rebuilds (race-date change
    /// or athlete-triggered regenerate).
    func reportMidCycleInjury(
        suspendDays: Int,
        bumpPainFrequencyToOften: Bool
    ) async {
        guard var currentAthlete = athlete else { return }
        currentAthlete.hasRecentInjury = true
        if currentAthlete.injuryCountLastYear == .none {
            currentAthlete.injuryCountLastYear = .one
        }
        if bumpPainFrequencyToOften {
            currentAthlete.painFrequency = .often
        }
        do {
            try await athleteRepository.updateAthlete(currentAthlete)
            athlete = currentAthlete
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to record mid-cycle injury on athlete profile: \(error)")
            return
        }
        if suspendDays > 0 {
            await suspendTraining(forDays: suspendDays, reason: .injury)
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
            refreshMissedSessionPattern()
            refreshScheduledReminders()
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
            refreshMissedSessionPattern()
            refreshScheduledReminders()
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
            refreshMissedSessionPattern()
            refreshScheduledReminders()
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
            refreshScheduledReminders()
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
