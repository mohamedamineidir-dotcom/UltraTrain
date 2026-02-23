import Foundation
import os

@Observable
@MainActor
final class SyncQueueViewModel {
    private let syncService: any SyncQueueServiceProtocol

    var pendingCount: Int = 0
    var failedItems: [SyncQueueItem] = []
    var isLoading = false
    var isRetrying = false
    var error: String?

    init(syncService: any SyncQueueServiceProtocol) {
        self.syncService = syncService
    }

    func load() async {
        isLoading = true
        pendingCount = await syncService.getPendingCount()
        failedItems = await syncService.getFailedItems()
        isLoading = false
    }

    func retryItem(_ item: SyncQueueItem) async {
        await syncService.retryItem(id: item.id)
        await load()
    }

    func discardItem(_ item: SyncQueueItem) async {
        await syncService.discardItem(id: item.id)
        await load()
    }

    func retryAll() async {
        isRetrying = true
        await syncService.retryAllFailed()
        await load()
        isRetrying = false
    }

    func discardAll() async {
        await syncService.discardAllFailed()
        await load()
    }
}
