import Foundation
import os

final class SyncedSharedRunRepository: SharedRunRepository, @unchecked Sendable {
    private let local: LocalSharedRunRepository
    private let remote: RemoteSharedRunDataSource
    private let authService: any AuthServiceProtocol

    private static let logger = Logger(subsystem: "com.ultratrain", category: "SyncedSharedRunRepository")

    init(
        local: LocalSharedRunRepository,
        remote: RemoteSharedRunDataSource,
        authService: any AuthServiceProtocol
    ) {
        self.local = local
        self.remote = remote
        self.authService = authService
    }

    func fetchSharedRuns() async throws -> [SharedRun] {
        guard authService.isAuthenticated() else {
            return try await local.fetchSharedRuns()
        }

        do {
            let dtos = try await remote.fetchSharedRuns()
            let runs = dtos.compactMap { SharedRunRemoteMapper.toDomain($0) }
            for run in runs {
                try? await local.shareRun(run, withFriendIds: [])
            }
            return runs
        } catch {
            Self.logger.warning("Remote shared runs fetch failed, using local: \(error)")
            return try await local.fetchSharedRuns()
        }
    }

    func shareRun(_ run: SharedRun, withFriendIds: [String]) async throws {
        guard authService.isAuthenticated() else {
            try await local.shareRun(run, withFriendIds: withFriendIds)
            return
        }

        let dto = SharedRunRemoteMapper.toDTO(run, recipientIds: withFriendIds)
        _ = try await remote.shareRun(dto)
        try await local.shareRun(run, withFriendIds: withFriendIds)
    }

    func revokeShare(_ runId: UUID) async throws {
        try await local.revokeShare(runId)

        guard authService.isAuthenticated() else { return }
        Task {
            do {
                try await self.remote.revokeShare(id: runId.uuidString)
            } catch {
                Self.logger.warning("Remote share revoke failed: \(error)")
            }
        }
    }

    func fetchRunsSharedByMe() async throws -> [SharedRun] {
        guard authService.isAuthenticated() else {
            return try await local.fetchRunsSharedByMe()
        }

        do {
            let dtos = try await remote.fetchMySharedRuns()
            let runs = dtos.compactMap { SharedRunRemoteMapper.toDomain($0) }
            return runs
        } catch {
            Self.logger.warning("Remote my shared runs fetch failed, using local: \(error)")
            return try await local.fetchRunsSharedByMe()
        }
    }
}
