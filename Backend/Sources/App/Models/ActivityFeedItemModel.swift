import Fluent
import Vapor

final class ActivityFeedItemModel: Model, Content, @unchecked Sendable {
    static let schema = "activity_feed_items"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserModel

    @Field(key: "activity_type")
    var activityType: String

    @Field(key: "title")
    var title: String

    @OptionalField(key: "subtitle")
    var subtitle: String?

    @OptionalField(key: "stats_json")
    var statsJSON: String?

    @Field(key: "timestamp")
    var timestamp: Date

    @Field(key: "idempotency_key")
    var idempotencyKey: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}
}
