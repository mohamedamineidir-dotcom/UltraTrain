import Fluent
import Vapor

final class FeedLikeModel: Model, Content, @unchecked Sendable {
    static let schema = "feed_likes"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserModel

    @Parent(key: "feed_item_id")
    var feedItem: ActivityFeedItemModel

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}
}
