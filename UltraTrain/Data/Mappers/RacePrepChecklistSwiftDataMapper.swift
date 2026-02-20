import Foundation

enum RacePrepChecklistSwiftDataMapper {

    static func toDomain(_ model: RacePrepChecklistSwiftDataModel) -> RacePrepChecklist {
        RacePrepChecklist(
            id: model.id,
            raceId: model.raceId,
            items: model.items.map { itemToDomain($0) },
            createdAt: model.createdAt,
            lastModified: model.lastModified
        )
    }

    static func toSwiftData(_ checklist: RacePrepChecklist) -> RacePrepChecklistSwiftDataModel {
        let model = RacePrepChecklistSwiftDataModel(
            id: checklist.id,
            raceId: checklist.raceId,
            createdAt: checklist.createdAt,
            lastModified: checklist.lastModified
        )
        model.items = checklist.items.map { itemToSwiftData($0) }
        return model
    }

    private static func itemToDomain(_ model: ChecklistItemSwiftDataModel) -> ChecklistItem {
        ChecklistItem(
            id: model.id,
            name: model.name,
            category: ChecklistCategory(rawValue: model.categoryRaw) ?? .gear,
            isChecked: model.isChecked,
            isCustom: model.isCustom,
            notes: model.notes
        )
    }

    private static func itemToSwiftData(_ item: ChecklistItem) -> ChecklistItemSwiftDataModel {
        ChecklistItemSwiftDataModel(
            id: item.id,
            name: item.name,
            categoryRaw: item.category.rawValue,
            isChecked: item.isChecked,
            isCustom: item.isCustom,
            notes: item.notes
        )
    }
}
