import Foundation
import os

final class SyncedGroupChallengeRepository: GroupChallengeRepository, @unchecked Sendable {
    private let local: LocalGroupChallengeRepository
    private let remote: RemoteGroupChallengeDataSource
    private let authService: any AuthServiceProtocol

    private static let logger = Logger(subsystem: "com.ultratrain", category: "SyncedGroupChallengeRepository")

    init(
        local: LocalGroupChallengeRepository,
        remote: RemoteGroupChallengeDataSource,
        authService: any AuthServiceProtocol
    ) {
        self.local = local
        self.remote = remote
        self.authService = authService
    }

    func fetchActiveChallenges() async throws -> [GroupChallenge] {
        guard authService.isAuthenticated() else {
            return try await local.fetchActiveChallenges()
        }

        do {
            let dtos = try await remote.fetchChallenges(status: "active")
            let challenges = dtos.compactMap { GroupChallengeRemoteMapper.toDomain($0) }
            for challenge in challenges {
                _ = try? await local.createChallenge(challenge)
            }
            return challenges
        } catch {
            Self.logger.warning("Remote active challenges fetch failed, using local: \(error)")
            return try await local.fetchActiveChallenges()
        }
    }

    func fetchCompletedChallenges() async throws -> [GroupChallenge] {
        guard authService.isAuthenticated() else {
            return try await local.fetchCompletedChallenges()
        }

        do {
            let dtos = try await remote.fetchChallenges(status: "completed")
            let challenges = dtos.compactMap { GroupChallengeRemoteMapper.toDomain($0) }
            for challenge in challenges {
                _ = try? await local.createChallenge(challenge)
            }
            return challenges
        } catch {
            Self.logger.warning("Remote completed challenges fetch failed, using local: \(error)")
            return try await local.fetchCompletedChallenges()
        }
    }

    func createChallenge(_ challenge: GroupChallenge) async throws -> GroupChallenge {
        guard authService.isAuthenticated() else {
            return try await local.createChallenge(challenge)
        }

        let dto = GroupChallengeRemoteMapper.toCreateDTO(challenge)
        let responseDTO = try await remote.createChallenge(dto)

        guard let created = GroupChallengeRemoteMapper.toDomain(responseDTO) else {
            Self.logger.warning("Failed to map remote challenge response to domain")
            return try await local.createChallenge(challenge)
        }

        _ = try? await local.createChallenge(created)
        return created
    }

    func joinChallenge(_ challengeId: UUID) async throws {
        guard authService.isAuthenticated() else {
            try await local.joinChallenge(challengeId)
            return
        }

        let responseDTO = try await remote.joinChallenge(id: challengeId.uuidString)
        if let updated = GroupChallengeRemoteMapper.toDomain(responseDTO) {
            _ = try? await local.createChallenge(updated)
        }
        try await local.joinChallenge(challengeId)
    }

    func leaveChallenge(_ challengeId: UUID) async throws {
        guard authService.isAuthenticated() else {
            try await local.leaveChallenge(challengeId)
            return
        }

        try await remote.leaveChallenge(id: challengeId.uuidString)
        try await local.leaveChallenge(challengeId)
    }

    func updateProgress(challengeId: UUID, value: Double) async throws {
        guard authService.isAuthenticated() else {
            try await local.updateProgress(challengeId: challengeId, value: value)
            return
        }

        let dto = UpdateProgressRequestDTO(value: value)
        _ = try await remote.updateProgress(challengeId: challengeId.uuidString, dto: dto)
        try await local.updateProgress(challengeId: challengeId, value: value)
    }
}
