import Foundation

struct CoachingInsight: Identifiable, Equatable, Sendable {
    let id: UUID
    var type: CoachingInsightType
    var category: InsightCategory
    var title: String
    var message: String
    var icon: String
}
