import Testing
import Foundation
@testable import UltraTrain

@Suite("SyncStatusMonitor")
@MainActor
struct SyncStatusMonitorTests {

    @Test("refresh updates pending and failed counts")
    func refreshUpdatesCounts() async {
        let mock = MockSyncQueueService()
        mock.stubbedPendingCount = 5
        mock.stubbedFailedCount = 2

        let monitor = SyncStatusMonitor(syncQueueService: mock)
        await monitor.refresh()

        #expect(monitor.pendingCount == 5)
        #expect(monitor.failedCount == 2)
    }

    @Test("isVisible true when pending items exist")
    func isVisibleWhenPending() async {
        let mock = MockSyncQueueService()
        mock.stubbedPendingCount = 1
        mock.stubbedFailedCount = 0

        let monitor = SyncStatusMonitor(syncQueueService: mock)
        await monitor.refresh()

        #expect(monitor.isVisible)
        #expect(monitor.hasPending)
    }

    @Test("isVisible false when all synced")
    func isVisibleFalseWhenSynced() async {
        let mock = MockSyncQueueService()
        mock.stubbedPendingCount = 0
        mock.stubbedFailedCount = 0

        let monitor = SyncStatusMonitor(syncQueueService: mock)
        await monitor.refresh()

        #expect(!monitor.isVisible)
        #expect(!monitor.hasPending)
        #expect(!monitor.hasFailures)
    }

    @Test("hasFailures true when failed count greater than zero")
    func hasFailuresWhenFailed() async {
        let mock = MockSyncQueueService()
        mock.stubbedPendingCount = 0
        mock.stubbedFailedCount = 3

        let monitor = SyncStatusMonitor(syncQueueService: mock)
        await monitor.refresh()

        #expect(monitor.hasFailures)
        #expect(monitor.isVisible)
    }

    @Test("isSyncing set when pending count is positive")
    func isSyncingWhenPending() async {
        let mock = MockSyncQueueService()
        mock.stubbedPendingCount = 2
        mock.stubbedFailedCount = 0

        let monitor = SyncStatusMonitor(syncQueueService: mock)
        await monitor.refresh()

        #expect(monitor.isSyncing)
    }
}
