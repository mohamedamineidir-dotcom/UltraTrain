import Foundation
@testable import UltraTrain

final class MockCalculateTrainingLoadUseCase: CalculateTrainingLoadUseCase, @unchecked Sendable {
    var resultSummary: TrainingLoadSummary?
    var shouldThrow = false

    func execute(
        runs: [CompletedRun],
        plan: TrainingPlan?,
        asOf date: Date
    ) async throws -> TrainingLoadSummary {
        if shouldThrow { throw DomainError.insufficientData(reason: "Mock error") }
        return resultSummary ?? TrainingLoadSummary(
            currentWeekLoad: WeeklyLoadData(weekStartDate: date.startOfWeek),
            weeklyHistory: [],
            acrTrend: [],
            monotony: 0,
            monotonyLevel: .low
        )
    }
}
