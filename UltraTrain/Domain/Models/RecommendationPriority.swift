import Foundation

enum RecommendationPriority: String, Sendable, Comparable {
    case low
    case medium
    case high

    static func < (lhs: RecommendationPriority, rhs: RecommendationPriority) -> Bool {
        let order: [RecommendationPriority] = [.low, .medium, .high]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }
}
