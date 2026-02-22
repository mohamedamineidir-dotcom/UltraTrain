import Foundation

struct Achievement: Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    var descriptionText: String
    var iconName: String
    var category: AchievementCategory
    var requirement: AchievementRequirement
}
