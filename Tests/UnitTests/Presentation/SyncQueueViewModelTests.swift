import Testing
import Foundation
@testable import UltraTrain

@Suite("SyncQueueViewModel")
@MainActor
struct SyncQueueViewModelTests {

    private func makeItem(
        type: SyncOperationType = .runUpload,
        status: SyncQueueItemStatus = .failed,
        errorMessage: String? = "Test error"
    ) -> SyncQueueItem {
        SyncQueueItem(
            id: UUID(),
            runId: UUID(),
            operationType: type,
            entityId: UUID(),
            status: status,
            retryCount: 1,
            lastAttempt: .now,
            errorMessage: errorMessage,
            createdAt: .now
        )
    }

    @Test("load populates pending count and failed items")
    func loadPopulatesData() async {
        let mock = MockSyncQueueService()
        mock.stubbedPendingCount = 3
        mock.stubbedFailedItems = [makeItem(), makeItem()]

        let vm = SyncQueueViewModel(syncService: mock)
        await vm.load()

        #expect(vm.pendingCount == 3)
        #expect(vm.failedItems.count == 2)
        #expect(!vm.isLoading)
    }

    @Test("retryItem calls service and reloads")
    func retryItemCallsService() async {
        let mock = MockSyncQueueService()
        let item = makeItem()
        mock.stubbedFailedItems = [item]

        let vm = SyncQueueViewModel(syncService: mock)
        await vm.retryItem(item)

        #expect(mock.retryItemCallCount == 1)
    }

    @Test("discardItem calls service and reloads")
    func discardItemCallsService() async {
        let mock = MockSyncQueueService()
        let item = makeItem()
        mock.stubbedFailedItems = [item]

        let vm = SyncQueueViewModel(syncService: mock)
        await vm.discardItem(item)

        #expect(mock.discardItemCallCount == 1)
    }

    @Test("retryAll sets isRetrying during operation")
    func retryAllSetsIsRetrying() async {
        let mock = MockSyncQueueService()
        mock.stubbedFailedItems = [makeItem()]

        let vm = SyncQueueViewModel(syncService: mock)
        await vm.retryAll()

        #expect(mock.retryAllCallCount == 1)
        #expect(!vm.isRetrying)
    }

    @Test("discardAll calls service and reloads")
    func discardAllCallsService() async {
        let mock = MockSyncQueueService()
        mock.stubbedFailedItems = [makeItem()]

        let vm = SyncQueueViewModel(syncService: mock)
        await vm.discardAll()

        #expect(mock.discardAllCallCount == 1)
    }
}
