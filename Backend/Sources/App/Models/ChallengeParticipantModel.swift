import Fluent
import Vapor

final class ChallengeParticipantModel: Model, Content, @unchecked Sendable {
    static let schema = "challenge_participants"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "challenge_id")
    var challenge: GroupChallengeModel

    @Parent(key: "user_id")
    var user: UserModel

    @Field(key: "display_name")
    var displayName: String

    @Field(key: "current_value")
    var currentValue: Double

    @Field(key: "joined_date")
    var joinedDate: Date

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}
}
