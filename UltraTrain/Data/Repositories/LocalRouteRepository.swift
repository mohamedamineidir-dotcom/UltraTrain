import Foundation
import SwiftData
import os

final class LocalRouteRepository: RouteRepository, @unchecked Sendable {

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getRoutes() async throws -> [SavedRoute] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<SavedRouteSwiftDataModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let models = try context.fetch(descriptor)
        return models.compactMap(SavedRouteSwiftDataMapper.toDomain)
    }

    func getRoute(id: UUID) async throws -> SavedRoute? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<SavedRouteSwiftDataModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else { return nil }
        return SavedRouteSwiftDataMapper.toDomain(model)
    }

    func saveRoute(_ route: SavedRoute) async throws {
        let context = ModelContext(modelContainer)
        let model = SavedRouteSwiftDataMapper.toSwiftData(route)
        context.insert(model)
        try context.save()
        Logger.persistence.info("Saved route '\(route.name)' with \(route.courseRoute.count) points")
    }

    func updateRoute(_ route: SavedRoute) async throws {
        let context = ModelContext(modelContainer)
        let routeId = route.id
        let descriptor = FetchDescriptor<SavedRouteSwiftDataModel>(
            predicate: #Predicate { $0.id == routeId }
        )

        guard let existing = try context.fetch(descriptor).first else {
            throw DomainError.routeNotFound
        }

        existing.name = route.name
        existing.distanceKm = route.distanceKm
        existing.elevationGainM = route.elevationGainM
        existing.elevationLossM = route.elevationLossM
        existing.trackPointsData = SavedRouteSwiftDataMapper.toSwiftData(route).trackPointsData
        existing.courseRouteData = SavedRouteSwiftDataMapper.toSwiftData(route).courseRouteData
        existing.checkpointsData = SavedRouteSwiftDataMapper.toSwiftData(route).checkpointsData
        existing.notes = route.notes
        existing.updatedAt = Date()
        try context.save()
    }

    func deleteRoute(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<SavedRouteSwiftDataModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else { return }
        context.delete(model)
        try context.save()
        Logger.persistence.info("Deleted route \(id)")
    }
}
