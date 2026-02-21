import Foundation

protocol ActivityFeedRepository: Sendable {
    func fetchFeed(limit: Int) async throws -> [ActivityFeedItem]
    func publishActivity(_ item: ActivityFeedItem) async throws
    func toggleLike(itemId: UUID) async throws
}
