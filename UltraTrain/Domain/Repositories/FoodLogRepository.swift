import Foundation

protocol FoodLogRepository: Sendable {
    func getEntries(for date: Date) async throws -> [FoodLogEntry]
    func saveEntry(_ entry: FoodLogEntry) async throws
    func updateEntry(_ entry: FoodLogEntry) async throws
    func deleteEntry(id: UUID) async throws
    func getEntries(from: Date, to: Date) async throws -> [FoodLogEntry]
}
