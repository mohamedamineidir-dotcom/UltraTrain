import Foundation

enum UnlockedAchievementMapper {

    static func toDomain(_ model: UnlockedAchievementSwiftDataModel) -> UnlockedAchievement {
        UnlockedAchievement(
            id: model.id,
            achievementId: model.achievementId,
            unlockedDate: model.unlockedDate
        )
    }

    static func toSwiftData(_ entity: UnlockedAchievement) -> UnlockedAchievementSwiftDataModel {
        UnlockedAchievementSwiftDataModel(
            id: entity.id,
            achievementId: entity.achievementId,
            unlockedDate: entity.unlockedDate
        )
    }
}
