import Fluent
import Vapor

final class FitnessSnapshotModel: Model, Content, @unchecked Sendable {
    static let schema = "fitness_snapshots"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserModel

    @Field(key: "snapshot_id")
    var snapshotId: String

    @Field(key: "date")
    var date: Date

    @Field(key: "fitness")
    var fitness: Double

    @Field(key: "fatigue")
    var fatigue: Double

    @Field(key: "form")
    var form: Double

    @Field(key: "fitness_json")
    var fitnessJSON: String

    @Field(key: "idempotency_key")
    var idempotencyKey: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}
}
