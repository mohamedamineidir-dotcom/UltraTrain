import Foundation
import SwiftData

final class LocalMorningCheckInRepository: MorningCheckInRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getCheckIn(for date: Date) async throws -> MorningCheckIn? {
        let context = ModelContext(modelContainer)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        var descriptor = FetchDescriptor<MorningCheckInSwiftDataModel>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )
        descriptor.fetchLimit = 1
        let models = try context.fetch(descriptor)
        return models.first.map(MorningCheckInMapper.toDomain)
    }

    func saveCheckIn(_ checkIn: MorningCheckIn) async throws {
        let context = ModelContext(modelContainer)
        let existingId = checkIn.id
        let existingDescriptor = FetchDescriptor<MorningCheckInSwiftDataModel>(
            predicate: #Predicate { $0.id == existingId }
        )
        if let existing = try context.fetch(existingDescriptor).first {
            existing.date = checkIn.date
            existing.perceivedEnergy = checkIn.perceivedEnergy
            existing.muscleSoreness = checkIn.muscleSoreness
            existing.mood = checkIn.mood
            existing.sleepQualitySubjective = checkIn.sleepQualitySubjective
            existing.notes = checkIn.notes
        } else {
            context.insert(MorningCheckInMapper.toSwiftData(checkIn))
        }
        try context.save()
    }

    func getCheckIns(from startDate: Date, to endDate: Date) async throws -> [MorningCheckIn] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<MorningCheckInSwiftDataModel>(
            predicate: #Predicate { $0.date >= startDate && $0.date <= endDate },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let models = try context.fetch(descriptor)
        return models.map(MorningCheckInMapper.toDomain)
    }
}
