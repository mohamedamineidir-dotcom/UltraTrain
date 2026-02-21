import Foundation

protocol SharedRunRepository: Sendable {
    func fetchSharedRuns() async throws -> [SharedRun]
    func shareRun(_ run: SharedRun, withFriendIds: [String]) async throws
    func revokeShare(_ runId: UUID) async throws
    func fetchRunsSharedByMe() async throws -> [SharedRun]
}
