import Foundation
import os

@Observable
@MainActor
final class MorningReadinessViewModel {

    private let healthKitService: any HealthKitServiceProtocol
    private let recoveryRepository: any RecoveryRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let fitnessRepository: any FitnessRepository
    private let morningCheckInRepository: (any MorningCheckInRepository)?

    var readinessScore: ReadinessScore?
    var recoveryScore: RecoveryScore?
    var hrvTrend: HRVAnalyzer.HRVTrend?
    var hrvReadings: [HRVReading] = []
    var recoveryHistory: [RecoverySnapshot] = []
    var sleepEntry: SleepEntry?
    var morningCheckIn: MorningCheckIn?
    var recommendations: [RecoveryRecommendation] = []
    var isLoading = false
    var error: String?

    init(
        healthKitService: any HealthKitServiceProtocol,
        recoveryRepository: any RecoveryRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        fitnessRepository: any FitnessRepository,
        morningCheckInRepository: (any MorningCheckInRepository)? = nil
    ) {
        self.healthKitService = healthKitService
        self.recoveryRepository = recoveryRepository
        self.fitnessCalculator = fitnessCalculator
        self.fitnessRepository = fitnessRepository
        self.morningCheckInRepository = morningCheckInRepository
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

            let fitnessSnapshot = try await fitnessRepository.getLatestSnapshot()

            if let recovery = recoveryScore {
                readinessScore = ReadinessCalculator.calculate(
                    recoveryScore: recovery,
                    hrvTrend: hrvTrend,
                    fitnessSnapshot: fitnessSnapshot
                )
            }

            morningCheckIn = try await morningCheckInRepository?.getCheckIn(for: now)
            recommendations = RecoveryRecommendationEngine.recommend(
                readiness: readinessScore,
                checkIn: morningCheckIn,
                recoveryScore: recoveryScore
            )
        } catch {
            self.error = error.localizedDescription
            Logger.recovery.error("Failed to load readiness data: \(error)")
        }
        isLoading = false
    }
}
