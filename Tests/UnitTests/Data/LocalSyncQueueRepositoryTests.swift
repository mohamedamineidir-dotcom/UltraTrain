import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalSyncQueueRepository Tests")
@MainActor
struct LocalSyncQueueRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            SyncQueueSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeItem(
        id: UUID = UUID(),
        runId: UUID = UUID(),
        operationType: SyncOperationType = .runUpload,
        entityId: UUID = UUID(),
        status: SyncQueueItemStatus = .pending,
        retryCount: Int = 0,
        lastAttempt: Date? = nil,
        errorMessage: String? = nil,
        createdAt: Date = Date()
    ) -> SyncQueueItem {
        SyncQueueItem(
            id: id,
            runId: runId,
            operationType: operationType,
            entityId: entityId,
            status: status,
            retryCount: retryCount,
            lastAttempt: lastAttempt,
            errorMessage: errorMessage,
            createdAt: createdAt
        )
    }

    // MARK: - Save & Fetch

    @Test("Save item and fetch by run ID returns the saved item")
    func saveAndFetchByRunId() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)
        let runId = UUID()
        let item = makeItem(runId: runId)

        try await repo.saveItem(item)
        let fetched = try await repo.getItem(forRunId: runId)

        #expect(fetched != nil)
        #expect(fetched?.id == item.id)
        #expect(fetched?.runId == runId)
        #expect(fetched?.status == .pending)
        #expect(fetched?.operationType == .runUpload)
    }

    @Test("Fetch item for nonexistent run ID returns nil")
    func fetchNonexistentRunIdReturnsNil() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        let fetched = try await repo.getItem(forRunId: UUID())
        #expect(fetched == nil)
    }

    // MARK: - Get Pending Items

    @Test("Get pending items returns items with pending or failed status sorted by createdAt")
    func getPendingItemsReturnsPendingAndFailed() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        let oldest = Date(timeIntervalSince1970: 1_000_000)
        let middle = Date(timeIntervalSince1970: 2_000_000)
        let newest = Date(timeIntervalSince1970: 3_000_000)
        let evenNewer = Date(timeIntervalSince1970: 4_000_000)

        let pendingItem = makeItem(status: .pending, createdAt: oldest)
        let failedItem = makeItem(status: .failed, createdAt: middle)
        let completedItem = makeItem(status: .completed, createdAt: newest)
        let uploadingItem = makeItem(status: .uploading, createdAt: evenNewer)

        try await repo.saveItem(pendingItem)
        try await repo.saveItem(failedItem)
        try await repo.saveItem(completedItem)
        try await repo.saveItem(uploadingItem)

        let pending = try await repo.getPendingItems()

        // Should include pending and failed only (not completed or uploading)
        #expect(pending.count == 2)
        // Sorted by createdAt ascending
        #expect(pending[0].id == pendingItem.id)
        #expect(pending[1].id == failedItem.id)
    }

    @Test("Get pending items when none exist returns empty array")
    func getPendingItemsEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        let pending = try await repo.getPendingItems()
        #expect(pending.isEmpty)
    }

    // MARK: - Get Failed Items

    @Test("Get failed items returns only items with failed status")
    func getFailedItemsReturnsOnlyFailed() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        let pendingItem = makeItem(status: .pending, createdAt: Date(timeIntervalSince1970: 1_000_000))
        let failedItem1 = makeItem(status: .failed, createdAt: Date(timeIntervalSince1970: 3_000_000))
        let failedItem2 = makeItem(status: .failed, createdAt: Date(timeIntervalSince1970: 2_000_000))
        let completedItem = makeItem(status: .completed, createdAt: Date(timeIntervalSince1970: 4_000_000))

        try await repo.saveItem(pendingItem)
        try await repo.saveItem(failedItem1)
        try await repo.saveItem(failedItem2)
        try await repo.saveItem(completedItem)

        let failed = try await repo.getFailedItems()

        #expect(failed.count == 2)
        // Sorted by createdAt descending (newest first)
        #expect(failed[0].id == failedItem1.id)
        #expect(failed[1].id == failedItem2.id)
    }

    @Test("Get failed items when none failed returns empty array")
    func getFailedItemsWhenNoneFailed() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        let pendingItem = makeItem(status: .pending)
        try await repo.saveItem(pendingItem)

        let failed = try await repo.getFailedItems()
        #expect(failed.isEmpty)
    }

    // MARK: - Counts

    @Test("Get pending count returns count of pending and uploading items")
    func getPendingCountIncludesPendingAndUploading() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        try await repo.saveItem(makeItem(status: .pending))
        try await repo.saveItem(makeItem(status: .pending))
        try await repo.saveItem(makeItem(status: .uploading))
        try await repo.saveItem(makeItem(status: .failed))
        try await repo.saveItem(makeItem(status: .completed))

        let count = try await repo.getPendingCount()
        #expect(count == 3)
    }

    @Test("Get failed count returns count of failed items only")
    func getFailedCountReturnsOnlyFailed() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        try await repo.saveItem(makeItem(status: .pending))
        try await repo.saveItem(makeItem(status: .failed))
        try await repo.saveItem(makeItem(status: .failed))
        try await repo.saveItem(makeItem(status: .completed))

        let count = try await repo.getFailedCount()
        #expect(count == 2)
    }

    @Test("Get pending count on empty repo returns zero")
    func getPendingCountEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        let count = try await repo.getPendingCount()
        #expect(count == 0)
    }

    @Test("Get failed count on empty repo returns zero")
    func getFailedCountEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        let count = try await repo.getFailedCount()
        #expect(count == 0)
    }

    // MARK: - Update

    @Test("Update item modifies status, retry count, and error message")
    func updateItemModifiesFields() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)
        let itemId = UUID()
        let runId = UUID()

        let original = makeItem(id: itemId, runId: runId, status: .pending, retryCount: 0)
        try await repo.saveItem(original)

        let attemptDate = Date()
        let updated = SyncQueueItem(
            id: itemId,
            runId: runId,
            operationType: .runUpload,
            entityId: original.entityId,
            status: .failed,
            retryCount: 3,
            lastAttempt: attemptDate,
            errorMessage: "Network timeout",
            createdAt: original.createdAt
        )
        try await repo.updateItem(updated)

        let fetched = try await repo.getItem(forRunId: runId)
        #expect(fetched?.status == .failed)
        #expect(fetched?.retryCount == 3)
        #expect(fetched?.errorMessage == "Network timeout")
        #expect(fetched?.lastAttempt != nil)
    }

    @Test("Update nonexistent item does not throw")
    func updateNonexistentItemNoThrow() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)
        let item = makeItem()

        // Should not throw - just silently returns
        try await repo.updateItem(item)
    }

    // MARK: - Delete

    @Test("Delete item removes it from the store")
    func deleteItem() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)
        let runId = UUID()
        let item = makeItem(runId: runId)

        try await repo.saveItem(item)
        let beforeDelete = try await repo.getItem(forRunId: runId)
        #expect(beforeDelete != nil)

        try await repo.deleteItem(id: item.id)
        let afterDelete = try await repo.getItem(forRunId: runId)
        #expect(afterDelete == nil)
    }

    @Test("Delete nonexistent item does not throw")
    func deleteNonexistentItemNoThrow() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        // Should not throw when item doesn't exist
        try await repo.deleteItem(id: UUID())
    }

    @Test("Delete only removes targeted item leaving others intact")
    func deleteOnlyTargetedItem() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        let item1 = makeItem(status: .pending)
        let item2 = makeItem(status: .pending)
        try await repo.saveItem(item1)
        try await repo.saveItem(item2)

        try await repo.deleteItem(id: item1.id)

        let remaining = try await repo.getPendingItems()
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == item2.id)
    }

    // MARK: - Operation Types

    @Test("Different operation types are preserved through save and fetch")
    func operationTypesPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalSyncQueueRepository(modelContainer: container)

        let runId1 = UUID()
        let runId2 = UUID()
        let runId3 = UUID()

        try await repo.saveItem(makeItem(runId: runId1, operationType: .runUpload))
        try await repo.saveItem(makeItem(runId: runId2, operationType: .raceSync))
        try await repo.saveItem(makeItem(runId: runId3, operationType: .trainingPlanSync))

        let item1 = try await repo.getItem(forRunId: runId1)
        let item2 = try await repo.getItem(forRunId: runId2)
        let item3 = try await repo.getItem(forRunId: runId3)

        #expect(item1?.operationType == .runUpload)
        #expect(item2?.operationType == .raceSync)
        #expect(item3?.operationType == .trainingPlanSync)
    }
}
