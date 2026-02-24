import Foundation
import os

final class SyncedSocialProfileRepository: SocialProfileRepository, @unchecked Sendable {
    private let local: LocalSocialProfileRepository
    private let remote: RemoteSocialProfileDataSource
    private let authService: any AuthServiceProtocol
    private let syncQueue: (any SyncQueueServiceProtocol)?

    private static let logger = Logger(subsystem: "com.ultratrain", category: "SyncedSocialProfileRepository")

    init(
        local: LocalSocialProfileRepository,
        remote: RemoteSocialProfileDataSource,
        authService: any AuthServiceProtocol,
        syncQueue: (any SyncQueueServiceProtocol)? = nil
    ) {
        self.local = local
        self.remote = remote
        self.authService = authService
        self.syncQueue = syncQueue
    }

    func fetchMyProfile() async throws -> SocialProfile? {
        guard authService.isAuthenticated() else {
            return try await local.fetchMyProfile()
        }

        do {
            let dto = try await remote.fetchMyProfile()
            guard let profile = SocialProfileRemoteMapper.toDomain(dto) else {
                Self.logger.warning("Failed to map remote social profile to domain")
                return try await local.fetchMyProfile()
            }
            try await local.saveMyProfile(profile)
            return profile
        } catch {
            Self.logger.warning("Remote social profile fetch failed, using local: \(error)")
            return try await local.fetchMyProfile()
        }
    }

    func saveMyProfile(_ profile: SocialProfile) async throws {
        try await local.saveMyProfile(profile)

        guard authService.isAuthenticated() else { return }
        if let syncQueue {
            let entityId = UUID(uuidString: profile.id) ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            try? await syncQueue.enqueueOperation(.socialProfileSync, entityId: entityId)
        } else {
            Task {
                do {
                    let dto = SocialProfileRemoteMapper.toDTO(profile)
                    let responseDTO = try await self.remote.updateMyProfile(dto)
                    if let updated = SocialProfileRemoteMapper.toDomain(responseDTO) {
                        try await self.local.saveMyProfile(updated)
                    }
                } catch {
                    Self.logger.warning("Remote social profile sync failed: \(error)")
                }
            }
        }
    }

    func fetchProfile(byId profileId: String) async throws -> SocialProfile? {
        guard authService.isAuthenticated() else {
            return try await local.fetchProfile(byId: profileId)
        }

        do {
            let dto = try await remote.fetchProfile(id: profileId)
            guard let profile = SocialProfileRemoteMapper.toDomain(dto) else {
                Self.logger.warning("Failed to map remote profile \(profileId) to domain")
                return try await local.fetchProfile(byId: profileId)
            }
            return profile
        } catch {
            Self.logger.warning("Remote profile fetch failed for \(profileId), using local: \(error)")
            return try await local.fetchProfile(byId: profileId)
        }
    }

    func deleteMyProfile() async throws {
        try await local.deleteMyProfile()
    }
}
