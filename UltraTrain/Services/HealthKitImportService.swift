import Foundation
import os

final class HealthKitImportService: HealthKitImportServiceProtocol, @unchecked Sendable {

    private let healthKitService: any HealthKitServiceProtocol
    private let runRepository: any RunRepository
    private let planRepository: any TrainingPlanRepository

    init(
        healthKitService: any HealthKitServiceProtocol,
        runRepository: any RunRepository,
        planRepository: any TrainingPlanRepository
    ) {
        self.healthKitService = healthKitService
        self.runRepository = runRepository
        self.planRepository = planRepository
    }

    // MARK: - Import

    func importNewWorkouts(athleteId: UUID) async throws -> HealthKitImportResult {
        let now = Date.now
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!

        let workouts = try await healthKitService.fetchWorkouts(
            activityTypes: ActivityType.allCases.filter { $0 != .other },
            from: thirtyDaysAgo,
            to: now
        )

        let existingRuns = try await runRepository.getRecentRuns(limit: 200)
        let plan = try await planRepository.getActivePlan()
        let allSessions = plan?.weeks.flatMap(\.sessions) ?? []

        var importedCount = 0
        var skippedCount = 0
        var matchedSessionCount = 0

        for workout in workouts {
            if isDuplicate(workout: workout, existingRuns: existingRuns) {
                skippedCount += 1
                continue
            }

            let run = mapToCompletedRun(workout: workout, athleteId: athleteId)
            try await runRepository.saveRun(run)
            importedCount += 1

            guard run.isRunningActivity else { continue }

            if let match = SessionMatcher.findMatch(
                runDate: run.date,
                distanceKm: run.distanceKm,
                duration: run.duration,
                candidates: allSessions
            ) {
                var updatedSession = match.session
                updatedSession.isCompleted = true
                updatedSession.linkedRunId = run.id
                try await planRepository.updateSession(updatedSession)
                try await runRepository.updateLinkedSession(
                    runId: run.id,
                    sessionId: match.session.id
                )
                matchedSessionCount += 1
            }
        }

        Logger.healthKit.info(
            "HealthKit import: \(importedCount) imported, \(skippedCount) skipped, \(matchedSessionCount) matched"
        )

        return HealthKitImportResult(
            importedCount: importedCount,
            skippedCount: skippedCount,
            matchedSessionCount: matchedSessionCount
        )
    }

    // MARK: - Private

    private func isDuplicate(
        workout: HealthKitWorkout,
        existingRuns: [CompletedRun]
    ) -> Bool {
        existingRuns.contains { run in
            if run.healthKitWorkoutUUID == workout.originalUUID { return true }
            let timeDiff = abs(run.date.timeIntervalSince(workout.startDate))
            let distanceDiff = abs(run.distanceKm - workout.distanceKm)
            return timeDiff < 3600 && distanceDiff < 0.5
        }
    }

    private func mapToCompletedRun(
        workout: HealthKitWorkout,
        athleteId: UUID
    ) -> CompletedRun {
        let pace = RunStatisticsCalculator.averagePace(
            distanceKm: workout.distanceKm,
            duration: workout.duration
        )

        return CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: workout.startDate,
            distanceKm: workout.distanceKm,
            elevationGainM: workout.elevationGainM,
            elevationLossM: 0,
            duration: workout.duration,
            averageHeartRate: workout.averageHeartRate,
            maxHeartRate: workout.maxHeartRate,
            averagePaceSecondsPerKm: pace,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0,
            isHealthKitImport: true,
            healthKitWorkoutUUID: workout.originalUUID,
            activityType: workout.activityType
        )
    }
}
