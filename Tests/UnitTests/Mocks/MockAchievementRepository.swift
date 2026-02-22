import Foundation
@testable import UltraTrain

final class MockAchievementRepository: AchievementRepository, @unchecked Sendable {
    var unlockedAchievements: [UnlockedAchievement] = []
    var saveCalledWith: [UnlockedAchievement] = []

    func getUnlockedAchievements() async throws -> [UnlockedAchievement] {
        unlockedAchievements
    }

    func saveUnlocked(_ achievement: UnlockedAchievement) async throws {
        saveCalledWith.append(achievement)
        unlockedAchievements.append(achievement)
    }

    func isUnlocked(achievementId: String) async throws -> Bool {
        unlockedAchievements.contains { $0.achievementId == achievementId }
    }
}
