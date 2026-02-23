import Fluent
import Vapor

final class TrainingPlanModel: Model, Content, @unchecked Sendable {
    static let schema = "training_plans"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserModel

    @Field(key: "target_race_name")
    var targetRaceName: String

    @Field(key: "target_race_date")
    var targetRaceDate: Date

    @Field(key: "total_weeks")
    var totalWeeks: Int

    @Field(key: "plan_json")
    var planJSON: String

    @Field(key: "idempotency_key")
    var idempotencyKey: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userId: UUID,
        targetRaceName: String,
        targetRaceDate: Date,
        totalWeeks: Int,
        planJSON: String,
        idempotencyKey: String
    ) {
        self.id = id
        self.$user.id = userId
        self.targetRaceName = targetRaceName
        self.targetRaceDate = targetRaceDate
        self.totalWeeks = totalWeeks
        self.planJSON = planJSON
        self.idempotencyKey = idempotencyKey
    }
}
