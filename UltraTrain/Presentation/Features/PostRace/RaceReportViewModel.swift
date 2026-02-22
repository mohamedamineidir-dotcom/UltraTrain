import Foundation
import os

@Observable
@MainActor
final class RaceReportViewModel {
    let race: Race
    var reflection: RaceReflection?
    var estimate: FinishEstimate?
    var linkedRun: CompletedRun?
    var isLoading = true

    private let raceReflectionRepository: any RaceReflectionRepository
    private let finishEstimateRepository: any FinishEstimateRepository
    private let runRepository: any RunRepository

    init(
        race: Race,
        raceReflectionRepository: any RaceReflectionRepository,
        finishEstimateRepository: any FinishEstimateRepository,
        runRepository: any RunRepository
    ) {
        self.race = race
        self.raceReflectionRepository = raceReflectionRepository
        self.finishEstimateRepository = finishEstimateRepository
        self.runRepository = runRepository
    }

    func load() async {
        isLoading = true
        reflection = try? await raceReflectionRepository.getReflection(for: race.id)
        estimate = try? await finishEstimateRepository.getEstimate(for: race.id)
        if let runId = race.linkedRunId {
            linkedRun = try? await runRepository.getRun(id: runId)
        }
        isLoading = false
    }

    var goalAchieved: Bool {
        guard let actual = race.actualFinishTime else { return false }
        switch race.goalType {
        case .finish:
            return true
        case .targetTime(let target):
            return actual <= target
        case .targetRanking(let target):
            return (reflection?.actualPosition ?? Int.max) <= target
        }
    }

    var predictionAccuracy: Double? {
        guard let actual = race.actualFinishTime,
              let est = estimate else { return nil }
        let diff = abs(actual - est.expectedTime)
        return max(0, (1.0 - diff / est.expectedTime) * 100)
    }
}
