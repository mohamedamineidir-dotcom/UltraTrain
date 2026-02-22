import Foundation
import SwiftData
import os

final class LocalFoodLogRepository: FoodLogRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getEntries(for date: Date) async throws -> [FoodLogEntry] {
        let context = ModelContext(modelContainer)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let descriptor = FetchDescriptor<FoodLogEntrySwiftDataModel>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay },
            sortBy: [SortDescriptor(\.date)]
        )

        let models = try context.fetch(descriptor)
        return models.compactMap { FoodLogEntryMapper.toDomain($0) }
    }

    func saveEntry(_ entry: FoodLogEntry) async throws {
        let context = ModelContext(modelContainer)
        let model = FoodLogEntryMapper.toSwiftData(entry)
        context.insert(model)
        try context.save()
        Logger.nutrition.info("Food log entry saved: \(entry.mealType.rawValue)")
    }

    func updateEntry(_ entry: FoodLogEntry) async throws {
        let context = ModelContext(modelContainer)
        let targetId = entry.id
        var descriptor = FetchDescriptor<FoodLogEntrySwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.persistenceError(message: "Food log entry not found for update")
        }

        context.delete(existing)
        let model = FoodLogEntryMapper.toSwiftData(entry)
        context.insert(model)
        try context.save()
        Logger.nutrition.info("Food log entry updated")
    }

    func deleteEntry(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<FoodLogEntrySwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.persistenceError(message: "Food log entry not found for deletion")
        }

        context.delete(existing)
        try context.save()
        Logger.nutrition.info("Food log entry deleted")
    }

    func getEntries(from startDate: Date, to endDate: Date) async throws -> [FoodLogEntry] {
        let context = ModelContext(modelContainer)

        let descriptor = FetchDescriptor<FoodLogEntrySwiftDataModel>(
            predicate: #Predicate { $0.date >= startDate && $0.date <= endDate },
            sortBy: [SortDescriptor(\.date)]
        )

        let models = try context.fetch(descriptor)
        return models.compactMap { FoodLogEntryMapper.toDomain($0) }
    }
}
