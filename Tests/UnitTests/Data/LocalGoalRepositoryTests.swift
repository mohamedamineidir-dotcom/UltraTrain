import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalGoalRepository Tests")
@MainActor
struct LocalGoalRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([TrainingGoalSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeGoal(
        id: UUID = UUID(),
        period: GoalPeriod = .weekly,
        distanceKm: Double = 50,
        startDate: Date = Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
        endDate: Date = Calendar.current.date(byAdding: .day, value: 4, to: .now)!
    ) -> TrainingGoal {
        TrainingGoal(
            id: id,
            period: period,
            targetDistanceKm: distanceKm,
            startDate: startDate,
            endDate: endDate
        )
    }

    @Test("Save and retrieve active goal")
    func saveAndRetrieveActive() async throws {
        let container = try makeContainer()
        let repo = LocalGoalRepository(modelContainer: container)
        let goal = makeGoal()

        try await repo.saveGoal(goal)
        let active = try await repo.getActiveGoal(period: .weekly)

        #expect(active != nil)
        #expect(active?.id == goal.id)
        #expect(active?.targetDistanceKm == 50)
    }

    @Test("Active goal returns nil for expired goals")
    func activeGoalReturnsNilForExpired() async throws {
        let container = try makeContainer()
        let repo = LocalGoalRepository(modelContainer: container)
        let expired = makeGoal(
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: .now)!,
            endDate: Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        )

        try await repo.saveGoal(expired)
        let active = try await repo.getActiveGoal(period: .weekly)
        #expect(active == nil)
    }

    @Test("Goal history returns goals sorted by end date descending")
    func goalHistorySortedDescending() async throws {
        let container = try makeContainer()
        let repo = LocalGoalRepository(modelContainer: container)

        let older = makeGoal(
            period: .weekly,
            startDate: Calendar.current.date(byAdding: .day, value: -21, to: .now)!,
            endDate: Calendar.current.date(byAdding: .day, value: -14, to: .now)!
        )
        let newer = makeGoal(
            period: .weekly,
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: .now)!,
            endDate: Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        )

        try await repo.saveGoal(older)
        try await repo.saveGoal(newer)

        let history = try await repo.getGoalHistory(period: .weekly, limit: 10)
        #expect(history.count == 2)
        #expect(history.first?.endDate ?? .distantPast > history.last?.endDate ?? .distantFuture)
    }

    @Test("Goal history respects limit")
    func goalHistoryRespectsLimit() async throws {
        let container = try makeContainer()
        let repo = LocalGoalRepository(modelContainer: container)

        for i in 0..<5 {
            let goal = makeGoal(
                startDate: Calendar.current.date(byAdding: .day, value: -(i + 1) * 7, to: .now)!,
                endDate: Calendar.current.date(byAdding: .day, value: -i * 7, to: .now)!
            )
            try await repo.saveGoal(goal)
        }

        let limited = try await repo.getGoalHistory(period: .weekly, limit: 3)
        #expect(limited.count == 3)
    }

    @Test("Goal history filters by period")
    func goalHistoryFiltersByPeriod() async throws {
        let container = try makeContainer()
        let repo = LocalGoalRepository(modelContainer: container)

        try await repo.saveGoal(makeGoal(period: .weekly))
        try await repo.saveGoal(makeGoal(period: .monthly))

        let weeklyHistory = try await repo.getGoalHistory(period: .weekly, limit: 10)
        let monthlyHistory = try await repo.getGoalHistory(period: .monthly, limit: 10)

        #expect(weeklyHistory.count == 1)
        #expect(monthlyHistory.count == 1)
    }

    @Test("Delete goal removes it")
    func deleteGoalRemovesIt() async throws {
        let container = try makeContainer()
        let repo = LocalGoalRepository(modelContainer: container)
        let goal = makeGoal()

        try await repo.saveGoal(goal)
        try await repo.deleteGoal(id: goal.id)

        let active = try await repo.getActiveGoal(period: .weekly)
        #expect(active == nil)
    }

    @Test("Delete nonexistent goal throws error")
    func deleteNonexistentGoalThrows() async throws {
        let container = try makeContainer()
        let repo = LocalGoalRepository(modelContainer: container)

        await #expect(throws: (any Error).self) {
            try await repo.deleteGoal(id: UUID())
        }
    }
}
