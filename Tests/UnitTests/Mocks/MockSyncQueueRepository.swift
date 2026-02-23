import Foundation
@testable import UltraTrain

final class MockSyncQueueRepository: SyncQueueRepository, @unchecked Sendable {
    var items: [SyncQueueItem] = []
    var shouldThrow = false

    func getPendingItems() async throws -> [SyncQueueItem] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return items.filter { $0.status == .pending || $0.status == .failed }
    }

    func getItem(forRunId runId: UUID) async throws -> SyncQueueItem? {
        items.first { $0.runId == runId }
    }

    func saveItem(_ item: SyncQueueItem) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        items.append(item)
    }

    func updateItem(_ item: SyncQueueItem) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }

    func deleteItem(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }

    func getPendingCount() async throws -> Int {
        items.filter { $0.status == .pending || $0.status == .failed }.count
    }

    func getFailedCount() async throws -> Int {
        items.filter { $0.status == .failed }.count
    }

    func getFailedItems() async throws -> [SyncQueueItem] {
        items.filter { $0.status == .failed }
    }
}
