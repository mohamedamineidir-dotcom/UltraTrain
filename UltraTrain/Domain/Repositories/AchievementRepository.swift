import Foundation

protocol AchievementRepository: Sendable {
    func getUnlockedAchievements() async throws -> [UnlockedAchievement]
    func saveUnlocked(_ achievement: UnlockedAchievement) async throws
    func isUnlocked(achievementId: String) async throws -> Bool
}
