import Foundation

struct RacePrepChecklist: Identifiable, Equatable, Sendable {
    let id: UUID
    var raceId: UUID
    var items: [ChecklistItem]
    var createdAt: Date
    var lastModified: Date
}

struct ChecklistItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var category: ChecklistCategory
    var isChecked: Bool
    var isCustom: Bool
    var notes: String?
}

enum ChecklistCategory: String, CaseIterable, Sendable {
    case gear
    case nutrition
    case clothing
    case safety
    case logistics
    case dropBag
}
