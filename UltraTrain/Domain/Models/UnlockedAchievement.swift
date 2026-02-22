import Foundation

struct UnlockedAchievement: Identifiable, Equatable, Sendable {
    let id: UUID
    var achievementId: String
    var unlockedDate: Date
}
