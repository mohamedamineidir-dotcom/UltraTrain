import Foundation
@testable import UltraTrain

final class MockStravaUploadQueueRepository: StravaUploadQueueRepository, @unchecked Sendable {
    var items: [StravaUploadQueueItem] = []
    var shouldThrow = false

    func getPendingItems() async throws -> [StravaUploadQueueItem] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return items.filter { $0.status == .pending || $0.status == .failed }
    }

    func getItem(forRunId runId: UUID) async throws -> StravaUploadQueueItem? {
        items.first { $0.runId == runId }
    }

    func saveItem(_ item: StravaUploadQueueItem) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        items.append(item)
    }

    func updateItem(_ item: StravaUploadQueueItem) async throws {
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
}
