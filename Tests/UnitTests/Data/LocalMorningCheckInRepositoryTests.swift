import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalMorningCheckInRepository Tests")
@MainActor
struct LocalMorningCheckInRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([MorningCheckInSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeCheckIn(
        id: UUID = UUID(),
        date: Date = Date(),
        perceivedEnergy: Int = 7,
        muscleSoreness: Int = 3,
        mood: Int = 8,
        sleepQualitySubjective: Int = 7,
        notes: String? = nil
    ) -> MorningCheckIn {
        MorningCheckIn(
            id: id,
            date: date,
            perceivedEnergy: perceivedEnergy,
            muscleSoreness: muscleSoreness,
            mood: mood,
            sleepQualitySubjective: sleepQualitySubjective,
            notes: notes
        )
    }

    @Test("Save and get check-in for date")
    func saveAndGetCheckInForDate() async throws {
        let container = try makeContainer()
        let repo = LocalMorningCheckInRepository(modelContainer: container)
        let today = Date()

        let checkIn = makeCheckIn(date: today, perceivedEnergy: 8)
        try await repo.saveCheckIn(checkIn)

        let fetched = try await repo.getCheckIn(for: today)
        #expect(fetched != nil)
        #expect(fetched?.perceivedEnergy == 8)
    }

    @Test("Get check-in returns nil for date without check-in")
    func getCheckInReturnsNilForDateWithout() async throws {
        let container = try makeContainer()
        let repo = LocalMorningCheckInRepository(modelContainer: container)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let fetched = try await repo.getCheckIn(for: tomorrow)
        #expect(fetched == nil)
    }

    @Test("Save check-in updates existing with same ID")
    func saveCheckInUpdatesExistingWithSameId() async throws {
        let container = try makeContainer()
        let repo = LocalMorningCheckInRepository(modelContainer: container)
        let checkInId = UUID()
        let today = Date()

        let original = makeCheckIn(id: checkInId, date: today, perceivedEnergy: 5)
        try await repo.saveCheckIn(original)

        let updated = makeCheckIn(id: checkInId, date: today, perceivedEnergy: 9)
        try await repo.saveCheckIn(updated)

        let fetched = try await repo.getCheckIn(for: today)
        #expect(fetched?.perceivedEnergy == 9)
    }

    @Test("Get check-ins in date range returns matching entries")
    func getCheckInsInDateRange() async throws {
        let container = try makeContainer()
        let repo = LocalMorningCheckInRepository(modelContainer: container)
        let now = Date()

        let checkIn1 = makeCheckIn(date: Calendar.current.date(byAdding: .day, value: -2, to: now)!)
        let checkIn2 = makeCheckIn(date: Calendar.current.date(byAdding: .day, value: -1, to: now)!)
        let outOfRange = makeCheckIn(date: Calendar.current.date(byAdding: .day, value: -10, to: now)!)

        try await repo.saveCheckIn(checkIn1)
        try await repo.saveCheckIn(checkIn2)
        try await repo.saveCheckIn(outOfRange)

        let startDate = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let results = try await repo.getCheckIns(from: startDate, to: now)
        #expect(results.count == 2)
    }

    @Test("Check-ins in date range are sorted by date ascending")
    func checkInsInDateRangeSortedAscending() async throws {
        let container = try makeContainer()
        let repo = LocalMorningCheckInRepository(modelContainer: container)
        let now = Date()

        let older = makeCheckIn(
            date: Calendar.current.date(byAdding: .day, value: -3, to: now)!,
            perceivedEnergy: 5
        )
        let newer = makeCheckIn(
            date: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
            perceivedEnergy: 8
        )

        try await repo.saveCheckIn(newer)
        try await repo.saveCheckIn(older)

        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: now)!
        let results = try await repo.getCheckIns(from: startDate, to: now)
        #expect(results.count == 2)
        #expect(results[0].perceivedEnergy == 5)
        #expect(results[1].perceivedEnergy == 8)
    }
}
