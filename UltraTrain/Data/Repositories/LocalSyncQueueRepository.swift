import Foundation
import SwiftData
import os

final class LocalSyncQueueRepository: SyncQueueRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getPendingItems() async throws -> [SyncQueueItem] {
        let context = ModelContext(modelContainer)
        let pendingRaw = SyncQueueItemStatus.pending.rawValue
        let failedRaw = SyncQueueItemStatus.failed.rawValue
        let descriptor = FetchDescriptor<SyncQueueSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == pendingRaw || $0.statusRaw == failedRaw },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { SyncQueueMapper.toDomain($0) }
    }

    func getItem(forRunId runId: UUID) async throws -> SyncQueueItem? {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<SyncQueueSwiftDataModel>(
            predicate: #Predicate { $0.runId == runId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return nil }
        return SyncQueueMapper.toDomain(model)
    }

    func saveItem(_ item: SyncQueueItem) async throws {
        let context = ModelContext(modelContainer)
        let model = SyncQueueMapper.toSwiftData(item)
        context.insert(model)
        try context.save()
    }

    func updateItem(_ item: SyncQueueItem) async throws {
        let context = ModelContext(modelContainer)
        let targetId = item.id
        var descriptor = FetchDescriptor<SyncQueueSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return }
        model.statusRaw = item.status.rawValue
        model.retryCount = item.retryCount
        model.lastAttempt = item.lastAttempt
        model.errorMessage = item.errorMessage
        model.updatedAt = Date()
        try context.save()
    }

    func deleteItem(id: UUID) async throws {
        let context = ModelContext(modelContainer)
        let targetId = id
        var descriptor = FetchDescriptor<SyncQueueSwiftDataModel>(
            predicate: #Predicate { $0.id == targetId }
        )
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else { return }
        context.delete(model)
        try context.save()
    }

    func getPendingCount() async throws -> Int {
        let context = ModelContext(modelContainer)
        let pendingRaw = SyncQueueItemStatus.pending.rawValue
        let uploadingRaw = SyncQueueItemStatus.uploading.rawValue
        let descriptor = FetchDescriptor<SyncQueueSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == pendingRaw || $0.statusRaw == uploadingRaw }
        )
        return try context.fetchCount(descriptor)
    }

    func getFailedCount() async throws -> Int {
        let context = ModelContext(modelContainer)
        let failedRaw = SyncQueueItemStatus.failed.rawValue
        let descriptor = FetchDescriptor<SyncQueueSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == failedRaw }
        )
        return try context.fetchCount(descriptor)
    }

    func getFailedItems() async throws -> [SyncQueueItem] {
        let context = ModelContext(modelContainer)
        let failedRaw = SyncQueueItemStatus.failed.rawValue
        let descriptor = FetchDescriptor<SyncQueueSwiftDataModel>(
            predicate: #Predicate { $0.statusRaw == failedRaw },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return results.compactMap { SyncQueueMapper.toDomain($0) }
    }
}
