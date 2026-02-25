import Foundation

struct ChecklistItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var category: ChecklistCategory
    var isChecked: Bool
    var isCustom: Bool
    var notes: String?
}
