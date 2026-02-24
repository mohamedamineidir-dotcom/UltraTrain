import Foundation
import os

final class SyncedFriendRepository: FriendRepository, @unchecked Sendable {
    private let local: LocalFriendRepository
    private let remote: RemoteFriendDataSource
    private let authService: any AuthServiceProtocol

    private static let logger = Logger(subsystem: "com.ultratrain", category: "SyncedFriendRepository")

    init(
        local: LocalFriendRepository,
        remote: RemoteFriendDataSource,
        authService: any AuthServiceProtocol
    ) {
        self.local = local
        self.remote = remote
        self.authService = authService
    }

    func fetchFriends() async throws -> [FriendConnection] {
        guard authService.isAuthenticated() else {
            return try await local.fetchFriends()
        }

        do {
            let dtos = try await remote.fetchFriends()
            let friends = dtos.compactMap { FriendConnectionRemoteMapper.toDomain($0) }
            return friends
        } catch {
            Self.logger.warning("Remote friends fetch failed, using local: \(error)")
            return try await local.fetchFriends()
        }
    }

    func fetchPendingRequests() async throws -> [FriendConnection] {
        guard authService.isAuthenticated() else {
            return try await local.fetchPendingRequests()
        }

        do {
            let dtos = try await remote.fetchPending()
            let pending = dtos.compactMap { FriendConnectionRemoteMapper.toDomain($0) }
            return pending
        } catch {
            Self.logger.warning("Remote pending requests fetch failed, using local: \(error)")
            return try await local.fetchPendingRequests()
        }
    }

    func sendFriendRequest(toProfileId: String, displayName: String) async throws -> FriendConnection {
        guard authService.isAuthenticated() else {
            return try await local.sendFriendRequest(toProfileId: toProfileId, displayName: displayName)
        }

        let requestDTO = FriendConnectionRemoteMapper.toRequestDTO(profileId: toProfileId)
        let responseDTO = try await remote.sendRequest(requestDTO)

        guard let connection = FriendConnectionRemoteMapper.toDomain(responseDTO) else {
            Self.logger.warning("Failed to map remote friend request response to domain")
            return try await local.sendFriendRequest(toProfileId: toProfileId, displayName: displayName)
        }

        return connection
    }

    func acceptFriendRequest(_ connectionId: UUID) async throws {
        guard authService.isAuthenticated() else {
            try await local.acceptFriendRequest(connectionId)
            return
        }

        _ = try await remote.acceptRequest(connectionId: connectionId.uuidString)
        try await local.acceptFriendRequest(connectionId)
    }

    func declineFriendRequest(_ connectionId: UUID) async throws {
        guard authService.isAuthenticated() else {
            try await local.declineFriendRequest(connectionId)
            return
        }

        _ = try await remote.declineRequest(connectionId: connectionId.uuidString)
        try await local.declineFriendRequest(connectionId)
    }

    func removeFriend(_ connectionId: UUID) async throws {
        guard authService.isAuthenticated() else {
            try await local.removeFriend(connectionId)
            return
        }

        try await remote.removeFriend(connectionId: connectionId.uuidString)
        try await local.removeFriend(connectionId)
    }
}
