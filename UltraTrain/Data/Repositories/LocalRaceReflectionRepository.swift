import Foundation
import SwiftData
import os

final class LocalRaceReflectionRepository: RaceReflectionRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getReflection(for raceId: UUID) async throws -> RaceReflection? {
        let context = ModelContext(modelContainer)
        let targetRaceId = raceId
        var descriptor = FetchDescriptor<RaceReflectionSwiftDataModel>(
            predicate: #Predicate { $0.raceId == targetRaceId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else { return nil }
        guard let reflection = RaceReflectionMapper.toDomain(model) else {
            throw DomainError.persistenceError(message: "Failed to map stored race reflection data")
        }
        return reflection
    }

    func saveReflection(_ reflection: RaceReflection) async throws {
        let context = ModelContext(modelContainer)

        let targetRaceId = reflection.raceId
        let existing = FetchDescriptor<RaceReflectionSwiftDataModel>(
            predicate: #Predicate { $0.raceId == targetRaceId }
        )
        for old in try context.fetch(existing) {
            context.delete(old)
        }

        let model = RaceReflectionMapper.toSwiftData(reflection)
        context.insert(model)
        try context.save()
        Logger.persistence.info("Race reflection saved for race")
    }
}
