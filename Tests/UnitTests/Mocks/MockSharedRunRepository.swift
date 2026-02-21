import Foundation
@testable import UltraTrain

final class MockSharedRunRepository: SharedRunRepository, @unchecked Sendable {
    var sharedRuns: [SharedRun] = []
    var sharedByMe: [SharedRun] = []
    var lastShared: SharedRun?
    var lastSharedFriendIds: [String] = []
    var revokedId: UUID?

    func fetchSharedRuns() async throws -> [SharedRun] { sharedRuns }

    func shareRun(_ run: SharedRun, withFriendIds friendIds: [String]) async throws {
        lastShared = run
        lastSharedFriendIds = friendIds
    }

    func revokeShare(_ runId: UUID) async throws { revokedId = runId }
    func fetchRunsSharedByMe() async throws -> [SharedRun] { sharedByMe }
}
