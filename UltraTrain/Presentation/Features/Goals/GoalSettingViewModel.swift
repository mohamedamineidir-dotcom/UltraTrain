import Foundation
import os

@Observable
@MainActor
final class GoalSettingViewModel {
    private let goalRepository: any GoalRepository

    var period: GoalPeriod = .weekly
    var targetDistanceKm: Double?
    var targetElevationM: Double?
    var targetRunCount: Int?
    var targetDurationMinutes: Int?
    var isSaving = false
    var error: String?
    var didSave = false

    var isEditing: Bool { existingGoalId != nil }

    private var existingGoalId: UUID?

    init(goalRepository: any GoalRepository, existingGoal: TrainingGoal? = nil) {
        self.goalRepository = goalRepository
        if let goal = existingGoal {
            existingGoalId = goal.id
            period = goal.period
            targetDistanceKm = goal.targetDistanceKm
            targetElevationM = goal.targetElevationM
            targetRunCount = goal.targetRunCount
            if let seconds = goal.targetDurationSeconds {
                targetDurationMinutes = Int(seconds / 60)
            }
        }
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }

        let (startDate, endDate) = dateBounds(for: period)

        let goal = TrainingGoal(
            id: existingGoalId ?? UUID(),
            period: period,
            targetDistanceKm: targetDistanceKm,
            targetElevationM: targetElevationM,
            targetRunCount: targetRunCount,
            targetDurationSeconds: targetDurationMinutes.map { Double($0) * 60 },
            startDate: startDate,
            endDate: endDate
        )

        do {
            try await goalRepository.saveGoal(goal)
            didSave = true
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to save goal: \(error)")
        }
    }

    private func dateBounds(for period: GoalPeriod) -> (Date, Date) {
        switch period {
        case .weekly:
            let start = Date.now.startOfWeek
            let end = start.adding(days: 6)
            return (start, end)
        case .monthly:
            let start = Date.now.startOfMonth
            let end = Date.now.endOfMonth
            return (start, end)
        }
    }
}
