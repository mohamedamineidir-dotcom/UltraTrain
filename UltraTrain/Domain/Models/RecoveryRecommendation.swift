import Foundation

struct RecoveryRecommendation: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var description: String
    var iconName: String
    var priority: RecommendationPriority
}
