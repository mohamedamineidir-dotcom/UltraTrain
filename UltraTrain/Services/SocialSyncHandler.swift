import Foundation
import os

final class SocialSyncHandler: @unchecked Sendable {
    private let remoteSocialProfile: RemoteSocialProfileDataSource?
    private let localSocialProfile: LocalSocialProfileRepository?
    private let remoteActivityFeed: RemoteActivityFeedDataSource?
    private let localActivityFeed: LocalActivityFeedRepository?
    private let remoteSharedRun: RemoteSharedRunDataSource?

    init(
        remoteSocialProfile: RemoteSocialProfileDataSource? = nil,
        localSocialProfile: LocalSocialProfileRepository? = nil,
        remoteActivityFeed: RemoteActivityFeedDataSource? = nil,
        localActivityFeed: LocalActivityFeedRepository? = nil,
        remoteSharedRun: RemoteSharedRunDataSource? = nil
    ) {
        self.remoteSocialProfile = remoteSocialProfile
        self.localSocialProfile = localSocialProfile
        self.remoteActivityFeed = remoteActivityFeed
        self.localActivityFeed = localActivityFeed
        self.remoteSharedRun = remoteSharedRun
    }

    func process(_ item: SyncQueueItem) async throws {
        switch item.operationType {
        case .socialProfileSync:
            try await processSocialProfileSync(item)
        case .activityPublish:
            try await processActivityPublish(item)
        case .shareRevoke:
            try await processShareRevoke(item)
        default:
            Logger.network.error("SocialSyncHandler: unexpected operation type \(item.operationType.rawValue)")
        }
    }

    // MARK: - Private

    private func processSocialProfileSync(_ item: SyncQueueItem) async throws {
        guard let remote = remoteSocialProfile,
              let local = localSocialProfile else { return }
        guard let profile = try await local.fetchMyProfile() else {
            Logger.social.info("SocialSyncHandler: no local profile to sync")
            return
        }
        let dto = SocialProfileRemoteMapper.toDTO(profile)
        let responseDTO = try await remote.updateMyProfile(dto)
        if let updated = SocialProfileRemoteMapper.toDomain(responseDTO) {
            try await local.saveMyProfile(updated)
        }
    }

    private func processActivityPublish(_ item: SyncQueueItem) async throws {
        guard let remote = remoteActivityFeed,
              let local = localActivityFeed else { return }
        let items = try await local.fetchFeed(limit: 100)
        guard let feedItem = items.first(where: { $0.id == item.entityId }) else {
            Logger.social.info("SocialSyncHandler: activity item \(item.entityId) not found locally")
            return
        }
        let dto = ActivityFeedRemoteMapper.toDTO(feedItem)
        _ = try await remote.publishActivity(dto)
    }

    private func processShareRevoke(_ item: SyncQueueItem) async throws {
        guard let remote = remoteSharedRun else { return }
        try await remote.revokeShare(id: item.entityId.uuidString)
    }
}
