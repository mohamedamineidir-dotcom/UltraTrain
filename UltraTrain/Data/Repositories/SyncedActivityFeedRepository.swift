import Foundation
import os

// @unchecked Sendable: immutable after init; delegates to Sendable deps
final class SyncedActivityFeedRepository: ActivityFeedRepository, @unchecked Sendable {
    private let local: LocalActivityFeedRepository
    private let remote: RemoteActivityFeedDataSource
    private let authService: any AuthServiceProtocol
    private let syncQueue: (any SyncQueueServiceProtocol)?

    private static let logger = Logger(subsystem: "com.ultratrain", category: "SyncedActivityFeedRepository")

    init(
        local: LocalActivityFeedRepository,
        remote: RemoteActivityFeedDataSource,
        authService: any AuthServiceProtocol,
        syncQueue: (any SyncQueueServiceProtocol)? = nil
    ) {
        self.local = local
        self.remote = remote
        self.authService = authService
        self.syncQueue = syncQueue
    }

    func fetchFeed(limit: Int) async throws -> [ActivityFeedItem] {
        guard authService.isAuthenticated() else {
            return try await local.fetchFeed(limit: limit)
        }

        do {
            let dtos = try await remote.fetchFeed(limit: limit)
            let items = dtos.compactMap { ActivityFeedRemoteMapper.toDomain($0) }
            for item in items {
                do {
                    try await local.publishActivity(item)
                } catch {
                    Self.logger.warning("Failed to cache activity feed item \(item.id) locally: \(error)")
                }
            }
            return items
        } catch {
            Self.logger.warning("Remote feed fetch failed, using local: \(error)")
            return try await local.fetchFeed(limit: limit)
        }
    }

    func publishActivity(_ item: ActivityFeedItem) async throws {
        try await local.publishActivity(item)

        guard authService.isAuthenticated() else { return }
        if let syncQueue {
            do {
                try await syncQueue.enqueueOperation(.activityPublish, entityId: item.id)
            } catch {
                Self.logger.warning("Failed to enqueue activity publish for \(item.id): \(error)")
            }
        } else {
            Task {
                do {
                    let dto = ActivityFeedRemoteMapper.toDTO(item)
                    _ = try await self.remote.publishActivity(dto)
                } catch {
                    Self.logger.warning("Remote activity publish failed: \(error)")
                }
            }
        }
    }

    func toggleLike(itemId: UUID) async throws {
        guard authService.isAuthenticated() else {
            try await local.toggleLike(itemId: itemId)
            return
        }

        do {
            _ = try await remote.toggleLike(itemId: itemId.uuidString)
            try await local.toggleLike(itemId: itemId)
        } catch {
            Self.logger.warning("Remote toggle like failed: \(error)")
            throw error
        }
    }
}
