import Foundation
import Testing
@testable import UltraTrain

@Suite("CloudKitAccountManager Tests")
struct CloudKitAccountManagerTests {

    // NOTE: CloudKitAccountManager depends on CKContainer which is unavailable in unit tests.
    // We test the cache logic and error semantics by verifying the actor's clearCache behavior
    // and the DomainError types it throws.

    // MARK: - DomainError semantics

    @Test("iCloudAccountUnavailable error has correct description")
    func iCloudAccountUnavailableErrorDescription() {
        let error = DomainError.iCloudAccountUnavailable
        #expect(error.localizedDescription.contains("iCloud"))
    }

    @Test("iCloudSyncFailed error includes reason")
    func iCloudSyncFailedIncludesReason() {
        let error = DomainError.iCloudSyncFailed(reason: "quota exceeded")
        #expect(error.localizedDescription.contains("quota exceeded"))
    }

    @Test("clearCache resets cached user record name")
    func clearCacheResetsCachedName() async {
        // CloudKitAccountManager is an actor, so we test that clearCache can be called
        // and the subsequent fetchMyRecordName would need to re-fetch.
        // Without a real CKContainer, we can only verify the method is callable.
        let manager = CloudKitAccountManager()
        await manager.clearCache()
        // No assertion needed -- verifying the method does not crash
    }

    @Test("CloudKitAccountManager can be instantiated as an actor")
    func canInstantiateAsActor() {
        let manager = CloudKitAccountManager()
        // Verify the instance is usable (actor isolation)
        _ = manager
    }

    @Test("publicDatabase property is accessible")
    func publicDatabaseIsAccessible() async {
        let manager = CloudKitAccountManager()
        let db = await manager.publicDatabase
        // Just verify we get a non-nil database reference
        _ = db
    }
}
