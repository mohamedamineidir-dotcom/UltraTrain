import Foundation
import SwiftData

final class LocalAchievementRepository: AchievementRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getUnlockedAchievements() async throws -> [UnlockedAchievement] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<UnlockedAchievementSwiftDataModel>(
            sortBy: [SortDescriptor(\.unlockedDate, order: .reverse)]
        )
        let models = try context.fetch(descriptor)
        return models.map(UnlockedAchievementMapper.toDomain)
    }

    func saveUnlocked(_ achievement: UnlockedAchievement) async throws {
        let context = ModelContext(modelContainer)
        let model = UnlockedAchievementMapper.toSwiftData(achievement)
        context.insert(model)
        try context.save()
    }

    func isUnlocked(achievementId: String) async throws -> Bool {
        let context = ModelContext(modelContainer)
        let id = achievementId
        let descriptor = FetchDescriptor<UnlockedAchievementSwiftDataModel>(
            predicate: #Predicate { $0.achievementId == id }
        )
        let count = try context.fetchCount(descriptor)
        return count > 0
    }
}
