import Foundation
import SwiftData
import os

final class LocalTrainingPlanRepository: TrainingPlanRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getActivePlan() async throws -> TrainingPlan? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<TrainingPlanSwiftDataModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let results = try context.fetch(descriptor)

        guard let model = results.first else { return nil }
        guard let plan = TrainingPlanSwiftDataMapper.toDomain(model) else {
            throw DomainError.persistenceError(message: "Failed to map stored training plan data")
        }
        return plan
    }

    func getPlan(id: UUID) async throws -> TrainingPlan? {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<TrainingPlanSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else { return nil }
        return TrainingPlanSwiftDataMapper.toDomain(model)
    }

    func savePlan(_ plan: TrainingPlan) async throws {
        let context = ModelContext(modelContainer)

        // Delete existing plans for the same athlete (one active plan at a time)
        let athleteId = plan.athleteId
        let existing = FetchDescriptor<TrainingPlanSwiftDataModel>(
            predicate: #Predicate { $0.athleteId == athleteId }
        )
        for old in try context.fetch(existing) {
            context.delete(old)
        }

        let model = TrainingPlanSwiftDataMapper.toSwiftData(plan)
        context.insert(model)
        try context.save()
        Logger.persistence.info("Training plan saved with \(plan.weeks.count) weeks")
    }

    func updatePlan(_ plan: TrainingPlan) async throws {
        let context = ModelContext(modelContainer)
        let targetId = plan.id
        var descriptor = FetchDescriptor<TrainingPlanSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.trainingPlanNotFound
        }

        // Replace: delete old and insert fresh
        context.delete(existing)
        let model = TrainingPlanSwiftDataMapper.toSwiftData(plan)
        context.insert(model)
        try context.save()
        Logger.persistence.info("Training plan updated")
    }

    func updateSession(_ session: TrainingSession) async throws {
        let context = ModelContext(modelContainer)
        let targetId = session.id
        var descriptor = FetchDescriptor<TrainingSessionSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.trainingPlanNotFound
        }

        existing.isCompleted = session.isCompleted
        existing.linkedRunId = session.linkedRunId
        try context.save()
        Logger.persistence.info("Session updated: \(session.type.rawValue) completed=\(session.isCompleted)")
    }
}
