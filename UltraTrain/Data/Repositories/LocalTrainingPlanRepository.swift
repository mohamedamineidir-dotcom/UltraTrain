import Foundation
import SwiftData
import os

// @unchecked Sendable: thread-safe via ModelContainer (new context per call)
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

        // Prefer the active (non-archived) plan; fall back to most-recent so
        // legacy data (no archive flag set) keeps working.
        guard let model = results.first(where: { !$0.isArchived }) ?? results.first else {
            return nil
        }
        guard let plan = TrainingPlanSwiftDataMapper.toDomain(model) else {
            throw DomainError.persistenceError(message: "Failed to map stored training plan data")
        }
        return plan
    }

    func getAllPlans() async throws -> [TrainingPlan] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<TrainingPlanSwiftDataModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).compactMap { TrainingPlanSwiftDataMapper.toDomain($0) }
    }

    func setActivePlan(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let all = try context.fetch(FetchDescriptor<TrainingPlanSwiftDataModel>())
        for model in all {
            model.isArchived = (model.id != id)
        }
        try context.save()
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

        let athleteId = plan.athleteId
        let isScenario = plan.isScenarioPlan
        let existing = try context.fetch(FetchDescriptor<TrainingPlanSwiftDataModel>(
            predicate: #Predicate { $0.athleteId == athleteId }
        ))
        for old in existing {
            if old.isScenarioPlan == isScenario {
                // Replace a prior plan of the SAME kind (e.g. regenerating
                // the custom plan, or re-picking a scenario).
                context.delete(old)
            } else {
                // Preserve the OTHER kind (e.g. a paying user's custom plan
                // when a free scenario is saved), but archive it so only the
                // newly-saved plan is active.
                old.isArchived = true
            }
        }

        var active = plan
        active.isArchived = false
        let model = TrainingPlanSwiftDataMapper.toSwiftData(active)
        context.insert(model)
        try context.save()
        Logger.persistence.info("Training plan saved with \(plan.weeks.count) weeks (scenario=\(isScenario))")
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

        existing.date = session.date
        existing.isCompleted = session.isCompleted
        existing.isSkipped = session.isSkipped
        existing.linkedRunId = session.linkedRunId
        existing.plannedDistanceKm = session.plannedDistanceKm
        existing.plannedElevationGainM = session.plannedElevationGainM
        existing.plannedDuration = session.plannedDuration
        existing.actualDistanceKm = session.actualDistanceKm
        existing.actualDurationSeconds = session.actualDurationSeconds
        existing.actualElevationGainM = session.actualElevationGainM
        existing.perceivedFeelingRaw = session.perceivedFeeling?.rawValue
        existing.perceivedExertion = session.perceivedExertion
        existing.skipReasonRaw = session.skipReason?.rawValue
        try context.save()
        Logger.persistence.info("Session updated: \(session.type.rawValue) completed=\(session.isCompleted) skipped=\(session.isSkipped)")
    }
}
