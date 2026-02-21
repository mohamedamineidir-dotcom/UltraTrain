import Foundation
import SwiftData
import os

final class LocalGoalRepository: GoalRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getActiveGoal(period: GoalPeriod) async throws -> TrainingGoal? {
        let context = ModelContext(modelContainer)
        let periodString = period.rawValue
        let now = Date.now
        var descriptor = FetchDescriptor<TrainingGoalSwiftDataModel>(
            predicate: #Predicate {
                $0.periodRaw == periodString &&
                $0.startDate <= now &&
                $0.endDate >= now
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let results = try context.fetch(descriptor)
        return results.first.map { TrainingGoalSwiftDataMapper.toDomain($0) }
    }

    func getGoalHistory(period: GoalPeriod, limit: Int) async throws -> [TrainingGoal] {
        let context = ModelContext(modelContainer)
        let periodString = period.rawValue
        var descriptor = FetchDescriptor<TrainingGoalSwiftDataModel>(
            predicate: #Predicate { $0.periodRaw == periodString },
            sortBy: [SortDescriptor(\.endDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let results = try context.fetch(descriptor)
        return results.map { TrainingGoalSwiftDataMapper.toDomain($0) }
    }

    func saveGoal(_ goal: TrainingGoal) async throws {
        let context = ModelContext(modelContainer)
        let model = TrainingGoalSwiftDataMapper.toSwiftData(goal)
        context.insert(model)
        try context.save()
        Logger.training.info("Training goal saved: \(goal.id) (\(goal.period.rawValue))")
    }

    func deleteGoal(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<TrainingGoalSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.persistenceError(message: "Goal not found for deletion")
        }
        context.delete(model)
        try context.save()
        Logger.training.info("Training goal deleted: \(id)")
    }
}
