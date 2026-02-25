import Foundation

struct RacePrepChecklist: Identifiable, Equatable, Sendable {
    let id: UUID
    var raceId: UUID
    var items: [ChecklistItem]
    var createdAt: Date
    var lastModified: Date
}
