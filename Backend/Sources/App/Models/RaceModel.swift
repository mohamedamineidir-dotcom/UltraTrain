import Fluent
import Vapor

final class RaceModel: Model, Content, @unchecked Sendable {
    static let schema = "races"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserModel

    @Field(key: "race_id")
    var raceId: String

    @Field(key: "name")
    var name: String

    @Field(key: "date")
    var date: Date

    @Field(key: "distance_km")
    var distanceKm: Double

    @Field(key: "elevation_gain_m")
    var elevationGainM: Double

    @Field(key: "priority")
    var priority: String

    @Field(key: "race_json")
    var raceJSON: String

    @Field(key: "idempotency_key")
    var idempotencyKey: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}
}
