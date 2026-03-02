import Fluent
import Vapor

final class FinishEstimateModel: Model, Content, @unchecked Sendable {
    static let schema = "finish_estimates"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserModel

    @Field(key: "estimate_id")
    var estimateId: String

    @Field(key: "race_id")
    var raceId: String

    @Field(key: "expected_time")
    var expectedTime: Double

    @Field(key: "confidence_percent")
    var confidencePercent: Double

    @Field(key: "estimate_json")
    var estimateJSON: String

    @Field(key: "idempotency_key")
    var idempotencyKey: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}
}
