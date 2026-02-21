import Foundation
import os

@Observable
@MainActor
final class MorningReadinessViewModel {

    private let healthKitService: any HealthKitServiceProtocol
    private let recoveryRepository: any RecoveryRepository
    private let fitnessCalculator: any CalculateFitnessUseCase

    var readinessScore: ReadinessScore?
    var recoveryScore: RecoveryScore?
    var hrvTrend: HRVAnalyzer.HRVTrend?
    var hrvReadings: [HRVReading] = []
    var recoveryHistory: [RecoverySnapshot] = []
    var sleepEntry: SleepEntry?
    var isLoading = false
    var error: String?

    init(
        healthKitService: any HealthKitServiceProtocol,
        recoveryRepository: any RecoveryRepository,
        fitnessCalculator: any CalculateFitnessUseCase
    ) {
        self.healthKitService = healthKitService
        self.recoveryRepository = recoveryRepository
        self.fitnessCalculator = fitnessCalculator
    }

    func load() async {
        isLoading = true
        do {
            let now = Date.now
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!

            hrvReadings = try await healthKitService.fetchHRVData(from: thirtyDaysAgo, to: now)
            hrvTrend = HRVAnalyzer.analyze(readings: hrvReadings)

            recoveryHistory = try await recoveryRepository.getSnapshots(from: thirtyDaysAgo, to: now)

            if let latestSnapshot = recoveryHistory.last {
                recoveryScore = latestSnapshot.recoveryScore
                sleepEntry = latestSnapshot.sleepEntry
            }

            if let recovery = recoveryScore {
                readinessScore = ReadinessCalculator.calculate(
                    recoveryScore: recovery,
                    hrvTrend: hrvTrend,
                    fitnessSnapshot: nil
                )
            }
        } catch {
            self.error = error.localizedDescription
            Logger.recovery.error("Failed to load readiness data: \(error)")
        }
        isLoading = false
    }
}
