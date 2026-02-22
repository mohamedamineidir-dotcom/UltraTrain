import Foundation
import SwiftData

@Model
final class UnlockedAchievementSwiftDataModel {
    var id: UUID = UUID()
    var achievementId: String = ""
    var unlockedDate: Date = Date.distantPast

    init(id: UUID = UUID(), achievementId: String = "", unlockedDate: Date = Date.distantPast) {
        self.id = id
        self.achievementId = achievementId
        self.unlockedDate = unlockedDate
    }
}
