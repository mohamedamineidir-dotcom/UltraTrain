import Foundation
import SwiftData
import os

final class LocalRaceRepository: RaceRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getRaces() async throws -> [Race] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<RaceSwiftDataModel>(
            sortBy: [SortDescriptor(\.date)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { RaceSwiftDataMapper.toDomain($0) }
    }

    func getRace(id: UUID) async throws -> Race? {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<RaceSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else { return nil }
        return RaceSwiftDataMapper.toDomain(model)
    }

    func saveRace(_ race: Race) async throws {
        let context = ModelContext(modelContainer)
        let model = RaceSwiftDataMapper.toSwiftData(race)
        context.insert(model)
        try context.save()
        Logger.persistence.info("Race saved: \(race.name)")
    }

    func updateRace(_ race: Race) async throws {
        let context = ModelContext(modelContainer)
        let targetId = race.id
        var descriptor = FetchDescriptor<RaceSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.raceNotFound
        }

        existing.name = race.name
        existing.date = race.date
        existing.distanceKm = race.distanceKm
        existing.elevationGainM = race.elevationGainM
        existing.elevationLossM = race.elevationLossM
        existing.priorityRaw = race.priority.rawValue
        existing.terrainDifficultyRaw = race.terrainDifficulty.rawValue

        let (goalTypeRaw, goalValue) = encodeGoal(race.goalType)
        existing.goalTypeRaw = goalTypeRaw
        existing.goalValue = goalValue

        try context.save()
        Logger.persistence.info("Race updated: \(race.name)")
    }

    func deleteRace(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<RaceSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.raceNotFound
        }

        context.delete(model)
        try context.save()
        Logger.persistence.info("Race deleted: \(model.name)")
    }

    private func encodeGoal(_ goal: RaceGoal) -> (String, Double?) {
        switch goal {
        case .finish:
            return ("finish", nil)
        case .targetTime(let interval):
            return ("targetTime", interval)
        case .targetRanking(let rank):
            return ("targetRanking", Double(rank))
        }
    }
}
