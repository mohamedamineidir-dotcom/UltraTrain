import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalAchievementRepository Tests")
@MainActor
struct LocalAchievementRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([UnlockedAchievementSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeAchievement(
        id: UUID = UUID(),
        achievementId: String = "first_50k",
        unlockedDate: Date = Date()
    ) -> UnlockedAchievement {
        UnlockedAchievement(
            id: id,
            achievementId: achievementId,
            unlockedDate: unlockedDate
        )
    }

    @Test("Save and fetch unlocked achievements")
    func saveAndFetchUnlockedAchievements() async throws {
        let container = try makeContainer()
        let repo = LocalAchievementRepository(modelContainer: container)

        let achievement = makeAchievement(achievementId: "first_ultra")
        try await repo.saveUnlocked(achievement)

        let results = try await repo.getUnlockedAchievements()
        #expect(results.count == 1)
        #expect(results.first?.achievementId == "first_ultra")
    }

    @Test("Get unlocked achievements returns empty when none saved")
    func getUnlockedAchievementsReturnsEmptyWhenNone() async throws {
        let container = try makeContainer()
        let repo = LocalAchievementRepository(modelContainer: container)

        let results = try await repo.getUnlockedAchievements()
        #expect(results.isEmpty)
    }

    @Test("isUnlocked returns true for saved achievement")
    func isUnlockedReturnsTrueForSaved() async throws {
        let container = try makeContainer()
        let repo = LocalAchievementRepository(modelContainer: container)

        try await repo.saveUnlocked(makeAchievement(achievementId: "100_miles"))

        let unlocked = try await repo.isUnlocked(achievementId: "100_miles")
        #expect(unlocked == true)
    }

    @Test("isUnlocked returns false for unsaved achievement")
    func isUnlockedReturnsFalseForUnsaved() async throws {
        let container = try makeContainer()
        let repo = LocalAchievementRepository(modelContainer: container)

        let unlocked = try await repo.isUnlocked(achievementId: "nonexistent")
        #expect(unlocked == false)
    }

    @Test("Achievements returned in reverse date order")
    func achievementsReturnedInReverseDateOrder() async throws {
        let container = try makeContainer()
        let repo = LocalAchievementRepository(modelContainer: container)

        let older = makeAchievement(
            achievementId: "older",
            unlockedDate: Date.now.addingTimeInterval(-3600)
        )
        let newer = makeAchievement(
            achievementId: "newer",
            unlockedDate: Date.now
        )

        try await repo.saveUnlocked(older)
        try await repo.saveUnlocked(newer)

        let results = try await repo.getUnlockedAchievements()
        #expect(results.count == 2)
        #expect(results[0].achievementId == "newer")
        #expect(results[1].achievementId == "older")
    }
}
