import Fluent
import Vapor

final class GroupChallengeModel: Model, Content, @unchecked Sendable {
    static let schema = "group_challenges"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "creator_id")
    var creator: UserModel

    @Field(key: "name")
    var name: String

    @Field(key: "description_text")
    var descriptionText: String

    @Field(key: "type")
    var type: String

    @Field(key: "target_value")
    var targetValue: Double

    @Field(key: "start_date")
    var startDate: Date

    @Field(key: "end_date")
    var endDate: Date

    @Field(key: "status")
    var status: String

    @Field(key: "idempotency_key")
    var idempotencyKey: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}
}
