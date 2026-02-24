import Fluent
import Vapor

final class FriendConnectionModel: Model, Content, @unchecked Sendable {
    static let schema = "friend_connections"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "requestor_id")
    var requestor: UserModel

    @Parent(key: "recipient_id")
    var recipient: UserModel

    @Field(key: "status")
    var status: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @OptionalField(key: "accepted_at")
    var acceptedAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}
}
