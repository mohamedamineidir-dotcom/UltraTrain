import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalFoodLogRepository Tests")
@MainActor
struct LocalFoodLogRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([FoodLogEntrySwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeEntry(
        id: UUID = UUID(),
        date: Date = Date(),
        mealType: MealType = .breakfast,
        description: String = "Oatmeal with banana",
        caloriesEstimate: Int? = 450
    ) -> FoodLogEntry {
        FoodLogEntry(
            id: id,
            date: date,
            mealType: mealType,
            description: description,
            caloriesEstimate: caloriesEstimate
        )
    }

    @Test("Save and get entries for date")
    func saveAndGetEntriesForDate() async throws {
        let container = try makeContainer()
        let repo = LocalFoodLogRepository(modelContainer: container)
        let today = Date()

        let entry = makeEntry(date: today, mealType: .breakfast)
        try await repo.saveEntry(entry)

        let results = try await repo.getEntries(for: today)
        #expect(results.count == 1)
        #expect(results.first?.mealType == .breakfast)
    }

    @Test("Get entries for date returns empty for different day")
    func getEntriesForDateReturnsEmptyForDifferentDay() async throws {
        let container = try makeContainer()
        let repo = LocalFoodLogRepository(modelContainer: container)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        try await repo.saveEntry(makeEntry(date: yesterday))

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let results = try await repo.getEntries(for: tomorrow)
        #expect(results.isEmpty)
    }

    @Test("Update entry replaces existing")
    func updateEntryReplacesExisting() async throws {
        let container = try makeContainer()
        let repo = LocalFoodLogRepository(modelContainer: container)
        let entryId = UUID()
        let today = Date()

        try await repo.saveEntry(makeEntry(id: entryId, date: today, description: "Original"))

        let updated = FoodLogEntry(
            id: entryId,
            date: today,
            mealType: .lunch,
            description: "Updated meal",
            caloriesEstimate: 600
        )
        try await repo.updateEntry(updated)

        let results = try await repo.getEntries(for: today)
        #expect(results.count == 1)
        #expect(results.first?.description == "Updated meal")
        #expect(results.first?.caloriesEstimate == 600)
    }

    @Test("Delete entry removes it")
    func deleteEntryRemovesIt() async throws {
        let container = try makeContainer()
        let repo = LocalFoodLogRepository(modelContainer: container)
        let entryId = UUID()
        let today = Date()

        try await repo.saveEntry(makeEntry(id: entryId, date: today))
        try await repo.deleteEntry(id: entryId)

        let results = try await repo.getEntries(for: today)
        #expect(results.isEmpty)
    }

    @Test("Get entries in date range returns matching entries")
    func getEntriesInDateRange() async throws {
        let container = try makeContainer()
        let repo = LocalFoodLogRepository(modelContainer: container)
        let now = Date()

        let entry1 = makeEntry(date: Calendar.current.date(byAdding: .day, value: -2, to: now)!)
        let entry2 = makeEntry(date: Calendar.current.date(byAdding: .day, value: -1, to: now)!)
        let entryOutOfRange = makeEntry(date: Calendar.current.date(byAdding: .day, value: -10, to: now)!)

        try await repo.saveEntry(entry1)
        try await repo.saveEntry(entry2)
        try await repo.saveEntry(entryOutOfRange)

        let startDate = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let results = try await repo.getEntries(from: startDate, to: now)
        #expect(results.count == 2)
    }

    @Test("Delete entry throws when not found")
    func deleteEntryThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalFoodLogRepository(modelContainer: container)

        await #expect(throws: DomainError.self) {
            try await repo.deleteEntry(id: UUID())
        }
    }
}
