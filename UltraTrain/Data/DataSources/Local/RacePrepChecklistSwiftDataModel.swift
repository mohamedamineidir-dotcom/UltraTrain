import Foundation
import SwiftData

@Model
final class RacePrepChecklistSwiftDataModel {
    var id: UUID = UUID()
    var raceId: UUID = UUID()
    var createdAt: Date = Date.distantPast
    var lastModified: Date = Date.distantPast
    @Relationship(deleteRule: .cascade, inverse: \ChecklistItemSwiftDataModel.checklist)
    var items: [ChecklistItemSwiftDataModel] = []

    init(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        createdAt: Date = Date.distantPast,
        lastModified: Date = Date.distantPast,
        items: [ChecklistItemSwiftDataModel] = []
    ) {
        self.id = id
        self.raceId = raceId
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.items = items
    }
}
