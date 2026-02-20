import Foundation
import SwiftData
import os

final class LocalRunRepository: RunRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getRuns(for athleteId: UUID) async throws -> [CompletedRun] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<CompletedRunSwiftDataModel>(
            predicate: #Predicate { $0.athleteId == athleteId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return results.map { CompletedRunSwiftDataMapper.toDomain($0) }
    }

    func getRun(id: UUID) async throws -> CompletedRun? {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<CompletedRunSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return nil }
        return CompletedRunSwiftDataMapper.toDomain(model)
    }

    func saveRun(_ run: CompletedRun) async throws {
        let context = ModelContext(modelContainer)
        let model = CompletedRunSwiftDataMapper.toSwiftData(run)
        context.insert(model)
        try context.save()
        Logger.tracking.info("Run saved: \(run.distanceKm, format: .fixed(precision: 1)) km")
    }

    func deleteRun(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<CompletedRunSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return }
        context.delete(model)
        try context.save()
        Logger.tracking.info("Run deleted: \(id)")
    }

    func updateRun(_ run: CompletedRun) async throws {
        let context = ModelContext(modelContainer)
        let targetId = run.id
        var descriptor = FetchDescriptor<CompletedRunSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.persistenceError(message: "Run not found for update")
        }
        model.stravaActivityId = run.stravaActivityId
        model.isStravaImport = run.isStravaImport
        model.isHealthKitImport = run.isHealthKitImport
        model.healthKitWorkoutUUID = run.healthKitWorkoutUUID
        model.notes = run.notes
        model.updatedAt = Date()
        try context.save()
        Logger.tracking.info("Run updated: \(run.id)")
    }

    func updateLinkedSession(runId: UUID, sessionId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = runId
        var descriptor = FetchDescriptor<CompletedRunSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.persistenceError(message: "Run not found for linking")
        }
        model.linkedSessionId = sessionId
        model.updatedAt = Date()
        try context.save()
        Logger.tracking.info("Run \(runId) linked to session \(sessionId)")
    }

    func getRecentRuns(limit: Int) async throws -> [CompletedRun] {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<CompletedRunSwiftDataModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let results = try context.fetch(descriptor)
        return results.map { CompletedRunSwiftDataMapper.toDomain($0) }
    }
}
