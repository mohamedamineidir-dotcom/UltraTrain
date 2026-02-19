import Foundation

enum GearItemSwiftDataMapper {

    static func toDomain(_ model: GearItemSwiftDataModel) -> GearItem? {
        guard let type = GearType(rawValue: model.typeRaw) else { return nil }
        return GearItem(
            id: model.id,
            name: model.name,
            brand: model.brand,
            type: type,
            purchaseDate: model.purchaseDate,
            maxDistanceKm: model.maxDistanceKm,
            totalDistanceKm: model.totalDistanceKm,
            totalDuration: model.totalDuration,
            isRetired: model.isRetired,
            notes: model.notes
        )
    }

    static func toSwiftData(_ item: GearItem) -> GearItemSwiftDataModel {
        GearItemSwiftDataModel(
            id: item.id,
            name: item.name,
            brand: item.brand,
            typeRaw: item.type.rawValue,
            purchaseDate: item.purchaseDate,
            maxDistanceKm: item.maxDistanceKm,
            totalDistanceKm: item.totalDistanceKm,
            totalDuration: item.totalDuration,
            isRetired: item.isRetired,
            notes: item.notes
        )
    }
}
