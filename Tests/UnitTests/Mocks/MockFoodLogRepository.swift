import Foundation
@testable import UltraTrain

final class MockFoodLogRepository: FoodLogRepository, @unchecked Sendable {
    var entries: [FoodLogEntry] = []
    var shouldThrow = false

    func getEntries(for date: Date) async throws -> [FoodLogEntry] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func saveEntry(_ entry: FoodLogEntry) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        entries.append(entry)
    }

    func updateEntry(_ entry: FoodLogEntry) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
    }

    func deleteEntry(id: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        entries.removeAll { $0.id == id }
    }

    func getEntries(from: Date, to: Date) async throws -> [FoodLogEntry] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return entries.filter { $0.date >= from && $0.date <= to }
    }
}
