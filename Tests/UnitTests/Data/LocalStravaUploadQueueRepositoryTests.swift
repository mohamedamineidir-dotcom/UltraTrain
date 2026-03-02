import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalStravaUploadQueueRepository Tests")
@MainActor
struct LocalStravaUploadQueueRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([StravaUploadQueueSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeItem(
        id: UUID = UUID(),
        runId: UUID = UUID(),
        status: StravaQueueItemStatus = .pending,
        retryCount: Int = 0
    ) -> StravaUploadQueueItem {
        StravaUploadQueueItem(
            id: id,
            runId: runId,
            status: status,
            retryCount: retryCount,
            lastAttempt: nil,
            stravaActivityId: nil,
            errorMessage: nil,
            createdAt: Date()
        )
    }

    @Test("Save and get pending items")
    func saveAndGetPendingItems() async throws {
        let container = try makeContainer()
        let repo = LocalStravaUploadQueueRepository(modelContainer: container)

        try await repo.saveItem(makeItem(status: .pending))
        try await repo.saveItem(makeItem(status: .completed))

        let pending = try await repo.getPendingItems()
        #expect(pending.count == 1)
    }

    @Test("Pending items include failed items")
    func pendingItemsIncludeFailedItems() async throws {
        let container = try makeContainer()
        let repo = LocalStravaUploadQueueRepository(modelContainer: container)

        try await repo.saveItem(makeItem(status: .pending))
        try await repo.saveItem(makeItem(status: .failed, retryCount: 1))

        let pending = try await repo.getPendingItems()
        #expect(pending.count == 2)
    }

    @Test("Get item by run ID returns matching item")
    func getItemByRunIdReturnsMatching() async throws {
        let container = try makeContainer()
        let repo = LocalStravaUploadQueueRepository(modelContainer: container)
        let runId = UUID()

        try await repo.saveItem(makeItem(runId: runId))

        let fetched = try await repo.getItem(forRunId: runId)
        #expect(fetched != nil)
        #expect(fetched?.runId == runId)
    }

    @Test("Update item modifies status and retry count")
    func updateItemModifiesStatusAndRetryCount() async throws {
        let container = try makeContainer()
        let repo = LocalStravaUploadQueueRepository(modelContainer: container)
        let itemId = UUID()

        try await repo.saveItem(makeItem(id: itemId, status: .pending, retryCount: 0))

        var updatedItem = StravaUploadQueueItem(
            id: itemId,
            runId: UUID(),
            status: .failed,
            retryCount: 1,
            lastAttempt: Date(),
            stravaActivityId: nil,
            errorMessage: "Upload timeout",
            createdAt: Date()
        )
        try await repo.updateItem(updatedItem)

        let pending = try await repo.getPendingItems()
        let found = pending.first { $0.id == itemId }
        #expect(found?.status == .failed)
        #expect(found?.retryCount == 1)
        #expect(found?.errorMessage == "Upload timeout")
    }

    @Test("Delete item removes it")
    func deleteItemRemovesIt() async throws {
        let container = try makeContainer()
        let repo = LocalStravaUploadQueueRepository(modelContainer: container)
        let itemId = UUID()

        try await repo.saveItem(makeItem(id: itemId))
        try await repo.deleteItem(id: itemId)

        let count = try await repo.getPendingCount()
        #expect(count == 0)
    }

    @Test("Get pending count returns correct number")
    func getPendingCountReturnsCorrectNumber() async throws {
        let container = try makeContainer()
        let repo = LocalStravaUploadQueueRepository(modelContainer: container)

        try await repo.saveItem(makeItem(status: .pending))
        try await repo.saveItem(makeItem(status: .failed))
        try await repo.saveItem(makeItem(status: .completed))

        let count = try await repo.getPendingCount()
        #expect(count == 2)
    }
}
