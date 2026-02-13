import Foundation
import SwiftData
import os

final class LocalAthleteRepository: AthleteRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getAthlete() async throws -> Athlete? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<AthleteSwiftDataModel>()
        let results = try context.fetch(descriptor)

        guard let model = results.first else { return nil }
        guard let athlete = AthleteSwiftDataMapper.toDomain(model) else {
            throw DomainError.persistenceError(message: "Failed to map stored athlete data")
        }
        return athlete
    }

    func saveAthlete(_ athlete: Athlete) async throws {
        let context = ModelContext(modelContainer)
        let model = AthleteSwiftDataMapper.toSwiftData(athlete)
        context.insert(model)
        try context.save()
        Logger.persistence.info("Athlete saved: \(athlete.firstName) \(athlete.lastName)")
    }

    func updateAthlete(_ athlete: Athlete) async throws {
        let context = ModelContext(modelContainer)
        let targetId = athlete.id
        var descriptor = FetchDescriptor<AthleteSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.athleteNotFound
        }

        existing.firstName = athlete.firstName
        existing.lastName = athlete.lastName
        existing.dateOfBirth = athlete.dateOfBirth
        existing.weightKg = athlete.weightKg
        existing.heightCm = athlete.heightCm
        existing.restingHeartRate = athlete.restingHeartRate
        existing.maxHeartRate = athlete.maxHeartRate
        existing.experienceLevelRaw = athlete.experienceLevel.rawValue
        existing.weeklyVolumeKm = athlete.weeklyVolumeKm
        existing.longestRunKm = athlete.longestRunKm
        existing.preferredUnitRaw = athlete.preferredUnit.rawValue

        try context.save()
        Logger.persistence.info("Athlete updated: \(athlete.firstName) \(athlete.lastName)")
    }
}
