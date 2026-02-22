import BackgroundTasks
import Foundation
import os

final class BackgroundTaskService: Sendable {
    static let healthKitSyncId = "com.ultratrain.app.healthkit-sync"
    static let recoveryCalcId = "com.ultratrain.app.recovery-calc"

    private let healthKitService: any HealthKitServiceProtocol
    private let recoveryRepository: any RecoveryRepository
    private let fitnessRepository: any FitnessRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let runRepository: any RunRepository

    init(
        healthKitService: any HealthKitServiceProtocol,
        recoveryRepository: any RecoveryRepository,
        fitnessRepository: any FitnessRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        runRepository: any RunRepository
    ) {
        self.healthKitService = healthKitService
        self.recoveryRepository = recoveryRepository
        self.fitnessRepository = fitnessRepository
        self.fitnessCalculator = fitnessCalculator
        self.runRepository = runRepository
    }

    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.healthKitSyncId,
            using: nil
        ) { task in
            nonisolated(unsafe) let refreshTask = task as! BGAppRefreshTask
            let service = self
            Task { @MainActor in
                await service.handleHealthKitSync(task: refreshTask)
            }
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.recoveryCalcId,
            using: nil
        ) { task in
            nonisolated(unsafe) let processingTask = task as! BGProcessingTask
            let service = self
            Task { @MainActor in
                await service.handleRecoveryCalc(task: processingTask)
            }
        }
    }

    func scheduleHealthKitSync() {
        let request = BGAppRefreshTaskRequest(identifier: Self.healthKitSyncId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.healthKit.debug("Scheduled HealthKit sync background task")
        } catch {
            Logger.healthKit.error("Failed to schedule HealthKit sync: \(error)")
        }
    }

    func scheduleRecoveryCalc() {
        let request = BGProcessingTaskRequest(identifier: Self.recoveryCalcId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 14400)
        request.requiresExternalPower = false
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.recovery.debug("Scheduled recovery calculation background task")
        } catch {
            Logger.recovery.error("Failed to schedule recovery calc: \(error)")
        }
    }

    @MainActor
    private func handleHealthKitSync(task: BGAppRefreshTask) async {
        scheduleHealthKitSync()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        do {
            let now = Date.now
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
            _ = try await healthKitService.fetchSleepData(from: yesterday, to: now)
            _ = try await healthKitService.fetchHRVData(from: yesterday, to: now)
            _ = try await healthKitService.fetchRestingHeartRate()
            task.setTaskCompleted(success: true)
            Logger.healthKit.info("Background HealthKit sync completed")
        } catch {
            Logger.healthKit.error("Background HealthKit sync failed: \(error)")
            task.setTaskCompleted(success: false)
        }
    }

    @MainActor
    private func handleRecoveryCalc(task: BGProcessingTask) async {
        scheduleRecoveryCalc()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        do {
            let now = Date.now
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

            let sleepData = try await healthKitService.fetchSleepData(from: yesterday, to: now)
            let hrvReadings = try await healthKitService.fetchHRVData(from: thirtyDaysAgo, to: now)
            let restingHR = try await healthKitService.fetchRestingHeartRate()
            let recentRuns = try await runRepository.getRecentRuns(limit: 200)
            let fitnessSnapshot = try await fitnessCalculator.execute(runs: recentRuns, asOf: now)

            try await fitnessRepository.saveSnapshot(fitnessSnapshot)

            let hrvTrend = HRVAnalyzer.analyze(readings: hrvReadings)
            let hrvScore = hrvTrend.map { HRVAnalyzer.hrvScore(trend: $0) }

            let baselineRHR = restingHR ?? 60
            let recoveryScore = RecoveryScoreCalculator.calculate(
                lastNightSleep: sleepData.last,
                sleepHistory: sleepData,
                currentRestingHR: restingHR,
                baselineRestingHR: baselineRHR,
                fitnessSnapshot: fitnessSnapshot,
                hrvScore: hrvScore
            )

            let snapshot = RecoverySnapshot(
                id: UUID(),
                date: now,
                recoveryScore: recoveryScore,
                sleepEntry: sleepData.last,
                restingHeartRate: restingHR,
                hrvReading: hrvReadings.last,
                readinessScore: nil
            )
            try await recoveryRepository.saveSnapshot(snapshot)

            task.setTaskCompleted(success: true)
            Logger.recovery.info("Background recovery calculation completed")
        } catch {
            Logger.recovery.error("Background recovery calc failed: \(error)")
            task.setTaskCompleted(success: false)
        }
    }
}
