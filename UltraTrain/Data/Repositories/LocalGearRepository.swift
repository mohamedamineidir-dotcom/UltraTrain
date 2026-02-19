import Foundation
import SwiftData
import os

final class LocalGearRepository: GearRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getGearItems() async throws -> [GearItem] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<GearItemSwiftDataModel>(
            sortBy: [SortDescriptor(\.name)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { GearItemSwiftDataMapper.toDomain($0) }
    }

    func getGearItem(id: UUID) async throws -> GearItem? {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<GearItemSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return nil }
        return GearItemSwiftDataMapper.toDomain(model)
    }

    func getActiveGear(ofType type: GearType?) async throws -> [GearItem] {
        let context = ModelContext(modelContainer)
        let descriptor: FetchDescriptor<GearItemSwiftDataModel>
        if let type {
            let typeRaw = type.rawValue
            descriptor = FetchDescriptor<GearItemSwiftDataModel>(
                predicate: #Predicate { $0.isRetired == false && $0.typeRaw == typeRaw },
                sortBy: [SortDescriptor(\.name)]
            )
        } else {
            descriptor = FetchDescriptor<GearItemSwiftDataModel>(
                predicate: #Predicate { $0.isRetired == false },
                sortBy: [SortDescriptor(\.name)]
            )
        }
        let results = try context.fetch(descriptor)
        return results.compactMap { GearItemSwiftDataMapper.toDomain($0) }
    }

    func saveGearItem(_ item: GearItem) async throws {
        let context = ModelContext(modelContainer)
        let model = GearItemSwiftDataMapper.toSwiftData(item)
        context.insert(model)
        try context.save()
        Logger.gear.info("Gear item saved: \(item.name)")
    }

    func updateGearItem(_ item: GearItem) async throws {
        let context = ModelContext(modelContainer)
        let targetId = item.id
        var descriptor = FetchDescriptor<GearItemSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.gearNotFound
        }

        existing.name = item.name
        existing.brand = item.brand
        existing.typeRaw = item.type.rawValue
        existing.purchaseDate = item.purchaseDate
        existing.maxDistanceKm = item.maxDistanceKm
        existing.totalDistanceKm = item.totalDistanceKm
        existing.totalDuration = item.totalDuration
        existing.isRetired = item.isRetired
        existing.notes = item.notes
        existing.updatedAt = Date()

        try context.save()
        Logger.gear.info("Gear item updated: \(item.name)")
    }

    func deleteGearItem(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<GearItemSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            throw DomainError.gearNotFound
        }

        context.delete(model)
        try context.save()
        Logger.gear.info("Gear item deleted: \(targetId)")
    }

    func updateGearMileage(gearIds: [UUID], distanceKm: Double, duration: TimeInterval) async throws {
        guard !gearIds.isEmpty else { return }
        let context = ModelContext(modelContainer)

        for gearId in gearIds {
            let targetId = gearId
            var descriptor = FetchDescriptor<GearItemSwiftDataModel>(
                predicate: #Predicate { $0.id == targetId }
            )
            descriptor.fetchLimit = 1

            guard let model = try context.fetch(descriptor).first else { continue }
            model.totalDistanceKm += distanceKm
            model.totalDuration += duration
            model.updatedAt = Date()
        }

        try context.save()
        Logger.gear.info("Updated mileage for \(gearIds.count) gear item(s): +\(String(format: "%.1f", distanceKm)) km")
    }
}
