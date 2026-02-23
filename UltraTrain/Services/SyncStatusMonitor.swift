import Foundation
import os

@Observable
final class SyncStatusMonitor: @unchecked Sendable {
    private(set) var pendingCount: Int = 0
    private(set) var failedCount: Int = 0
    private(set) var isSyncing: Bool = false

    var hasFailures: Bool { failedCount > 0 }
    var hasPending: Bool { pendingCount > 0 || isSyncing }
    var isVisible: Bool { hasPending || hasFailures }

    private let syncQueueService: any SyncQueueServiceProtocol

    init(syncQueueService: any SyncQueueServiceProtocol) {
        self.syncQueueService = syncQueueService
    }

    @MainActor
    func refresh() async {
        pendingCount = await syncQueueService.getPendingCount()
        failedCount = await syncQueueService.getFailedCount()
        isSyncing = pendingCount > 0
    }
}
