import Foundation
import SwiftData

@Model
final class ChecklistItemSwiftDataModel {
    var id: UUID = UUID()
    var name: String = ""
    var categoryRaw: String = ""
    var isChecked: Bool = false
    var isCustom: Bool = false
    var notes: String? = nil
    var checklist: RacePrepChecklistSwiftDataModel?

    init(
        id: UUID = UUID(),
        name: String = "",
        categoryRaw: String = "",
        isChecked: Bool = false,
        isCustom: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = categoryRaw
        self.isChecked = isChecked
        self.isCustom = isCustom
        self.notes = notes
    }
}
