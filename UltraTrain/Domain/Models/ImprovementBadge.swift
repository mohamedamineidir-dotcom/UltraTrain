import Foundation

struct ImprovementBadge: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var description: String
    var icon: String
}
