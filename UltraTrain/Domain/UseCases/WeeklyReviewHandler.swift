import Foundation

enum WeeklyReviewHandler {

    struct ReviewCheckResult: Equatable, Sendable {
        let isNeeded: Bool
        let previousWeekIndex: Int?
        let previousWeekNumber: Int?
        let nonRestSessions: [TrainingSession]
    }

    enum ReviewOutcome: Sendable {
        case allCompleted
        case noneCompleted
        case partiallyCompleted(completedIds: Set<UUID>)
    }

    // MARK: - Check

    static func checkReviewNeeded(
        plan: TrainingPlan,
        lastReviewedWeekNumber: Int,
        now: Date = .now
    ) -> ReviewCheckResult {
        let notNeeded = ReviewCheckResult(
            isNeeded: false,
            previousWeekIndex: nil,
            previousWeekNumber: nil,
            nonRestSessions: []
        )

        guard let currentWeekIndex = plan.weeks.firstIndex(where: { $0.contains(date: now) }),
              currentWeekIndex > 0 else {
            return notNeeded
        }

        let previousWeek = plan.weeks[currentWeekIndex - 1]

        guard previousWeek.weekNumber > lastReviewedWeekNumber else {
            return notNeeded
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let weekEnd = calendar.startOfDay(for: previousWeek.endDate)
        guard weekEnd < today else { return notNeeded }

        let nonRestSessions = previousWeek.sessions.filter { $0.type != .rest }
        guard !nonRestSessions.isEmpty else { return notNeeded }

        let completedCount = nonRestSessions.filter(\.isCompleted).count
        guard completedCount == 0 else { return notNeeded }

        return ReviewCheckResult(
            isNeeded: true,
            previousWeekIndex: currentWeekIndex - 1,
            previousWeekNumber: previousWeek.weekNumber,
            nonRestSessions: nonRestSessions
        )
    }

    // MARK: - Apply

    static func applyOutcome(
        _ outcome: ReviewOutcome,
        plan: TrainingPlan,
        previousWeekIndex: Int
    ) -> (updatedSessions: [TrainingSession], needsVolumeReduction: Bool) {
        let nonRestSessions = plan.weeks[previousWeekIndex].sessions
            .filter { $0.type != .rest }

        switch outcome {
        case .allCompleted:
            let updated = nonRestSessions.map { session in
                var s = session
                s.isCompleted = true
                return s
            }
            return (updated, false)

        case .noneCompleted:
            let updated = nonRestSessions.map { session in
                var s = session
                s.isSkipped = true
                return s
            }
            return (updated, true)

        case .partiallyCompleted(let completedIds):
            var updated: [TrainingSession] = []
            var missedKeySession = false
            for session in nonRestSessions {
                var s = session
                if completedIds.contains(session.id) {
                    s.isCompleted = true
                } else {
                    s.isSkipped = true
                    if session.isKeySession { missedKeySession = true }
                }
                updated.append(s)
            }
            return (updated, missedKeySession)
        }
    }

    // MARK: - Volume Reduction

    static func reduceCurrentWeekVolume(
        plan: TrainingPlan,
        currentWeekIndex: Int,
        reductionPercent: Double = AppConfiguration.Training.lowAdherenceVolumeReductionPercent
    ) -> [TrainingSession] {
        let factor = 1.0 - reductionPercent / 100.0
        let today = Calendar.current.startOfDay(for: .now)
        let week = plan.weeks[currentWeekIndex]

        return week.sessions.compactMap { session in
            let sessionDay = Calendar.current.startOfDay(for: session.date)
            guard sessionDay >= today,
                  session.type != .rest,
                  !session.isCompleted else { return nil }
            var s = session
            s.plannedDistanceKm *= factor
            s.plannedElevationGainM *= factor
            s.plannedDuration *= factor
            return s
        }
    }
}
