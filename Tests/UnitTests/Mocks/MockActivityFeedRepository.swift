import Foundation
@testable import UltraTrain

final class MockActivityFeedRepository: ActivityFeedRepository, @unchecked Sendable {
    var feedItems: [ActivityFeedItem] = []
    var publishedItem: ActivityFeedItem?
    var toggledLikeId: UUID?

    func fetchFeed(limit: Int) async throws -> [ActivityFeedItem] { Array(feedItems.prefix(limit)) }
    func publishActivity(_ item: ActivityFeedItem) async throws { publishedItem = item }
    func toggleLike(itemId: UUID) async throws { toggledLikeId = itemId }
}
