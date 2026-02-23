import Fluent
import Vapor

final class RunModel: Model, Content, @unchecked Sendable {
    static let schema = "runs"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: UserModel

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

    @OptionalField(key: "average_heart_rate")
    var averageHeartRate: Int?

    @OptionalField(key: "max_heart_rate")
    var maxHeartRate: Int?

    @Field(key: "average_pace_seconds_per_km")
    var averagePaceSecondsPerKm: Double

    @Field(key: "gps_track_json")
    var gpsTrackJSON: String

    @Field(key: "splits_json")
    var splitsJSON: String

    @OptionalField(key: "notes")
    var notes: String?

    @OptionalField(key: "linked_session_id")
    var linkedSessionId: String?

    @Field(key: "idempotency_key")
    var idempotencyKey: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}
}
