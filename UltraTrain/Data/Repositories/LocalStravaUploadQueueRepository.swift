import Foundation
import SwiftData
import os

final class LocalStravaUploadQueueRepository: StravaUploadQueueRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getPendingItems() async throws -> [StravaUploadQueueItem] {
        let context = ModelContext(modelContainer)
        let pendingRaw = StravaQueueItemStatus.pending.rawValue
        let failedRaw = StravaQueueItemStatus.failed.rawValue
        let descriptor = FetchDescriptor<StravaUploadQueueSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == pendingRaw || $0.statusRaw == failedRaw },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { StravaUploadQueueMapper.toDomain($0) }
    }

    func getItem(forRunId runId: UUID) async throws -> StravaUploadQueueItem? {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<StravaUploadQueueSwiftDataModel>(
            predicate: #Predicate { $0.runId == runId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return nil }
        return StravaUploadQueueMapper.toDomain(model)
    }

    func saveItem(_ item: StravaUploadQueueItem) async throws {
        let context = ModelContext(modelContainer)
        let model = StravaUploadQueueMapper.toSwiftData(item)
        context.insert(model)
        try context.save()
        Logger.strava.info("Queue item saved for run \(item.runId)")
    }

    func updateItem(_ item: StravaUploadQueueItem) async throws {
        let context = ModelContext(modelContainer)
        let targetId = item.id
        var descriptor = FetchDescriptor<StravaUploadQueueSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return }
        model.statusRaw = item.status.rawValue
        model.retryCount = item.retryCount
        model.lastAttempt = item.lastAttempt
        model.stravaActivityId = item.stravaActivityId
        model.errorMessage = item.errorMessage
        model.updatedAt = Date()
        try context.save()
    }

    func deleteItem(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<StravaUploadQueueSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return }
        context.delete(model)
        try context.save()
    }

    func getPendingCount() async throws -> Int {
        let context = ModelContext(modelContainer)
        let pendingRaw = StravaQueueItemStatus.pending.rawValue
        let failedRaw = StravaQueueItemStatus.failed.rawValue
        let descriptor = FetchDescriptor<StravaUploadQueueSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == pendingRaw || $0.statusRaw == failedRaw }
        )
        return try context.fetchCount(descriptor)
    }
}
