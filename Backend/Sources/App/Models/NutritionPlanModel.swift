import Fluent
import Vapor

final class NutritionPlanModel: Model, Content, @unchecked Sendable {
    static let schema = "nutrition_plans"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserModel

    @Field(key: "nutrition_plan_id")
    var nutritionPlanId: String

    @Field(key: "race_id")
    var raceId: String

    @Field(key: "calories_per_hour")
    var caloriesPerHour: Int

    @Field(key: "nutrition_json")
    var nutritionJSON: String

    @Field(key: "idempotency_key")
    var idempotencyKey: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}
}
