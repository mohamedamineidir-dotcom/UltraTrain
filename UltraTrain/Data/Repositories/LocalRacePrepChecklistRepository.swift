import Foundation
import SwiftData
import os

final class LocalRacePrepChecklistRepository: RacePrepChecklistRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getChecklist(for raceId: UUID) async throws -> RacePrepChecklist? {
        let context = ModelContext(modelContainer)
        let targetId = raceId
        let descriptor = FetchDescriptor<RacePrepChecklistSwiftDataModel>(
            predicate: #Predicate { $0.raceId == targetId }
        )
        guard let model = try context.fetch(descriptor).first else { return nil }
        return RacePrepChecklistSwiftDataMapper.toDomain(model)
    }

    func saveChecklist(_ checklist: RacePrepChecklist) async throws {
        let context = ModelContext(modelContainer)
        // Delete existing checklist for same race
        let targetRaceId = checklist.raceId
        let existing = FetchDescriptor<RacePrepChecklistSwiftDataModel>(
            predicate: #Predicate { $0.raceId == targetRaceId }
        )
        for model in try context.fetch(existing) {
            context.delete(model)
        }
        let model = RacePrepChecklistSwiftDataMapper.toSwiftData(checklist)
        context.insert(model)
        try context.save()
    }

    func deleteChecklist(for raceId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = raceId
        let descriptor = FetchDescriptor<RacePrepChecklistSwiftDataModel>(
            predicate: #Predicate { $0.raceId == targetId }
        )
        for model in try context.fetch(descriptor) {
            context.delete(model)
        }
        try context.save()
    }
}
