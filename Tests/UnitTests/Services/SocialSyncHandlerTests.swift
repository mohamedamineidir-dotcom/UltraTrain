import Testing
import Foundation
@testable import UltraTrain

@Suite("SocialSyncHandler Tests")
struct SocialSyncHandlerTests {

    private func makeItem(
        type: SyncOperationType,
        entityId: UUID = UUID()
    ) -> SyncQueueItem {
        SyncQueueItem(
            id: UUID(),
            runId: UUID(),
            operationType: type,
            entityId: entityId,
            status: .uploading,
            retryCount: 0,
            lastAttempt: Date(),
            errorMessage: nil,
            createdAt: Date()
        )
    }

    @Test func handlerInitializesWithNilDeps() {
        let handler = SocialSyncHandler()
        // No crash = success
        #expect(handler != nil)
    }

    @Test func processUnexpectedTypeDoesNotCrash() async throws {
        let handler = SocialSyncHandler()
        let item = makeItem(type: .runUpload)

        // Should log error but not throw
        try await handler.process(item)
    }

    @Test func socialProfileSyncWithNilDepsReturns() async throws {
        let handler = SocialSyncHandler()
        let item = makeItem(type: .socialProfileSync)

        // No remote/local → early return, no throw
        try await handler.process(item)
    }

    @Test func activityPublishWithNilDepsReturns() async throws {
        let handler = SocialSyncHandler()
        let item = makeItem(type: .activityPublish)

        try await handler.process(item)
    }

    @Test func shareRevokeWithNilDepsReturns() async throws {
        let handler = SocialSyncHandler()
        let item = makeItem(type: .shareRevoke)

        try await handler.process(item)
    }

    @Test func allThreeSocialTypesAreHandled() async throws {
        let handler = SocialSyncHandler()

        let types: [SyncOperationType] = [.socialProfileSync, .activityPublish, .shareRevoke]
        for type in types {
            let item = makeItem(type: type)
            try await handler.process(item)
        }
    }
}
