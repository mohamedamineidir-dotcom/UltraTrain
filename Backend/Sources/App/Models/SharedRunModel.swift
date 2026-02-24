import Fluent
import Vapor

final class SharedRunModel: Model, Content, @unchecked Sendable {
    static let schema = "shared_runs"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserModel

    @OptionalField(key: "source_run_id")
    var sourceRunId: UUID?

    @Field(key: "date")
    var date: Date

    @Field(key: "distance_km")
    var distanceKm: Double

    @Field(key: "elevation_gain_m")
    var elevationGainM: Double

    @Field(key: "elevation_loss_m")
    var elevationLossM: Double

    @Field(key: "duration")
    var duration: Double

    @Field(key: "average_pace")
    var averagePace: Double

    @Field(key: "gps_track_json")
    var gpsTrackJSON: String

    @Field(key: "splits_json")
    var splitsJSON: String

    @OptionalField(key: "notes")
    var notes: String?

    @Field(key: "shared_at")
    var sharedAt: Date

    @Field(key: "idempotency_key")
    var idempotencyKey: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}
}
